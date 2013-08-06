#!/usr/bin/env python
# -*- coding: utf-8 -*-

def main():
  import argparse
  parser = argparse.ArgumentParser(description='Takes Magic Assistant collections & turn them into DeckBox CSVs.')
  parser.add_argument('--inputfile', dest='collection', default='', help='Set a specific collection to be converted. (default=~/Dropbox/MagicAssistantWorkspace/magiccards/Collections/main.xml')
  parser.add_argument('--inputdir', default='', help='Set a directory to search for files which comprise your collection. (default=~/Dropbox/MagicAssistantWorkspace/)')
  parser.add_argument('--inventoryoutputfile', default='', help='Full path to the desired inventory output file. Requires --decklistoutputfile if used. (default=magicdeckboxinventory.csv in the output directory option)')
  parser.add_argument('--decklistoutputfile', default='', help='Full path to the desired decklist output file. Requires --inventoryoutputfile if used. (default=magiccollection.dec in the output directory option)')
  parser.add_argument('--outputdir', default='', help='Directory in which to place the generated inventory & decklist files. (default=~/Dropbox, ~/Ubuntu One, or the current working directory)')
  parser.add_argument("--singlecollectiononly", help="Don't recursively look for collections to convert", action="store_true")
  args = parser.parse_args()
  
  import os
  home = os.path.expanduser("~")

  if not args.outputdir == '':
    outputdirectoryprefix = args.outputdir
    inventoryOutputFileStr = args.outputdir + '/magicdeckboxinventory.csv'
    decklistOutputFileStr = args.outputdir + '/magiccollection.dec'
  else:
    if os.path.exists(home + '/Dropbox'):
      outputdirectoryprefix = home + '/Dropbox/DeckboxExports'
    elif os.path.exists(home + '/Ubuntu One'):
      outputdirectoryprefix = home + '/Ubuntu One/DeckboxExports'
    else:
      outputdirectoryprefix = os.getcwd()
      
    if not os.path.isdir(outputdirectoryprefix):
      os.makedirs(outputdirectoryprefix)
    elif os.path.isdir(outputdirectoryprefix):
	  os.removedirs(outputdirectoryprefix)
	  os.makedirs(outputdirectoryprefix)
    inventoryOutputFileStr = outputdirectoryprefix + '/magicdeckboxinventory.csv'
    decklistOutputFileStr = outputdirectoryprefix + '/magiccollection.dec'
    
  if args.singlecollectiononly:
    if args.inventoryoutputfile != '' or args.inventoryoutputfile != '':
      if (args.inventoryoutputfile != '' and args.inventoryoutputfile) or (args.inventoryoutputfile == '' and args.inventoryoutputfile != ''):
        print('--inventoryoutputfile & --decklistoutputfile must both be specified or left to default')
        from sys import exit
        exit()
      else:
        outputdirectoryprefix = ''
        inventoryOutputFileStr = args.inventoryoutputfile
        decklistOutputFileStr = args.decklistoutputfile
    if args.collection == '':
      if os.path.isfile(home + '/Dropbox/MagicAssistantWorkspace/magiccards/Collections/main.xml'):
        collectionFileStr = home + '/Dropbox/MagicAssistantWorkspace/magiccards/Collections/main.xml'
      elif os.path.isfile(home + '/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/main.xml'):
        collectionFileStr = home + '/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/main.xml'
      else:
        print('No suitable collection found!')
        from sys import exit
        exit()
    else:
      collectionFileStr = args.collection
      createfiles(collectionFileStr, inventoryOutputFileStr,decklistOutputFileStr)
  else:
    if os.path.exists(home + '/Dropbox/MagicAssistantWorkspace/magiccards/Collections/'):
      collectionFolderStr = home + '/Dropbox/MagicAssistantWorkspace/magiccards/Collections/'
    elif os.path.exists(home + '/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/'):
      collectionFolderStr = home + '/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/'
    else:
      print('Please specify a valid folder.')
      from sys import exit
      exit()
    
    import fnmatch
    
    listoffiles = []
    for root, dirnames, filenames in os.walk(collectionFolderStr):
      for filename in fnmatch.filter(filenames, '*.xml'):
        listoffiles.append(os.path.join(root, filename))
    for collectionfile in listoffiles:
      cleanfilename = os.path.splitext(os.path.basename(collectionfile))[0]
      inventoryOutputDynamicStr = outputdirectoryprefix + '/' + cleanfilename + ".csv"
      decklistOutputDynamicStr = outputdirectoryprefix + '/' + cleanfilename + ".dec"
      createfiles(collectionfile,inventoryOutputDynamicStr,decklistOutputDynamicStr)
      
def createfiles(collectionFileStr,inventoryOutputFileStr,decklistOutputFileStr):
  # Get the automatically converted CSV first (the staging file)
  generatedCSV = xml2csv(collectionFileStr)
  
  # Write the output file's header
  createdeckboxheader(inventoryOutputFileStr)

  # Finish the conversion
  createdeckboxinv(generatedCSV,inventoryOutputFileStr)

  # Create a decklist version as well
  createdecklist(generatedCSV,decklistOutputFileStr)

