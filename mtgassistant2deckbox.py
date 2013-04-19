#!/usr/bin/python

import csv

#from Tkinter import Tk
#from tkFileDialog import askopenfilename

#Tk().withdraw() # we don't want a full GUI, so keep the root window from appearing
#filename = askopenfilename() # show an "Open" dialog box and return the path to the selected file

from os.path import expanduser
home = expanduser("~")

stagingfile = home + "/magicassistantutils/magicdeckboxstaging.csv"
invfile = home + "/Ubuntu One/magicdeckboxinventory.csv"
wishfile = home + "/Ubuntu One/magicdeckboxwishlist.csv"

with open(stagingfile,"rb") as source:
#with open(filename,"rb") as source:
    rdr= csv.reader( source, delimiter=',', quotechar="\"", quoting=csv.QUOTE_ALL, skipinitialspace=True)
    rdr.next()
    with open(invfile,"wb") as result:
        wtr= csv.writer( result, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        wtr.writerow((["Count"] + ["Tradelist Count"] + ["Name"] + ["Foil"] + ["Textless"] + ["Promo"] + ["Signed"] + ["Edition"] + ["Condition"] + ["Language"]))
        for r in rdr:
            # Check for foil or promo status
            if len(r) > 7:
                if len(r) > 8:
                    if "foil" in r[8]:
                        foilstatus = "foil"
                    else:
                        foilstatus = ""
                    if "promo" in r[8]:
                        promostatus = "promo"
                    else:
                        promostatus = ""
                else:
                    if "foil" in r[7]:
                        foilstatus = "foil"
                    else:
                        foilstatus = ""
                    if "promo" in r[7]:
                        promostatus = "promo"
                    else:
                        promostatus = ""
            else:
                foilstatus = ""
                promostatus = ""
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
            # Write the line to the file
            if "loan to me" not in r[5]:
                wtr.writerow([r[4].replace("\"","").replace(" ","")] + [tradecount] + [r[1].decode("ascii", "ignore").encode("ascii").replace("ther Membrane","Aether Membrane").replace("therize","Aetherize").replace("Death (Death)","Death").replace("Ice (Fire)","Ice")] + [foilstatus] + [r[3].replace("\"","").replace(" ","")] + [promostatus] + [r[3].replace("\"","").replace(" ","")] + [r[2].replace("\"","").replace("2012 Edition","2012")] + ["Near Mint"] + ["English"])
            else:
                rdr.next()

# Again, this time for the wishlist
with open(stagingfile,"rb") as source:
#with open(filename,"rb") as source:
    wishrdr= csv.reader( source, delimiter=',', quotechar="\"", quoting=csv.QUOTE_ALL, skipinitialspace=True)
    wishrdr.next()
    with open(wishfile,"wb") as result:
        wishwtr= csv.writer( result, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        wishwtr.writerow((["Count"] + ["Name"] + ["Foil"] + ["Textless"] + ["Promo"] + ["Signed"] + ["Edition"] + ["Condition"] + ["Language"]))
        for r in wishrdr:
            # Check for foil or promo status
            if len(r) > 7:
                if len(r) > 8:
                    if "foil" in r[8]:
                        foilstatus = "foil"
                    else:
                        foilstatus = ""
                    if "promo" in r[8]:
                        promostatus = "promo"
                    else:
                        promostatus = ""
                else:
                    if "foil" in r[7]:
                        foilstatus = "foil"
                    else:
                        foilstatus = ""
                    if "promo" in r[7]:
                        promostatus = "promo"
                    else:
                        promostatus = ""
            else:
                foilstatus = ""
                promostatus = ""
            if "loan to me" in r[5]:
                wishwtr.writerow([r[4].replace("\"","").replace(" ","")] + [r[1].decode("ascii", "ignore").encode("ascii").replace("ther Membrane","Aether Membrane").replace("therize","Aetherize").replace("Death (Death)","Death").replace("Ice (Fire)","Ice")] + [foilstatus] + [r[3].replace("\"","").replace(" ","")] + [promostatus] + [r[3].replace("\"","").replace(" ","")] + [r[2].replace("\"","").replace("2012 Edition","2012")] + ["Near Mint"] + ["English"])
            else:
                try:
                    wishrdr.next()
                except:
                    break
