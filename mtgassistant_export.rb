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

## Example card entries
#mainxml['list'].first['mcp'].first
# {"card"=>[{"id"=>["152727"], "name"=>["Disperse"], "edition"=>["Morningtide"]}], "count"=>["2"], "location"=>["Collections/main"], "ownership"=>["true"]}
#
#mainxml['list'].first['mcp'].first
#{"card"=>[{"id"=>["280320"], "name"=>["Intrepid Hero"], "edition"=>["Magic 2013"]}], "count"=>["1"], "location"=>["Collections/main"], "ownership"=>["true"], "special"=>["foil"]}

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
  # http://deckbox.org/forum/viewtopic.php?pid=72629
  if cardobj['card'].first['name'].first == 'Lim-Dûl\'s Vault'
    return false
  elsif cardobj['card'].first['name'].first == 'Chaotic Æther'
    return false
  elsif cardobj['special']
    if cardobj['special'].first.include?('loantome')
      return false
    else
      return true
    end
  else
    return true
  end
end

def gettradecount (cardobj)
  # TODO - Add support for manual tradecounts
  specialsets = ['Archenemy','Magic: The Gathering-Commander','Commander 2013 Edition','Planechase','Planechase 2012 Edition']
  unless specialsets.include?(cardobj['card'].first['edition'].first) or cardobj['card'].first['edition'].first.include?('Duel Deck')
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

