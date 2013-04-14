#!/bin/bash
cd
python ~/xmlutils.py/xml2csv.py --input "`pwd`/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/main.xml" --output `pwd`/deckboxstaging.csv --tag mcp
python ~/magicassistantutils/mtgassistant2deckbox.py
