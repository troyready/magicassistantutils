#!/bin/bash
cd $HOME/magicassistantutils
python xml2csv.py --input "$HOME/Ubuntu One/MagicAssistantWorkspace/magiccards/Collections/main.xml" --output $HOME/magicassistantutils/magicdeckboxstaging.csv --tag mcp > /dev/null
python mtgassistant2deckbox.py
python mtgassistant2decklist.py
cd
