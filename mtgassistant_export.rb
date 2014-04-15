#!/bin/env ruby
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

## Example card entry
# mainxml['list'].first['mcp'].first
# {"card"=>[{"id"=>["152727"], "name"=>["Disperse"], "edition"=>["Morningtide"]}], "id"=>["152727"], "name"=>["Disperse"], "cost"=>["{1}{U}"], "type"=>["Instant"], "oracleText"=>["Return target nonland permanent to its owner's hand."], "edition"=>["Morningtide"], "rarity"=>["Common"], "dbprice"=>["0.15"], "rating"=>["3.521"], "artist"=>["Steve Ellis"], "num"=>["31"], "text"=>["Return target nonland permanent to its owner's hand."], "properties"=>["{LEGALITY=Standard|Commander-}"], "count"=>["2"], "location"=>["Collections/main"], "ownership"=>["true"]}

require 'rubygems'
require 'bundler/setup'

def parsexml(xmlfile)
  require 'xmlsimple'
  XmlSimple.xml_in(xmlfile)
end

def hasparm? (parm,cardobj)
  if cardobj['special']
    if cardobj['special'].include? parm
      return true
    else
      return false
    end
  else
    return false
  end
end

def deckboxaccepts? (cardobj)
  if cardobj['edition'].first == 'Magic Player Rewards'
    return false
  # http://deckbox.org/forum/viewtopic.php?pid=72629
  elsif cardobj['name'].first == 'Lim-Dûl\'s Vault'
    return false
  elsif cardobj['name'].first == 'Chaotic Æther'
    return false
  elsif cardobj['special']
    if cardobj['special'].first.include?('loantome')
      return false
    end
  else
    return true
  end
end

def gettradecount (cardobj)
  # TODO - Add support for manual tradecounts
  specialsets = ['Archenemy','Magic: The Gathering-Commander','Commander 2013 Edition','Planechase','Planechase 2012 Edition']
  unless specialsets.include?(cardobj['edition'].first) or cardobj['edition'].first.include?('Duel Deck')
    if cardobj['count'].first.to_i > 4
      return (cardobj['count'].first.to_i - 4).to_s
    else
      return '0'
    end
  else
    return '0'
  end
end

def mkdecklist (xml,outputdir)
  decklistnames = []
  decklistcount = []
  xml['list'].first['mcp'].each do |card|
    unless card['special'] and card['special'].first.include?('loantome')
      if decklistnames.include?(card['name'].first)
        decklistcount[decklistnames.index(card['name'].first)] += card['count'].first.to_i
      else
        decklistnames << card['name'].first
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

def mkdeckboxinv(cardxml,outputdir)
  require 'csv'
  CSV.open("#{outputdir}/main.csv", "wb") do |csv|
    csv << ['Count','Tradelist Count','Name','Foil','Textless','Promo','Signed','Edition','Condition','Language']
    cardxml['list'].first['mcp'].each do |card|
      if deckboxaccepts?(card)
        linetoadd = [card['count'].first]
        linetoadd << gettradecount(card)
        cardname = card['name'].first.gsub(/ \(.*/, '').gsub("Æ", 'Ae')
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
        linetoadd << card['edition'].first.gsub(/2012 Edition/, '2012').gsub(/2013 Edition/, '2013')
        if hasparm?('played',card)
          linetoadd << 'Played'
        else
          linetoadd << 'Near Mint'
        end
        # FIXME - Language check?
        linetoadd << 'English'
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
  
  mkdeckboxinv(mainxml,options[:outputdir])
end
