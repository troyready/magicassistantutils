#!/usr/bin/python

import csv
from time import strftime

#from Tkinter import Tk
#from tkFileDialog import askopenfilename

#Tk().withdraw() # we don't want a full GUI, so keep the root window from appearing
#filename = askopenfilename() # show an "Open" dialog box and return the path to the selected file

from os.path import expanduser
home = expanduser("~")

stagingfile = home + "/magicassistantutils/magicdeckboxstaging.csv"
invfile = home + "/Ubuntu One/magiccollection.dec"
wishfile = home + "/Ubuntu One/magicwishlist.dec"

with open(stagingfile,"rb") as source:
#with open(filename,"rb") as source:
    rdr= csv.reader( source, delimiter=',', quotechar="\"", quoting=csv.QUOTE_ALL, skipinitialspace=True)
    rdr.next()
    with open(invfile,"wb") as result:
        result.write('// Generated on ' + strftime("%Y-%m-%d %H:%M:%S") + '\n')
        for r in rdr:
            if "loan to me" not in r[5]:
                result.write(' ' + r[4] + ' ' + r[1].decode("ascii", "ignore").encode("ascii").replace("ther Membrane","Aether Membrane").replace("therize","Aetherize").replace("Death (Death)","Death").replace("Ice (Fire)","Ice") + '\n')
            else:
                rdr.next()

