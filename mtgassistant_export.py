#!/usr/bin/env python
# -*- coding: utf-8 -*-

def main():
  import argparse
  parser = argparse.ArgumentParser(description='Takes Magic Assistant collections & turn them into Deckbox.org CSVs & Apprentice-format .DECs.')
  parser.add_argument('--inputfile', dest='collection', default='', help='Set a specific collection to be converted. (default=~/Dropbox/MagicAssistantWorkspace/magiccards/Collections/main.xml)')
  parser.add_argument('--inputdir', default='', help='Set a directory to search for files which comprise your collection. (default=~/Dropbox/MagicAssistantWorkspace/)')
  parser.add_argument('--inventoryoutputfile', default='', help='Full path to the desired inventory output file. Requires --decklistoutputfile if used. (default=magicdeckboxinventory.csv in the output directory option)')
  parser.add_argument('--decklistoutputfile', default='', help='Full path to the desired decklist output file. Requires --inventoryoutputfile if used. (default=magiccollection.dec in the output directory option)')
  parser.add_argument('--outputdir', default='', help='Directory in which to place the generated inventory & decklist files. (default=~/Dropbox, ~/Ubuntu One, or the current working directory)')
  parser.add_argument("--singlecollectiononly", help="Don't recursively look for collections to convert", action="store_true")
  parser.add_argument("-f", dest='force', help="Don't warn prior to overwriting the export directory", action="store_true")
  args = parser.parse_args()
  
  import os
  home = os.path.expanduser("~")

  if not args.outputdir == '':
    outputdirectoryprefix = os.path.join(args.outputdir, '')
    inventoryOutputFileStr = outputdirectoryprefix + 'magicdeckboxinventory.csv'
    decklistOutputFileStr = outputdirectoryprefix + 'magiccollection.dec'
  else:
    if os.path.exists(os.path.join(home, 'Dropbox')):
      outputdirectoryprefix = os.path.join(home, 'Dropbox', 'Magic Assistant Exports')
    elif os.path.exists(os.path.join(home, 'Ubuntu One')):
      outputdirectoryprefix = os.path.join(home, 'Ubuntu One', 'Magic Assistant Exports')
    else:
      outputdirectoryprefix = os.getcwd()
      
    # Prompt prior to directory removal
    if not args.force:
      print('\nWarning: \"' + outputdirectoryprefix + '\" will be completely overwritten!\n')
      #warningResultBool = query_yes_no()
      if not query_yes_no("Proceed?"):
        from sys import exit
        exit()
      else:
        print('Proceeding; this prompt can be suppressed in the future with the -f flag')
    if not os.path.isdir(outputdirectoryprefix):
      os.makedirs(outputdirectoryprefix)
    elif os.path.isdir(outputdirectoryprefix):
      emptyfolder(outputdirectoryprefix)
    inventoryOutputFileStr = os.path.join(outputdirectoryprefix, 'magicdeckboxinventory.csv')
    decklistOutputFileStr = os.path.join(outputdirectoryprefix, 'magiccollection.dec')
    
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
      if os.path.isfile(os.path.join(home, 'Dropbox', 'MagicAssistantWorkspace', 'magiccards', 'Collections', 'main.xml')):
        collectionFileStr = os.path.join(home, 'Dropbox', 'MagicAssistantWorkspace', 'magiccards', 'Collections', 'main.xml')
      elif os.path.isfile(os.path.join(home, 'Ubuntu One', 'MagicAssistantWorkspace', 'magiccards', 'Collections', 'main.xml')):
        collectionFileStr = os.path.join(home, 'Ubuntu One', 'MagicAssistantWorkspace', 'magiccards', 'Collections', 'main.xml')
      else:
        print('No suitable collection found!')
        from sys import exit
        exit()
    else:
      collectionFileStr = args.collection
      createfiles(collectionFileStr, inventoryOutputFileStr,decklistOutputFileStr)
  else:
    if not args.inputdir == '':
      os.path.join(args.inputdir, '') # will add trailing slash if necessary
    else:
      if os.path.exists(os.path.join(home, 'Dropbox', 'MagicAssistantWorkspace', 'magiccards', 'Collections', '')):
        collectionFolderStr = os.path.join(home, 'Dropbox', 'MagicAssistantWorkspace', 'magiccards', 'Collections', '')
      elif os.path.exists(os.path.join(home, 'Ubuntu One', 'MagicAssistantWorkspace', 'magiccards', 'Collections', '')):
        collectionFolderStr = os.path.join(home, 'Ubuntu One', 'MagicAssistantWorkspace', 'magiccards', 'Collections', '')
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
      inventoryOutputDynamicStr = os.path.join(outputdirectoryprefix, cleanfilename) + ".csv"
      decklistOutputDynamicStr = os.path.join(outputdirectoryprefix, cleanfilename) + ".dec"
      createfiles(collectionfile,inventoryOutputDynamicStr,decklistOutputDynamicStr)
    mergefilesexport(outputdirectoryprefix)
      
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

