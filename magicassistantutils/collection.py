#!/usr/bin/env python3
"""MTG Collection."""

import csv
import re
from typing import List, Union, cast

from xml.etree.ElementTree import ElementTree

from .card import Card
from .mappings import CollNumberMapping


def translate_deckbox_card_edition(card_name: str,
                                   card_edition: str) -> str:
    """Convert card edition to deckbox compatible name."""
    card_edition = re.sub(r'Magic: The Gathering-Commander',
                          'Commander',
                          card_edition)
    for i in ['2012', '2013']:
        card_edition = re.sub(r"%s Edition" % i, i, card_edition)
    card_edition = re.sub(r'Magic: The Gathering—Conspiracy',
                          'Conspiracy',
                          card_edition)
    card_edition = re.sub(r'Annihilation \(2014\)',
                          'Annihilation',
                          card_edition)
    if card_name == 'Mana Crypt' and card_edition == 'Promo set for Gatherer':
        card_edition = 'Media Inserts'
    return card_edition


def translate_deckbox_card_name(card_name: str) -> str:
    """Convert cardname to deckbox compatible name."""
    card_name = re.sub(r' \(.*', '', card_name)
    card_name = re.sub(r'Æ', 'Ae', card_name)
    card_name = re.sub(r'Lim-Dûl\'s Vault', 'Lim-Dul\'s Vault', card_name)
    return card_name


def get_deckbox_coll_number(card_name: str,
                            card_edition: str,
                            card_id: str,
                            coll_mappings: CollNumberMapping) -> str:
    """Return collector number for deckbox CSV.

    No number is returned for most cards. Exceptions are:
    * Basic lands with a normal (non-hypen-prefix) card id
    * "Extras:" set members (i.e. tokens)
    """
    if card_name in ['Plains', 'Island', 'Swamp', 'Mountain', 'Forest'] and (
            not card_id.startswith('-')):
        return coll_mappings.get_coll_number(card_id)
    elif card_edition.startswith('Extras:'):
        return card_id[-2]
    return ''  # most cards


def create_deckbox_card_line(card: Card,
                             coll_mappings: CollNumberMapping) -> List[Union[str, int]]:
    """Convert card to deckbox list."""
    card_line: List[Union[str, int]] = []
    card_line.append(card.count)
    card_line.append(0)  # todo: add trade count
    card_line.append(translate_deckbox_card_name(card.properties['name']))
    card_line.append(
        translate_deckbox_card_edition(card.properties['name'],
                                       card.properties['edition'])
    )
    card_line.append(get_deckbox_coll_number(card.properties['name'],
                                             card.properties['edition'],
                                             card.properties['id'],
                                             coll_mappings))
    if 'played' in card.special:
        card_line.append('Played')
    else:
        card_line.append('Near Mint')
    card_line.append('English')  # skipping language check
    if 'foil' in card.special:
        card_line.append('foil')
    else:
        card_line.append('')
    card_line.append('')  # skipping signed check
    card_line.append('')  # skipping artist proof check
    card_line.append('')  # skipping altered check
    card_line.append('')  # skipping misprint check
    for i in ['promo', 'textless']:
        if i in card.special:
            card_line.append(i)
        else:
            card_line.append('')
    card_line.append('0')  # hardcoding myprice field
    return card_line


class Collection(object):
    """A card collection."""

    def __init__(self) -> None:
        """Set up Collection."""
        self._imported_collection_paths: List[str] = []
        self.cards: List[Card] = []

    def import_mtgassistant_collection(self, path: str) -> None:
        """Load cards from MTG Assistant XML."""
        if path in self._imported_collection_paths:
            raise ValueError('Collection already imported')
        self._process_mtgassistant_xml(path)
        self._imported_collection_paths.append(path)

    def export_to_deckbox_csv(self, path: str) -> None:
        """Export collection to Deckbox CSV."""
        coll_mappings = CollNumberMapping()
        with open(path, 'w') as csvfile:
            csv_writer = csv.writer(csvfile, delimiter=',',
                                    quoting=csv.QUOTE_MINIMAL,
                                    lineterminator="\n")
            csv_writer.writerow([
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
            ])
            for card in self.cards:
                csv_writer.writerow(create_deckbox_card_line(card,
                                                             coll_mappings))

    def _process_mtgassistant_xml(self, raw_collection_path: str) -> None:
        """Process collection."""
        xml = ElementTree(file=raw_collection_path)
        for mcp in xml.find('list').iterfind('mcp'):  # type: ignore
            self.cards.append(
                Card(
                    properties={cast(str, i.tag): cast(str, i.text)
                                for i in mcp.find('card').getchildren()},  # type: ignore
                    count=int(mcp.find('count').text),  # type: ignore
                    special=(mcp.findall('special')[0].text
                             if mcp.findall('special')
                             else None)
                )
            )
