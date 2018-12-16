#!/usr/bin/env python3
"""MTG Card Mappings."""

from typing import Dict, Optional, cast

import os

import mtgsdk
import yaml


class CollNumberMapping(object):
    """Mapping of Multiverse Ids to Collector numbers."""

    def __init__(self, path: Optional[str]=None) -> None:
        """Set up CollNumberMapping."""
        if path is None:
            path = os.path.join(
                os.path.dirname(os.path.abspath(__file__)),
                'mapping_files',
                'collector_number_mapping.yml'
            )
        self.mapping_path: str = path
        with open(path, 'r') as stream:
            self._mappings: Dict[str, str] = yaml.safe_load(stream)
        if self._mappings is None:
            self._mappings = {}

    def get_coll_number(self, card_id: str) -> str:
        """Return collector number for given card multiverse id."""
        if not self._mappings.get(card_id):
            self._mappings[card_id] = cast(str,
                                           mtgsdk.Card.find(card_id).number)
            with open(self.mapping_path, 'w') as outfile:
                yaml.dump(self._mappings, outfile, default_flow_style=False)
        return self._mappings[card_id]
