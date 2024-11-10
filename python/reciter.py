"""This module is a pure Python re-implementation of the "SAM Reciter" which translates English text to SAM-style phonemes.

SAM is the Software Automatic Mouth, a speech synthesizer program from the 8-bit era. It was developed by Mark Barton
and sold by Don't Ask Software starting in 1982.
"""

from typing import Optional

from reciter_rewrite_rule import ReciterRewriteRule, ReciterCharacterClass
from reciter_rewrite_rules_dictionary import get_default_rewrite_rules_dictionary


class Reciter:
    """The Reciter class translates source text (usually English) to SAM-style phonemes in ASCII."""

    # pylint: disable=too-few-public-methods

    def __init__(self, *, rules_dictionary: Optional[dict[Optional[str], list[ReciterRewriteRule]]] = None, fix_bugs: bool = False):

        if rules_dictionary is None:
            rules_dictionary = get_default_rewrite_rules_dictionary()

        self.rules_dictionary = rules_dictionary
        self.fix_bugs = fix_bugs

    def to_phonemes(self, source: str) -> str:
        """Render source text as phonemes."""

        # Prepend a space character and map the individual characters to the range 0x00..0x5f.
        source_characters = [' ']
        for character_code in map(ord, source):
            character_code &= 0x7f
            if character_code >= 0x60:
                character_code -= 0x20
            source_characters.append(chr(character_code))

        source = "".join(source_characters)

        # Prepare an initially-empty list of phoneme strings.
        phonemes_list = []

        # Process all source characters.
        source_offset = 0
        while source_offset < len(source):
            (consume_source_characters, phonemes) = self._find_phoneme_replacement(source, source_offset)
            source_offset += consume_source_characters
            phonemes_list.append(phonemes)

        return "".join(phonemes_list)

    def _find_phoneme_replacement(self, source: str, source_offset: int) -> tuple[int, str]:

        source_character = source[source_offset]

        # If the source character is a period that is not followed by a digit, the period denotes
        # an end of a sentence. Handle this by emitting a period pseudo-phoneme.
        if source_character == "." and \
           not ((source_offset + 1) < len(source) and source[source_offset + 1] in ReciterCharacterClass.digits):
            return (1, ".")

        if source_character in ReciterCharacterClass.miscellaneous_symbols_or_digits:
            rule_list = self.rules_dictionary[None]
        elif source_character in ReciterCharacterClass.space_like_characters:
            return (1, " ")
        else:
            rule_list = self.rules_dictionary[source_character]

        # We will now try all rules in the rule list in order; we accept and apply the first one that succeeds.
        for rule in rule_list:
            if rule.match(source, source_offset, self.fix_bugs):
                # This rule matches; use its replacement string.
                return (len(rule.stem), rule.replacement)

        # The rules were all tried, without a match. If the rules are properly written, this cannot happen,
        # since at least one rule will /always/ match.
        raise RuntimeError(f"No rule matched (source = {source!r} source_offset = {source_offset}).")
