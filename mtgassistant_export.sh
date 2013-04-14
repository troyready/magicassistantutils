#!/bin/bash
cd
python ~/xmlutils.py/xml2csv.py --input "`pwd`/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/main.xml" --output `pwd`/magicdeckboxstaging.csv --tag mcp > /dev/null
python ~/magicassistantutils/mtgassistant2deckbox.py
python ~/magicassistantutils/mtgassistant2decklist.py
