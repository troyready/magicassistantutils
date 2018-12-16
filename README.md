# magicassistantutils

Helper utilities to parse a Magic Assistant collection and export DeckBox.org and Apprentice format files.

Python 3+ is required.

## Export to Deckbox.org

1. Install magicassistantutils in your project: `pipenv install --three git+https://github.com/troyready/magicassistantutils.git#egg=magicassistantutils`
2. Create your export script:
```
#!/usr/bin/env python3

import os
import magicassistantutils.collection


def main():
    """Generate deckbox inventory."""
    collection = magicassistantutils.collection.Collection()
    collection.import_mtgassistant_collection(
        os.path.expanduser('~/myrepo/MagicAssistantWorkspace/magiccards/Collections/main.xml')
    )
    collection.export_to_deckbox_csv(
        os.path.expanduser('~/myrepo/Magic Assistant Exports/main.csv')
    )


if __name__ == "__main__":
    main()
```
3. Run the script: `pipenv run python exportscriptname.py`
