#!/usr/bin/env ruby
# encoding: utf-8

# Copyright 2015 Troy Ready
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
# mainxml['list'].first['mcp'].first
# {
# "card"=>[
#   {"id"=>["152727"], "name"=>["Disperse"], "edition"=>["Morningtide"]}
# ],
# "count"=>["2"],
# "location"=>["Collections/main"],
# "ownership"=>["true"]
# }
#
# mainxml['list'].first['mcp'].first
# {
# "card"=>[
#   {"id"=>["280320"], "name"=>["Intrepid Hero"], "edition"=>["Magic 2013"]}
# ],
# "count"=>["1"],
# "location"=>["Collections/main"],
# "ownership"=>["true"],
# "special"=>["foil"]
# }

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'net/http'
require 'uri'
require 'yaml/store'

# Returns an object with the file's parsed contents
def parsexml(xmlfile)
  require 'xmlsimple'
  XmlSimple.xml_in(xmlfile)
end

def hasparm?(parm, cardobj)
  if cardobj['special']
    # Check to see if there are multiple special tags, which will be shown in
    # an array
    if cardobj['special'].is_a?(Array)
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

def sendtodeckbox?(cardobj)
  if cardobj['special']
    !cardobj['special'].first.include?('loantome')
  else
    true
  end
end

def sendtodeckedbuilder?(cardobj)
  # Planechase plains are the specific names here - they're included in the
  # regular Deckbox 'Planechase' set, but are not on Gatherer
  !(
    (cardobj['special'] && cardobj['special'].first.include?('loantome')) ||
    cardobj['card'].first['edition'].first.start_with?('Extras:') ||
    cardobj['card'].first['edition'].first.start_with?('Oversized:') ||
    cardobj['card'].first['name'].first.start_with?('Mirrored Depths') ||
    cardobj['card'].first['name'].first.start_with?('Horizon Boughs') ||
    cardobj['card'].first['name'].first.start_with?('Celestine Reef') ||
    cardobj['card'].first['name'].first.start_with?('Tember City')
  )
end

def sendtomtgprice?(cardobj)
  name = cardobj['card'].first['name'].first
  edition = cardobj['card'].first['edition'].first
  if (cardobj['special'] && cardobj['special'].first.include?('loantome')) ||
     edition.start_with?('Extras:') ||
     edition.start_with?('Oversized:') ||
     edition.start_with?('Modern Event Deck 2014') ||
     edition.start_with?('Ugin\'s Fate ') ||
     # Planechase plains are the specific names here - they're included in the
     # regular Deckbox 'Planechase' set, but are not on Gatherer
     name.start_with?('Mirrored Depths') ||
     name.start_with?('Horizon Boughs') ||
     name.start_with?('Celestine Reef') ||
     name.start_with?('Tember City') ||
     # Import can't handle the nested comma here
     name.start_with?('Borrowing 100,000 Arrows') ||
     ( %w(Plains Island Swamp Mountain Forest).include?(name) &&
       [
         'Battle for Zendikar',
         'Commander 2013 Edition',
         'Commander 2014',
         'Dragons of Tarkir',
         'Duel Decks: Elspeth vs. Kiora',
         'Duel Decks: Heroes vs. Monsters',
         'Duel Decks: Jace vs. Vraska',
         'Duel Decks: Sorin vs. Tibalt',
         'Duel Decks: Speed vs. Cunning',
         'Fate Reforged',
         'Khans of Tarkir',
         'Magic 2012',
         'Magic 2015 Core Set',
         'Theros'
       ].include?(edition) )
    return false
  else
    return true
  end
end

def gettradecount(cardobj, tradelistfile, tradecountdefault)
  name = cardobj['card'].first['name'].first
  edition = cardobj['card'].first['edition'].first
  # Return no cards for trade if not overridden below
  if (cardobj['count'].first.to_i < tradecountdefault) &&
     tradelistfile == ''
    return '0'
  elsif tradelistfile != ''
    require 'yaml/store'
    store = YAML::Store.new(tradelistfile)
    if store.transaction { store[name] } &&
       (edition == (store.transaction { store[name]['edition'] })) &&
       (hasparm?('foil', cardobj) ==
       (store.transaction { store[name]['foil'] }))
      return store.transaction { store[name]['trade_count'] }
    end
  end
  case (cardobj['count'].first.to_i - tradecountdefault) > 0
  when true
    (cardobj['count'].first.to_i - tradecountdefault).to_s
  else
    0.to_s
  end