def getmultiverseid (cardid)
  # If you want to include non-Gatherer cards in your Decked Builder collection,
  # you'll need to manually map the custom Magic Assistant id to a valid
  # multiverse id.
  #
  # This translation process is, I believe, specific to each Magic Assistant
  # installation. Modify here to match your own IDs
  #
  cardmapping = {}
  # DotP Scavenging Ooze promo -> Magic 2014 version
  cardmapping['-2147450810'] = '370629'
  # "Ponder" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354851".
  # "Rampant Growth" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354843".
  # "Giant Growth" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354867".
  # "Terminate" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354841".
  # "Mana Leak" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354872".
  # "Lightning Bolt" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354840".
  # "Searing Blaze" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354827".
  # "Terror" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354875".
  # "Sign in Blood" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354838".
  # "Fireball" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354874".
  # "Doom Blade" from "Magic Player Rewards" has an invalid Multiverse ID "-2143354829".
  # "Faithless Looting" from "Media Inserts" has an invalid Multiverse ID "-2147450841".
  # "Treasure Hunt" from "Media Inserts" has an invalid Multiverse ID "-2147450842".
  # "Serra Avatar" from "Media Inserts" has an invalid Multiverse ID "-2147450832".
  # "Dreg Mangler" from "Media Inserts" has an invalid Multiverse ID "-2147450825".
  # "Treasury Thrull" from "Prerelease Events" has an invalid Multiverse ID "-2147418048".
  # "Angel of Glory's Rise" from "Media Inserts" has an invalid Multiverse ID "-2147450821".
  # "Sunblast Angel" from "Media Inserts" has an invalid Multiverse ID "-2147450833".
  # "Terastodon" from "Media Inserts" has an invalid Multiverse ID "-2147450828".
  # "Fathom Mage" from "Prerelease Events" has an invalid Multiverse ID "-2147418051".
  # "Hypersonic Dragon" from "Prerelease Events" has an invalid Multiverse ID "-2147418056".
  # "Megantic Sliver" from "Prerelease Events" has an invalid Multiverse ID "-2147418045".
  # "Archon of the Triumvirate" from "Prerelease Events" has an invalid Multiverse ID "-2147418057".
  # "Anthousa, Setessan Hero" from "Prerelease Events" has an invalid Multiverse ID "-2147418040".
  # "Glissa, the Traitor" from "Prerelease Events" has an invalid Multiverse ID "-2147418064".
  # "Grove of the Guardian" from "Prerelease Events" has an invalid Multiverse ID "-2147418053".
  # "Consuming Aberration" from "Prerelease Events" has an invalid Multiverse ID "-2147418052".
  # "Foundry Champion" from "Prerelease Events" has an invalid Multiverse ID "-2147418050".
  # "Carnival Hellsteed" from "Prerelease Events" has an invalid Multiverse ID "-2147418055".
  # "Silent Sentinel" from "Prerelease Events" has an invalid Multiverse ID "-2147418039".
  # "Rubblehulk" from "Prerelease Events" has an invalid Multiverse ID "-2147418049".
  # "Corpsejack Menace" from "Prerelease Events" has an invalid Multiverse ID "-2147418054".
  # "Elvish Mystic" from "Friday Night Magic" has an invalid Multiverse ID "-2147385179".
  # "Sylvan Caryatid" from "Media Inserts" has an invalid Multiverse ID "-2147450803".
  # "Hive Stirrings" from "Magic Game Day Cards" has an invalid Multiverse ID "-2147352548".
  # "Doomwake Giant" from "Prerelease Events" has an invalid Multiverse ID "-2147418032".
  # "Bident of Thassa" from "Magic: The Gathering Launch Parties" has an invalid Multiverse ID "-2147319784".
  # "Phalanx Leader" from "Magic Game Day Cards" has an invalid Multiverse ID "-2147352546".
  # "Hamletback Goliath" from "Media Inserts" has an invalid Multiverse ID "-2147450809".
  # "Karametra's Acolyte" from "Media Inserts" has an invalid Multiverse ID "-2147450802".
  # "Kor Skyfisher" from "Media Inserts" has an invalid Multiverse ID "-2147450855".
  # "Oblivion Ring" from "Friday Night Magic" has an invalid Multiverse ID "-2147385230".
  # "Counterspell" from "Friday Night Magic" has an invalid Multiverse ID "-2147385278".
  # "Capsize" from "Friday Night Magic" has an invalid Multiverse ID "-2147385309".
  # "Giant Growth" from "Friday Night Magic" has an invalid Multiverse ID "-2147385336".
  # "Krosan Tusker" from "Friday Night Magic" has an invalid Multiverse ID "-2147385302".
  # "Wall of Roots" from "Friday Night Magic" has an invalid Multiverse ID "-2147385246".
  # "Terminate" from "Friday Night Magic" has an invalid Multiverse ID "-2147385274".
  # "Fireblast" from "Friday Night Magic" has an invalid Multiverse ID "-2147385326".
  # "Evolving Wilds" from "Friday Night Magic" has an invalid Multiverse ID "-2147385195".
  # "Warleader's Helix" from "Friday Night Magic" has an invalid Multiverse ID "-2147385180".
  # "Wild Nacatl" from "Friday Night Magic" has an invalid Multiverse ID "-2147385217".
  # "Forbidden Alchemy" from "Friday Night Magic" has an invalid Multiverse ID "-2147385198".
  # "Searing Spear" from "Friday Night Magic" has an invalid Multiverse ID "-2147385192".
  # "Mulldrifter" from "Friday Night Magic" has an invalid Multiverse ID "-2147385235".
  # "Grisly Salvage" from "Friday Night Magic" has an invalid Multiverse ID "-2147385182".
  # "Farseek" from "Friday Night Magic" has an invalid Multiverse ID "-2147385190".
  # "Rancor" from "Friday Night Magic" has an invalid Multiverse ID "-2147385288".
  # "Terror" from "Friday Night Magic" has an invalid Multiverse ID "-2147385342".
  # "Sakura-Tribe Elder" from "Friday Night Magic" has an invalid Multiverse ID "-2147385229".
  # "Wild Mongrel" from "Friday Night Magic" has an invalid Multiverse ID "-2147385271".
  # "Cultivate" from "Friday Night Magic" has an invalid Multiverse ID "-2147385209".
  # "River Boa" from "Friday Night Magic" has an invalid Multiverse ID "-2147385343".
  # "Blastoderm" from "Friday Night Magic" has an invalid Multiverse ID "-2147385285".
  # "Mogg Fanatic" from "Friday Night Magic" has an invalid Multiverse ID "-2147385315".
  # "Firebolt" from "Friday Night Magic" has an invalid Multiverse ID "-2147385264".
  # "Fireslinger" from "Friday Night Magic" has an invalid Multiverse ID "-2147385320".
  # "Carnophage" from "Friday Night Magic" has an invalid Multiverse ID "-2147385328".
  # "Desert" from "Friday Night Magic" has an invalid Multiverse ID "-2147385245".
  # "Teetering Peaks" from "Friday Night Magic" has an invalid Multiverse ID "-2147385208".
  # "Armadillo Cloak" from "Friday Night Magic" has an invalid Multiverse ID "-2147385275".
  # "Force Spike" from "Friday Night Magic" has an invalid Multiverse ID "-2147385253".
  # "Serrated Arrows" from "Friday Night Magic" has an invalid Multiverse ID "-2147385243".
  # "Deep Analysis" from "Friday Night Magic" has an invalid Multiverse ID "-2147385263".
  # "Sparksmith" from "Friday Night Magic" has an invalid Multiverse ID "-2147385303".
  # "Basking Rootwalla" from "Friday Night Magic" has an invalid Multiverse ID "-2147385261".
  # "Goblin Legionnaire" from "Friday Night Magic" has an invalid Multiverse ID "-2147385259".
  # "Qasali Pridemage" from "Friday Night Magic" has an invalid Multiverse ID "-2147385220".
  # "Arc Lightning" from "Arena League" has an invalid Multiverse ID "-2147254230".
  # "Dauthi Slayer" from "Arena League" has an invalid Multiverse ID "-2147254229".
  # "Skirk Marauder" from "Arena League" has an invalid Multiverse ID "-2147254222".
  # "Bonesplitter" from "Arena League" has an invalid Multiverse ID "-2147254220".
  # "Skyknight Legionnaire" from "Arena League" has an invalid Multiverse ID "-2147254198".
  # "Diabolic Edict" from "Arena League" has an invalid Multiverse ID "-2147254235".
  # "Gather the Townsfolk" from "WPN/Gateway" has an invalid Multiverse ID "-2147221425".
  # "Gravedigger" from "WPN/Gateway" has an invalid Multiverse ID "-2147221488".
  # "Woolly Thoctar" from "WPN/Gateway" has an invalid Multiverse ID "-2147221482".
  # "Maul Splicer" from "WPN/Gateway" has an invalid Multiverse ID "-2147221432".
  # "Boomerang" from "WPN/Gateway" has an invalid Multiverse ID "-2147221500".
  # "Mind Stone" from "WPN/Gateway" has an invalid Multiverse ID "-2147221493".
  # "Vault Skirge" from "WPN/Gateway" has an invalid Multiverse ID "-2147221433".
  # "Icatian Javelineers" from "WPN/Gateway" has an invalid Multiverse ID "-2147221502".
  # "Fated Conflagration" from "Media Inserts" has an invalid Multiverse ID "-2147450801".
  # "Ratchet Bomb" from "Media Inserts" has an invalid Multiverse ID "-2147450813".
  # "Kiora's Follower" from "Magic Game Day Cards" has an invalid Multiverse ID "-2147352543".
  # "Liliana's Specter" from "Magic Game Day Cards" has an invalid Multiverse ID "-2147352574".
  # "Scourge of Fleets" from "Prerelease Events" has an invalid Multiverse ID "-2147385265".
  # "Heroes' Bane" from "Prerelease Events" has an invalid Multiverse ID "-2147385262".
  # "Deep Analysis" from "Friday Night Magic" has an invalid Multiverse ID "-2147385263".
  # "Dawnbringer Charioteers" from "Prerelease Events" has an invalid Multiverse ID "-2147385266".
  # "Feast of Blood" from "Media Inserts" has an invalid Multiverse ID "-2147418069".
  # "Batterskull" from "Grand Prix" has an invalid Multiverse ID "-2147188726".
  # "Electrolyze" from "Media Inserts" has an invalid Multiverse ID "-2147418070".
  # "Arrest" from "Media Inserts" has an invalid Multiverse ID "-2147418059".

  
  # Now that all the mappings are setup, return the mapped value if it exists,
  # or return the original id
  if cardmapping.has_key?(cardid)
    return cardmapping[cardid]
  else
    return cardid
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
        cardid = getmultiverseid(card['card'].first['id'].first)
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

def mkdeckboxinv(cardxml,outputdir)
  require 'csv'
  CSV.open("#{outputdir}/main.csv", "wb") do |csv|
    csv << ['Count','Tradelist Count','Name','Foil','Textless','Promo','Signed','Edition','Condition','Language']
    cardxml['list'].first['mcp'].each do |card|
      if deckboxaccepts?(card)
        linetoadd = [card['count'].first]
        linetoadd << gettradecount(card)
        cardname = card['card'].first['name'].first.gsub(/ \(.*/, '').gsub("Æ", 'Ae')
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
        linetoadd << card['card'].first['edition'].first.gsub(/2012 Edition/, '2012').gsub(/2013 Edition/, '2013')
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
    
    options[:deckedoutfile] = false
    opts.on( '-d', '--deckedbuilder FILE', "Decked Builder output file" ) do |f|
      options[:deckedoutfile] = f
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
  
  mkdeckboxinv(mainxml,options[:outputdir])
end