def mergefilesexport(outputdirectory):
  import os
  import fnmatch
  import csv
  
  for root, dirnames, filenames in os.walk(outputdirectory):
    files = []
    for f in fnmatch.filter(filenames, '*.csv'):
      files.append(os.path.join(root, f))
    outfile = os.path.join(outputdirectory, 'Summary.csv')

  with open(outfile, 'w') as f_out:
    dict_writer = None
    for f in files:
      with open(f, 'r') as f_in:
        dict_reader = csv.DictReader(f_in)
        if not dict_writer:
          dict_writer = csv.DictWriter(f_out, lineterminator='\n', fieldnames=dict_reader.fieldnames)
          dict_writer.writeheader()
        for row in dict_reader:
          dict_writer.writerow(row)

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
          if ("Forest" in r[1]):
            tradecount = 0
          elif ("Island" in r[1]):
            tradecount = 0
          elif ("Mountain" in r[1]):
            tradecount = 0
          elif ("Plains" in r[1]):
            tradecount = 0
          elif ("Swamp" in r[1]):
            tradecount = 0
          elif (int(r[4].replace("\"","").replace(" ","")) - 4) >= 0:
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
        # Set up the edition
        cardedition = r[2].replace("\"","").replace("vs.", "vs").replace("2012 Edition","2012").replace('Time Spiral \\Timeshifted\\','Time Spiral \"Timeshifted\"\"').replace('\"\"','\"')
        # Write the line to the file
        if "loan to me" not in r[5]:
          wtr.writerow([r[4].replace("\"","").replace(" ","")] + [tradecount] + [cardname] + [foilstatus] + [r[3].replace("\"","").replace(" ","")] + [promostatus] + [r[3].replace("\"","").replace(" ","")] + [cardedition] + [condition] + ["English"])
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

def query_yes_no(question, default="yes"):
  # http://stackoverflow.com/questions/3041986/python-command-line-yes-no-input
  """Ask a yes/no question via raw_input() and return their answer.

  "question" is a string that is presented to the user.
  "default" is the presumed answer if the user just hits <Enter>.
  It must be "yes" (the default), "no" or None (meaning
  an answer is required of the user).

  The "answer" return value is one of "yes" or "no".
  """
  import sys
  valid = {"yes":True, "y":True, "ye":True, "no":False, "n":False}
  if default == None:
    prompt = " [y/n] "
  elif default == "yes":
    prompt = " [Y/n] "
  elif default == "no":
    prompt = " [y/N] "
  else:
    raise ValueError("invalid default answer: '%s'" % default)

  while True:
    sys.stdout.write(question + prompt)
    choice = raw_input().lower()
    if default is not None and choice == '':
      return valid[default]
    elif choice in valid:
      return valid[choice]
    else:
      sys.stdout.write("Please respond with 'yes' or 'no' (or 'y' or 'n').\n")

def emptyfolder(folder):
  import os 
  for the_file in os.listdir(folder):
    file_path = os.path.join(folder, the_file)
    try:
      if os.path.isfile(file_path):
        os.remove(file_path)
    except Exception, e:
      print e

if __name__ == "__main__":
  main()