end

def mkdecklist(xml, outputdir)
  decklistnames = []
  decklistcount = []
  xml['list'].first['mcp'].each do |card|
    name = card['card'].first['name'].first
    next if (card['special'] && card['special'].first.include?('loantome')) ||
            card['card'].first['edition'].first.start_with?('Extras:')
    if decklistnames.include?(name)
      decklistcount[decklistnames.index(name)] += card['count'].first.to_i
    else
      decklistnames << name
      decklistcount << card['count'].first.to_i
    end
  end
  sorteddecklist = decklistnames.sort
  decklist = []
  sorteddecklist.each do |card|
    decklist << {
      'name' => card,
      'count' => decklistcount[decklistnames.index(card)].to_s
    }
  end
  File.open("#{outputdir}/main.dec", 'wb') do |f|
    f.puts "// Generated on #{Time.new}\n"
    decklist.each do |card|
      f.puts "#{card['count']} #{card['name']}\n"
    end
  end
  File.open("#{outputdir}/main_mtgshoebox.dec", 'wb') do |f|
    decklist.each do |card|
      next if ['Celestine Reef',
               'Horizon Boughs',
               'Mirrored Depths',
               'Tember City'
              ].include?(card['name'])
      f.puts "#{card['count']} #{card['name'].gsub(/ \(['a-zA-Z]*\)$/, '')}\n"
    end
  end
end

def getmultiverseid(cardid, cardname)
  # This will translate your custom database entries into
  # standard multiverse IDs

  uri = URI.parse(
    "http://api.mtgapi.com/v1/card/name/#{cardname.gsub(/ /, '%20')}"
  )

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  if response.code == '200'
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
    puts "Translating card #{cardname} (card id #{cardid}) to card id "\
         "#{new_card_id} for Decked Builder"
    return new_card_id
  else
    puts "Unable to translate card #{cardname} (card id #{cardid}) - mtgapi "\
         "returned http code #{response.code}"
    return cardid
  end
end

def getcollnumber(cardid, cardname)
  # This will find the card collector number for a given card

  uri = URI.parse("http://api.mtgapi.com/v2/cards?multiverseid=#{cardid}")

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  if response.code == '200'
    result = JSON.parse(response.body)
    return result['cards'][0]['number']
  else
    puts "Unable to find collector's number for #{cardname} - mtgapi "\
         "returned http code #{response.code}"
    return ''
  end
end

def mkcoll2(xml, outputfile)
  # Using a temporary array of card ids as a way of quickly checking which
  # cards have already been encountered
  cardids = []
  cards = []
  xml['list'].first['mcp'].each do |card|
    next unless sendtodeckedbuilder?(card)
    # Custom sets in Magic Assistant start with a -
    cardid = ''
    if card['card'].first['id'].first.start_with?('-')
      # FIXME: adding a manual workaround for broken split card
      # Once new api is stable should switch to it and refactor
      if card['card'].first['name'].first == 'Fire // Ice (Fire)'
        cardid = '27166'
      else
        cardid = getmultiverseid(
          card['card'].first['id'].first,
          card['card'].first['name'].first
        )
      end
    else
      cardid = card['card'].first['id'].first
    end
    # Now we've translated IDs where possible; proceed with adding the cards
    # to the staging array for writing, unless they still have an invalid ID
    if cardid.start_with?('-')
      puts "Skipping card \"#{card['card'].first['name'].first}\" from "\
           "\"#{card['card'].first['edition'].first}\" due to its invalid "\
           "Multiverse ID \"#{cardid}\"."
    else
      if cardids.include?(cardid)
        # We've already encountered this multiverseid at least once, so
        # increment ownership numbers instead
        if card['special'] && card['special'].first.include?('foil')
          cards[cardids.index(cardid)]['foils'] += card['count'].first.to_i
        else
          cards[cardids.index(cardid)]['regulars'] += card['count'].first.to_i
        end
      else
        # This means that we haven't encountered this multiverse id before
        # Now that we're adding it to the cards array, note here that
        # we've encountered it
        cardids << cardid
        newcard = {}
        newcard['id'] = cardid
        if card['special'] && card['special'].first.include?('foil')
          newcard['regulars'] = 0
          newcard['foils'] = card['count'].first.to_i
        else
          newcard['regulars'] = card['count'].first.to_i
          newcard['foils'] = 0
        end
        cards << newcard
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
      f.puts "    - r: #{card['regulars']}\n" if card['regulars'] > 0
      f.puts "    - f: #{card['foils']}\n" if card['foils'] > 0
    end
  end