def createdeckboxheader(inventoryfile):
  import os
  f = open(inventoryfile,'w')
  f.write('Count,Tradelist Count,Name,Foil,Textless,Promo,Signed,Edition,Condition,Language' + os.linesep )
  f.close()


def createdeckboxinv(stagedcsv,inventoryfile):
  import csv
  import os
  
  with open(stagedcsv.name,"r") as source:
    rdr= csv.reader( source, delimiter=',', quotechar="\"", quoting=csv.QUOTE_ALL, skipinitialspace=True)
    rdr.next()
    with open(inventoryfile,"a") as result:
      wtr= csv.writer( result, delimiter=',', quoting=csv.QUOTE_MINIMAL, lineterminator=os.linesep)
      #wtr.writerow((["Count"] + ["Tradelist Count"] + ["Name"] + ["Foil"] + ["Textless"] + ["Promo"] + ["Signed"] + ["Edition"] + ["Condition"] + ["Language"]))
      for r in rdr:
        # Check for foil, promo, or condition status
        if len(r) > 7:
          if len(r) > 8:
            statusOffset = 1
          else:
            statusOffset = 0
          if "foil" in r[7 + statusOffset]:
            foilstatus = "foil"
          else:
            foilstatus = ""
          if "promo" in r[7 + statusOffset]:
            promostatus = "promo"
          else:
            promostatus = ""
          if "mint" in r[7 + statusOffset]:
            condition = "Mint"
          elif "nearmint" in r[7 + statusOffset]:
            condition = "Near Mint"
          elif "played" in r[7 + statusOffset]:
            condition = "Played"
          else:
            condition = "Near Mint"
        else:
          foilstatus = ""
          promostatus = ""
          condition = "Near Mint"
        # Set tradecount based on the number available
        # Set all non promo foils to trade status
        if ("foil" in foilstatus) and ("promo" not in promostatus):
          tradecount = int(r[4].replace("\"","").replace(" ",""))
        else:
          if (int(r[4].replace("\"","").replace(" ","")) - 4) >= 0:
            tradecount = int(r[4].replace("\"","").replace(" ","")) - 4
          else:
            tradecount = 0
        # Override the amount listed available for trade
        # If in a duel deck, none are available
        if ("Duel Deck" in r[2]):
          tradecount = 0
        # Set up the name
        if ("(" in r[1]):
          cardname = r[1].replace("Æ","Ae").split(" (")[0]
        else:
          cardname = r[1].replace("Æ","Ae")
        # Write the line to the file
        if "loan to me" not in r[5]:
          wtr.writerow([r[4].replace("\"","").replace(" ","")] + [tradecount] + [cardname] + [foilstatus] + [r[3].replace("\"","").replace(" ","")] + [promostatus] + [r[3].replace("\"","").replace(" ","")] + [r[2].replace("\"","").replace("2012 Edition","2012")] + [condition] + ["English"])
        else:
          rdr.next()

def createdecklist(stagedcsv,decklistfile):
  import csv
  from time import strftime
  import os
  
  with open(stagedcsv.name,"r") as source:
    rdr= csv.reader( source, delimiter=',', quotechar="\"", quoting=csv.QUOTE_ALL, skipinitialspace=True)
    rdr.next()
    with open(decklistfile,"w") as result:
      result.write('// Generated on ' + strftime("%Y-%m-%d %H:%M:%S") + os.linesep)
      for r in rdr:
        if "loan to me" not in r[5]:
          result.write(' ' + r[4] + ' ' + r[1] + os.linesep)
        else:
          rdr.next()


def xml2csv(collection):
  # This function (c) Kailash Nadh, October 2011
  # Used under the MIT License
  import codecs, xml.etree.ElementTree as et

  import tempfile
  tempfileObj = tempfile.NamedTemporaryFile()
  
  # output file handle
  output = codecs.open(tempfileObj.name, "w", encoding='utf-8')
  
  # open the xml file for iteration
  context = et.iterparse(collection, events=("start", "end"))
  context = iter(context)
  # get to the root
  event, root = context.next()
  
  items = []; tags = []; output_buffer = []
  tagged = False
  started = False
  n = 0
  
  # iterate through the xml
  for event, elem in context:
    if event == 'start' and elem.tag == 'mcp' and not started:
      started = True
  
    if started and event == 'end' and elem.tag != 'mcp':    #child nodes of the specified record tag
      tags.append(elem.tag) if tagged == False else True    # csv header (element tag names)
      items.append( '' if elem.text == None or elem.text.strip() == '' else elem.text.replace('"', '\\\"') )
      
    # end of traversing the record tag
    if event == 'end' and elem.tag == 'mcp' and len(items) > 0:
      # csv header (element tag names)
      output.write('#' + (', ').join(tags) + '\n') if tagged == False else True
      tagged = True
  
      # send the csv to buffer
      output_buffer.append('\"' + ('\"' + ', ' + '\"').join(items) + '\"')
      items = []
      n+=1
          
      # flush buffer to disk
      if len(output_buffer) > '1000':
        output.write(  '\n'.join(output_buffer) + '\n' )
        output_buffer = []
  
  output.write(  '\n'.join(output_buffer) + '\n' )
  output_buffer = []


  return tempfileObj

if __name__ == "__main__":
  main()
