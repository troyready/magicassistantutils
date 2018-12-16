"""Tests for collection module."""
import os
import tempfile
import unittest

from magicassistantutils.collection import Collection


def create_test_collection() -> str:
    """Return path to mock Magic Assistant collection file."""
    filehandle, path = tempfile.mkstemp()
    os.close(filehandle)
    with open(path, 'w') as stream:
        stream.write("""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cards>
  <name></name>
  <key>Collections/main</key>
  <comment></comment>
  <type>collection</type>
  <properties>
    <property name="virtual" value="false"/>
  </properties>
  <list>
    <mcp>
      <card>
        <id>152727</id>
        <name>Disperse</name>
        <edition>Morningtide</edition>
      </card>
      <count>2</count>
      <location>Collections/main</location>
      <ownership>true</ownership>
      <date>Sun Jun 08 22:28:22 PDT 2018</date>
    </mcp>
  </list>
</cards>
""")
    return path


class CollectionTester(unittest.TestCase):
    """Test Collection class."""

    def test_save_existing_iam_env_vars(self):
        """Test save_existing_iam_env_vars."""
        filehandle, path = tempfile.mkstemp()
        os.close(filehandle)
        collection = Collection()
        collection.import_mtgassistant_collection(create_test_collection())
        collection.export_to_deckbox_csv(path)
        with open(path, 'r') as stream:
            export: str = stream.read()
        self.assertEqual(
            export,
            ("Count,Tradelist Count,Name,Edition,Card Number,Condition,"
             "Language,Foil,Signed,Artist Proof,Altered Art,Misprint,Promo,"
             "Textless,My Price\n"
             "2,0,Disperse,Morningtide,,Near Mint,English,,,,,,,,0\n")
        )