end

def mkdeckboxinv(cardxml, outputdir, tradelistfile, tradecountdefault)
  require 'csv'
  CSV.open("#{outputdir}/main.csv", 'wb') do |csv|
    csv << [
      'Count',
      'Tradelist Count',
      'Name',
      'Edition',
      'Card Number',
      'Condition',
      'Language',
      'Foil',
      'Signed',
      'Artist Proof',
      'Altered Art',
      'Misprint',
      'Promo',
      'Textless',
      'My Price'
    ]
    cardxml['list'].first['mcp'].each do |card|
      next unless sendtodeckbox?(card)
      linetoadd = [card['count'].first]
      linetoadd << gettradecount(card, tradelistfile, tradecountdefault)
      cardname = card['card'].first['name'].first
                 .gsub(/ \(.*/, '')
                 .gsub('Æ', 'Ae')
                 .gsub('Lim-Dûl\'s Vault', 'Lim-Dul\'s Vault')
      linetoadd << cardname
      linetoadd << card['card'].first['edition'].first
        .gsub(/2012 Edition/, '2012')
        .gsub(/2013 Edition/, '2013')
        .gsub(/Magic: The Gathering—Conspiracy/, 'Conspiracy')
        .gsub(/Annihilation \(2014\)/, 'Annihilation')
      # Check to see if the collector number should be added
      # First check is to see if it's a basic land
      if %w(Plains Island Swamp Mountain Forest).include?(
        card['card'].first['name'].first
      ) && !(card['card'].first['id'].first.start_with?('-'))
        collnumber = getcollnumber(
          card['card'].first['id'].first,
          card['card'].first['name'].first
        )
        linetoadd << collnumber
      # Next, if the card is a token (or otherwise from the 'Extras' deckbox
      # set), map its collectors number to the last two digits of its
      # multiverse id
      elsif card['card'].first['edition'].first.start_with?('Extras:')
        linetoadd << card['card'].first['id'].first
          .split(//)
          .last(2)
          .join('')
          .to_s
      else
        linetoadd << ''
      end
      if hasparm?('played', card)
        linetoadd << 'Played'
      else
        linetoadd << 'Near Mint'
      end
      # FIXME: Language check?
      linetoadd << 'English'
      if hasparm?('foil', card)
        linetoadd << 'foil'
      else
        linetoadd << ''
      end
      # FIXME: Signed check
      linetoadd << ''
      # FIXME: Artist Proof check
      linetoadd << ''
      # FIXME: Altered Art check
      linetoadd << ''
      # FIXME: Misprint check
      linetoadd << ''
      if hasparm?('promo', card)
        linetoadd << 'promo'
      else
        linetoadd << ''
      end
      if hasparm?('textless', card)
        linetoadd << 'textless'
      else
        linetoadd << ''
      end
      # FIXME: My Price check
      linetoadd << ''
      csv << linetoadd
    end
  end
end

def mk_deckbox_wishlist(cardxml, wishlist_yaml_file, outputdir)
  require 'csv'
  require 'yaml'
  wishlist_minimum = YAML.load(File.read(wishlist_yaml_file))
  CSV.open("#{outputdir}/wishlist.csv", 'wb') do |csv|
    csv << [
      'Count',
      'Name',
      'Edition',
      'Card Number',
      'Condition',
      'Language',
      'Foil',
      'Signed',
      'Artist Proof',
      'Altered Art',
      'Misprint',
      'Promo',
      'Textless'
    ]
    wishlist_minimum.each do |card, v|
      card_count = v['count'].to_i
      cardxml['list'].first['mcp'].each do |inv_card|
        next if !sendtodeckbox?(inv_card) ||
                card != inv_card['card'].first['name'].first
        card_count -= inv_card['count'].first.to_i
      end
      next unless card_count > 0
      card_to_add = [card_count, card, '']
      if v['edition']
        card_to_add << v['edition']
      else
        card_to_add << nil
      end
      9.times {card_to_add << nil} # matches their file's number of commas
      csv << card_to_add
    end
  end
end

def mk_mtg_price(cardxml, outputdir)
  require 'csv'
  require 'yaml/store'
  mtgprice_mapping = YAML.load(
    File.read(
      File.join(
        File.dirname(__FILE__),
        'config',
        'mtgprice_mapping.yml'
      )
    )
  )
  card_hash = {}
  cardxml['list'].first['mcp'].each do |card|
    next unless sendtomtgprice?(card)
    cardname = case mtgprice_mapping.has_key? card['card'].first['id'].first
               when true
                 mtgprice_mapping[card['card'].first['id'].first]['name']
               else
                 card['card'].first['name'].first
                 .gsub(/ \(.*/, '')
                 .gsub('Æ', 'Ae')
                 .gsub('Lim-Dûl', 'Lim-Dul')
               end
    edition = card['card'].first['edition'].first
              .gsub(/.*Clash Pack Promos/, 'Clash Packs')
              .gsub(/Magic Game Day Cards/, 'Game Day')
              .gsub(/Magic Player Rewards/, 'Player Rewards')
              .gsub(/Prerelease Events:.*/, 'Prerelease Events')
              .gsub(%r{WPN/Gateway}, 'Gateway')
              .gsub(/Unlimited Edition/, 'Unlimited')
              .gsub(/Revised Edition/, 'Revised')
              .gsub(/Fourth Edition/, '4th Edition')
              .gsub(/Fifth Edition/, '5th Edition')
              .gsub(/Classic Sixth Edition/, '6th Edition')
              .gsub(/Seventh Edition/, '7th Edition')
              .gsub(/Eighth Edition/, '8th Edition')
              .gsub(/Ninth Edition/, '9th Edition')
              .gsub(/Tenth Edition/, '10th Edition')
              .gsub(/Urza's/, 'Urzas')
              .gsub(/Ravnica: City of Guilds/, 'Ravnica')
              .gsub(/Time Spiral "Timeshifted"/, 'Timespiral Timeshifted')
              .gsub(/Planechase 2012 Edition/, 'Planechase 2012')
              .gsub(/Magic 2010/, 'M10')
              .gsub(/Magic 2011/, 'M11')
              .gsub(/Magic 2012/, 'M12')
              .gsub(/Magic 2013/, 'M13')
              .gsub(/Magic 2014 Core Set/, 'M14')
              .gsub(/Magic 2015 Core Set/, 'M15')
              .gsub(/Dragon's Maze/, 'Dragons Maze')
              .gsub(/From the Vault:/, 'From the Vault')
              .gsub(/Commander 2013 Edition/, 'Commander 2013')
              .gsub(/Magic: The Gathering—Conspiracy/, 'Conspiracy')
              .gsub(/Annihilation \(2014\)/, 'Annihilation')
    if [
      'Akoum',
      'Aretopolis',
      'Astral Arena',
      'Bloodhill Bastion',
      'Chaotic Aether',
      'Edge of Malacol',
      'Furnace Layer',
      'Gavony',
      'Glen Elendra',
      'Grand Ossuary',
      'Grove of the Dreampods',
      'Hedron Fields of Agadeem',
      'Interplanar Tunnel',
      'Jund',
      'Kessig',
      'Kharasha Foothills',
      'Kilnspire District',
      'Lair of the Ashen Idol',
      'Morphic Tide',
      'Mount Keralia',
      'Mutual Epiphany',
      'Nephalia',
      'Norn\'s Dominion',
      'Onakke Catacomb',
      'Orochi Colony',
      'Orzhova',
      'Planewide Disaster',
      'Prahv',
      'Quicksilver Sea',
      'Reality Shaping',
      'Selesnya Loft Gardens',
      'Spatial Merging',
      'Stairs to Infinity',
      'Stensia',
      'Takenuma',
      'Talon Gates',
      'The Zephyr Maze',
      'Time Distortion',
      'Trail of the Mage-Rings',
      'Truga Jungle',
      'Windriddle Palaces'
    ].include?(cardname) && edition == 'Planechase 2012'
      edition = 'Planechase 2012 Planes'
    end
    if !(edition.include?('Arena League') ||
         edition.include?('Clash Packs') ||
         edition.include?('Duel Decks') ||
         edition.include?('Friday Night Magic') ||
         edition.include?('From the Vault') ||
         edition.include?('Game Day') ||
         edition.include?('Gateway') ||
         edition.include?('Grand Prix') ||
         edition.include?('Judge Gift') ||
         edition.include?('Launch Parties') ||
         edition.include?('Media Inserts') ||
         edition.include?('Player Rewards') ||
         edition.include?('Prerelease ')) &&
       hasparm?('foil', card)
      edition = "#{edition} (Foil)"
      foil = 'true'
    else
      foil = 'false'
    end
    if card_hash.key?("#{cardname}---#{edition}")
      card_hash["#{cardname}---#{edition}"]['count'] =
        (card_hash["#{cardname}---#{edition}"]['count'].to_i +
        card['count'].first.to_i).to_s
    else
      card_hash["#{cardname}---#{edition}"] =
        {
          'name' => cardname,
          'edition' => edition,
          'foil' => foil,
          'count' => card['count'].first
        }
    end
  end

  card_hash = CSV.generate do |csv|
    card_hash.sort.map do |_k, v|
      csv << [v['count'],
              "#{v['name']}FORCE_COMMAS,",
              v['edition'],
              v['foil']]
    end
  end

  File.open("#{outputdir}/mtgprice_coll.csv", 'wb') do |f|
    f.puts card_hash.gsub!(/FORCE_COMMAS,/, '')
  end
end

if __FILE__ == $PROGRAM_NAME

  require 'optparse'
  require 'pathname'

  # This hash will hold all of the options
  # parsed from the command-line by
  # OptionParser.
  options = {}

  optparse = OptionParser.new do|opts|
    # TODO: Put command-line options here

    options[:inputfile] = ''
    opts.on('-i', '--input FILE', 'Input XML file') do |f|
      options[:inputfile] = f
    end

    options[:outputdir] = ''
    opts.on('-o', '--output DIR', 'Output directory') do |f|
      options[:outputdir] = f
    end

    options[:deckedoutfile] = false
    opts.on('-d', '--deckedbuilder FILE', 'Decked Builder output file') do |f|
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
    opts.on('-t', '--tradelist FILE', 'Manual tradelist file') do |f|
      options[:tradelistfile] = f
    end

    options[:tradecountdefault] = 4
    opts.on(
      '-T',
      '--tradecountdefault N',
      'Cards above this number will be considered trade-able; defaults to 4'
    ) do |f|
      options[:tradecountdefault] = f.to_i
    end

    # Optional YAML file to generate a deckbox wishlist
    # This will be evaluated against your collection
    # E.g, if your wishlist count is 4, and you own 3 copies of the card,
    # the generated wishlist will have a count of 1
    #
    # yaml file example
    # ---
    # Fog:
    #   edition: Magic 2013
    #   count: 3
    # Giant Growth:
    # (etc)
    opts.on('-w', '--wishlist-yaml FILE', 'Wishlist yaml file') do |f|
      options[:wishlist_yaml_file] = f
    end

    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on('-h', '--help', 'Display this screen') do
      puts opts
      exit
    end
  end

  optparse.parse!

  if options[:inputfile].nil?
    print 'Enter input XML file: '
    options[:inputfile] = gets.chomp
  end

  if options[:outputdir].nil?
    print 'Enter output directory for files: '
    options[:outputdir] = Pathname(gets.chomp).cleanpath.to_s
  end

  unless Pathname(options[:outputdir]).directory?
    puts "\"#{options[:outputdir]}\" is not a valid directory"
  end

  # Option set; start the processing
  mainxml = parsexml(options[:inputfile])

  mkdecklist(mainxml, options[:outputdir])

  mkcoll2(mainxml, options[:deckedoutfile]) if options[:deckedoutfile]

  mkdeckboxinv(
    mainxml,
    options[:outputdir],
    options[:tradelistfile],
    options[:tradecountdefault]
  )

  mk_deckbox_wishlist(mainxml, options[:wishlist_yaml_file], options[:outputdir]) if options[:wishlist_yaml_file]

  mk_mtg_price(mainxml, options[:outputdir])
end
