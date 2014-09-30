#!/usr/bin/env ruby
# encoding: utf-8

# Copyright 2014 Troy Ready
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Example card entries
#mainxml['list'].first['mcp'].first
# {"card"=>[{"id"=>["152727"], "name"=>["Disperse"], "edition"=>["Morningtide"]}], "count"=>["2"], "location"=>["Collections/main"], "ownership"=>["true"]}
#
#mainxml['list'].first['mcp'].first
#{"card"=>[{"id"=>["280320"], "name"=>["Intrepid Hero"], "edition"=>["Magic 2013"]}], "count"=>["1"], "location"=>["Collections/main"], "ownership"=>["true"], "special"=>["foil"]}

require 'rubygems'
require 'bundler/setup'
require "json"
require "net/http"
require "uri"
require "yaml/store"

def parsexml(xmlfile)
  require 'xmlsimple'
  XmlSimple.xml_in(xmlfile)
end

def hasparm? (parm,cardobj)
  if cardobj['special']
    # Check to see if there are multiple special tags, which will be shown in an array
    if cardobj['special'].kind_of?(Array)
      if cardobj['special'].first.include? parm
        return true
      else
        return false
      end
    else
      if cardobj['special'].include? parm
        return true
      else
        return false
      end
    end
  else
    return false
  end
end

def sendtodeckbox? (cardobj)
  if cardobj['special']
    if cardobj['special'].first.include?('loantome')
      return false
    else
      return true
    end
  else
    return true
  end
end

def gettradecount (cardobj,tradelistfile)
  require "yaml/store"
  
  tradecount = '0'
  # First, generate a simple tradecount
  if cardobj['count'].first.to_i > 4
    tradecount = (cardobj['count'].first.to_i - 4).to_s
  end
  # Now, if a manual tradelist specified, check it for an override
  if tradelistfile != ''
    store = YAML::Store.new(tradelistfile)
    if store.transaction { store[cardobj['card'].first['name'].first] }
      if cardobj['card'].first['edition'].first == (store.transaction { store[cardobj['card'].first['name'].first]['edition'] })
        if hasparm?('foil',cardobj) == (store.transaction { store[cardobj['card'].first['name'].first]['foil'] })
          tradecount = store.transaction { store[cardobj['card'].first['name'].first]['trade_count'] }
        end
      end
    end
  end
  return tradecount
end

def mkdecklist (xml,outputdir)
  decklistnames = []
  decklistcount = []
  xml['list'].first['mcp'].each do |card|
    unless card['special'] and card['special'].first.include?('loantome')
      if decklistnames.include?(card['card'].first['name'].first)
        decklistcount[decklistnames.index(card['card'].first['name'].first)] += card['count'].first.to_i
      else
        decklistnames << card['card'].first['name'].first
        decklistcount << card['count'].first.to_i
      end
    end
  end
  sorteddecklist = decklistnames.sort
  decklist = []
  sorteddecklist.each do |card|
    decklist << {'name'=>card,'count'=>decklistcount[decklistnames.index(card)].to_s}
  end
  File.open("#{outputdir}/main.dec", 'w') do |f|
    f.puts "// Generated on #{Time.new.to_s}\n"
    decklist.each do |card|
      f.puts "#{card['count']} #{card['name']}\n"
    end
  end  
end

def getmultiverseid (cardid,cardname)
  # This will translate your custom database entries into standard multiverse IDs
  
  uri = URI.parse("http://api.mtgapi.com/v1/card/name/#{cardname.gsub(/ /, '%20')}")
  
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  
  response = http.request(request)
  
  if response.code == "200"
    result = JSON.parse(response.body)
    # Sometimes the api will return a hash like "{"name":"Ponder","id":null}"
    # Check here for null responses and skip to the next id
    new_card_id = ''
    index_under_eval = 0
    while new_card_id == ''
      if result[index_under_eval]['id'].is_a?(String)
        new_card_id = result[index_under_eval]['id']
      else
        index_under_eval += 1
      end
    end
    puts "Translating card #{cardname} (card id #{cardid}) to card id #{new_card_id} for Decked Builder"
    return new_card_id
  else
    puts "Unable to translate card #{cardname} (card id #{cardid}) - mtgapi returned http code #{response.code}"
    return cardid
  end
end

def getcollnumber (cardid,cardname)
  # This will find the card collector number for a given card
  
  uri = URI.parse("http://api.mtgapi.com/v2/cards?multiverseid=#{cardid}")
  
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  
  response = http.request(request)
  
  if response.code == "200"
    result = JSON.parse(response.body)
    return result['cards'][0]['number']
  else
    puts "Unable to find collector's number for #{cardname} - mtgapi returned http code #{response.code}"
    return ''
  end
end

