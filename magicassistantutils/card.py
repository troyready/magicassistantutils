#!/usr/bin/env python3
"""MTG Card."""

from typing import Dict, Optional


class Card(object):  # pylint: disable=too-few-public-methods
    """A MTG card."""

    def __init__(self,
                 properties: Dict[str, str],
                 count: int=0,
                 special: Optional[str]=None) -> None:
        """Set up Card."""
        self.properties = properties
        self.count = count
        if special:  # i.e. tags
            self.special = special.split(' ')
        else:
            self.special = []