def mkcoll2 (xml,outputfile)
  # Using a temporary array of card ideas as a way of quickly checking which
  # cards have already been encountered
  cardids = []
  cards = []
  xml['list'].first['mcp'].each do |card|
    unless card['special'] and card['special'].first.include?('loantome')
      # Custom sets in Magic Assistant start with a -
      cardid = ''
      unless card['card'].first['id'].first.start_with?('-')
        cardid = card['card'].first['id'].first
      else
        # FIXME - adding a manual workaround for broken split card
        # Once new api is stable should switch to it and refactor
        if card['card'].first['name'].first == 'Fire // Ice (Fire)'
          cardid = '27166'
        else
          cardid = getmultiverseid(card['card'].first['id'].first,card['card'].first['name'].first)
        end
      end
      # Now we've translated IDs where possible; proceed with adding the cards
      # to the staging array for writing, unless they still have an invalid ID
      unless cardid.start_with?('-')
        unless cardids.include?(cardid)
          # This means that we haven't encountered this multiverse id before
          # Now that we're adding it to the cards array, note here that
          # we've encountered it
          cardids << cardid
          newcard = {}
          newcard['id'] = cardid
          unless card['special'] and card['special'].first.include?('foil')
            newcard['regulars'] = card['count'].first.to_i
            newcard['foils'] = 0
          else
            newcard['regulars'] = 0
            newcard['foils'] = card['count'].first.to_i
          end
          cards << newcard
        else
          # We've already encountered this multiverseid at least once, so
          # increment ownership numbers instead
          unless card['special'] and card['special'].first.include?('foil')
            cards[cardids.index(cardid)]['regulars'] += card['count'].first.to_i
          else
            cards[cardids.index(cardid)]['foils'] += card['count'].first.to_i
          end
        end
      else
        puts "Skipping card \"#{card['card'].first['name'].first}\" from \"#{card['card'].first['edition'].first}\" due to its invalid Multiverse ID \"#{cardid}\"."
      end
    end
  end
  File.open(outputfile, 'w') do |f|
    # Start with the boilerplate
    f.puts "doc:\n"
    f.puts "- version: 1\n"
    f.puts "- items:\n"
    cards.each do |card|
      f.puts "  - - id: #{card['id']}\n"
      if card['regulars'] > 0
        f.puts "    - r: #{card['regulars'].to_s}\n"
      end
      if card['foils'] > 0
        f.puts "    - f: #{card['foils'].to_s}\n"
      end
    end
  end
end  

def mkdeckboxinv(cardxml,outputdir,tradelistfile)
  require 'csv'
  CSV.open("#{outputdir}/main.csv", "wb") do |csv|
    csv << ['Count','Tradelist Count','Name','Foil','Textless','Promo','Signed','Edition','Condition','Language','Card Number']
    cardxml['list'].first['mcp'].each do |card|
      if sendtodeckbox?(card)
        linetoadd = [card['count'].first]
        linetoadd << gettradecount(card,tradelistfile)
        cardname = card['card'].first['name'].first.gsub(/ \(.*/, '').gsub("Æ", 'Ae').gsub("Lim-Dûl's Vault", "Lim-Dul's Vault")
        linetoadd << cardname
        if hasparm?('foil',card)
          linetoadd << 'foil'
        else
          linetoadd << ''
        end
        if hasparm?('textless',card)
          linetoadd << 'textless'
        else
          linetoadd << ''
        end
        if hasparm?('promo',card)
          linetoadd << 'promo'
        else
          linetoadd << ''
        end
        if hasparm?('signed',card)
          linetoadd << 'signed'
        else
          linetoadd << ''
        end
        linetoadd << card['card'].first['edition'].first.gsub(/2012 Edition/, '2012').gsub(/2013 Edition/, '2013').gsub(/Magic: The Gathering—Conspiracy/, 'Conspiracy').gsub(/Annihilation \(2014\)/, 'Annihilation')
        if hasparm?('played',card)
          linetoadd << 'Played'
        else
          linetoadd << 'Near Mint'
        end
        # FIXME - Language check?
        linetoadd << 'English'
        # Check to see if the collector number should be added
        # First check is to see if it's a basic land
        if (['Plains','Island','Swamp','Mountain','Forest'].include? (card['card'].first['name'].first)) and not (card['card'].first['id'].first.start_with?('-'))
          collnumber = getcollnumber(card['card'].first['id'].first,card['card'].first['name'].first)
          unless collnumber == ''
            linetoadd << collnumber
          end
        # Next, if the card is a token (or otherwise from the 'Extras' deckbox set), map its collectors number to the last
        # two digits of its multiverse id
        elsif card['card'].first['edition'].first.start_with?('Extras:')
          linetoadd << card['card'].first['id'].first.split(//).last(2).join("").to_s
        end
        csv << linetoadd
      end
    end
  end
end

if __FILE__ == $0
  
  require 'optparse'
  require 'pathname'
  
  # This hash will hold all of the options
  # parsed from the command-line by
  # OptionParser.
  options = {}
  
  optparse = OptionParser.new do|opts|
    # TODO: Put command-line options here
    
    options[:inputfile] = ""
    opts.on( '-i', '--input FILE', "Input XML file" ) do |f|
      options[:inputfile] = f
    end
    
    options[:outputdir] = ""
    opts.on( '-o', '--output DIR', "Output directory" ) do |f|
      options[:outputdir] = f
    end
    
    options[:deckedoutfile] = false
    opts.on( '-d', '--deckedbuilder FILE', "Decked Builder output file" ) do |f|
      options[:deckedoutfile] = f
    end
    
    # Optional YAML file to override trade counts
    # e.g:
    # ---
    # Spellskite:
    #   edition: New Phyrexia
    #   foil: false
    #   trade_count: '0'
    # Giant Growth:
    # (etc)
    options[:tradelistfile] = ''
    opts.on( '-t', '--tradelist FILE', "Manual tradelist file" ) do |f|
      options[:tradelistfile] = f
    end
    
    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end
  
  optparse.parse!
  
  if options[:inputfile] == nil
    print 'Enter input XML file: '
    options[:inputfile] = gets.chomp
  end
  
  if options[:outputdir] == nil
    print 'Enter output directory for files: '
    options[:outputdir] = Pathname(gets.chomp).cleanpath.to_s
  end
  
  unless Pathname(options[:outputdir]).directory?
    puts "\"#{options[:outputdir]}\" is not a valid directory"
  end
  
  # Option set; start the processing
  mainxml = parsexml(options[:inputfile])
  
  mkdecklist(mainxml,options[:outputdir])
  
  if options[:deckedoutfile]
    mkcoll2(mainxml,options[:deckedoutfile])
  end
  
  mkdeckboxinv(mainxml,options[:outputdir],options[:tradelistfile])
end
