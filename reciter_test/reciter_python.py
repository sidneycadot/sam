#! /usr/bin/env python3

"""This is a Python re-implementation of the "SAM Reciter" program, which translates English text to phonemes represented in ASCII.
"""

import re
from typing import Optional, NamedTuple

def is_digit_character(c: str) -> bool:
    """Check if the character c is a decimal digit."""
    assert len(c) == 1
    return c in "0123456789"

def is_letter_or_single_quote_character(c: str) -> bool:
    """Check if the character c is either a single quote or an uppercase letter."""
    assert len(c) == 1
    return c in "'ABCDEFGHIJKLMNOPQRSTUVWXYZ"

def is_miscellaneous_symbol_or_digit_character(c: str) -> bool:
    """Check if the character c is a miscellaneous symbol or a digit character."""
    assert len(c) == 1
    return c in "!\"#$%&'*+,-./0123456789:;<=>?@^"

def is_vowel_character(c: str) -> bool:
    """Check if the character c is a vowel."""
    assert len(c) == 1
    return c in "AEIOUY"

def is_consonant_character(c: str) -> bool:
    """Check if the character c is a consonant."""
    assert len(c) == 1
    return c in "BCDFGHJKLMNPQRSTVWXZ"

def is_space_like_character(c: str) -> bool:
    """Check if the character c is 'space-like', meaning it will be treated like a space."""
    assert len(c) == 1
    if ord(c) < 32:
        return True
    return c in " ()[\\]_"


class ReciterRewriteRule(NamedTuple):
    """This class represents a single SAM Reciter rewrite rule.

    SAM Reciter rewrite rules are written in the SAM reciter assembly code as:

        prefix(stem)suffix=replacement

    Rules are represented in the same way in the rule file that we read in Python, with the
    added feature that the rule file allows underscore ('_') characters to represent space placeholder,
    in addition to the default space (' ') characters.

    The rewrite rules are used as follows by the SAM Reciter:

    First, a determination is made if the rule matches. This is a three-step process; if any match step fails,
    the rule is considered a non-match.

    (1) Match the rewrite rule's 'stem' at the current position in the source text.
        This match must be verbatim; characters, including symbols, are matched literally.

    (2) Match the rewrite rule's 'prefix', going left from the current position in the source text.
        The prefix can consists of the letters A-Z, and a number of placeholder symbols, described below.

    (3) Match the rewrite rule's 'suffix', going right from the character following the stem in the source text.
        Note that we're sure that the stem is present in the source text, as it was matched during step (1).
        The suffix can consists of the letters A-Z and a number of placeholder symbols, described below.

    If all three steps indicate a match, the rule is considered to match. In that case, the rewrite rule's
    'replacement' string is emitted into the phoneme buffer for vocalisation.

    Prefix and suffix patterns
    --------------------------

    The 'prefix' and 'suffix' fields can contain a number of so-called placeholder characters that can match
    with certain strings in the source text. These are described below.

    * Placeholder ' ':

      This placeholder matches a small pause in the vocalisation -- a "space".

      Any character that is not a letter A-Z or a single quote matches this.
      Single quotes are assumed to also imply that the character is preceded by a letter, e.g. "haven't" or "brother's",
      so those trailing 't' and 's' characters at the end are not preceded by a space, for example.

    * Placeholder '#':

      This placeholder matches a single vowel, i.e., any of the single letters A, E, I, O, U, or Y.

    * Placeholder '.':

      This placeholder matches a subset of the consonants, specifically, any of the single letters B, D, G, J, L, M, N, R, V, W, or Z.

    * Placeholder '&':

      This placeholder matches and of the single characters C, G, J, S, X, or Z, or any of the two-character combinations "CH", or "SH".

      That is the intention anyway. In SAM Reciter, this works in the case of prefix matching, but the implementation for suffix matching
      of the '&' placeholder is buggy, so in the suffix it actually matches the two-character combinations "HC", or "HS".

      Fortunately, in the standard rule-set of SAM Reciter, the '&' placeholder is never used in rule suffixes. Phew.

    * Placeholder '@':

      This placeholder matches and of the single characters D, J, L, N, R, S, T, or Z, or any of the two-character combinations "TH", "CH", or "SH".

      That is the intention anyway. In SAM Reciter, this works in the case of prefix matching, but the implementation for suffix matching
      of the '@' placeholder is buggy, so in the suffix it actually matches the two-character combinations "HT", "HC", or "HS".

      Fortunately, in the standard rule-set of SAM Reciter, the '@' placeholder is never used in rule suffixes. Phew.

    * Placeholder '^':

      This placeholder matches a single consonant, i.e., any of the single letters B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Z.

    * Placeholder '+':

      This placeholder matches a subset of the vowels, specifically, any of the single letters E, I, Y.

    * Placeholder ':':

      (TBW)

    * Placeholder '%':

      (TBW)

    Note: in Reciter, this placeholder is only implemented for suffixes, not for prefixes.

    """

    prefix: str
    stem: str
    suffix: str
    replacement: str

    def match(self, s: str, s_index: int) -> bool:

        return self._match_stem(s, s_index) and self._match_prefix(s, s_index) and self._match_suffix(s, s_index)

    def _match_stem(self, s: str, s_index: int) -> bool:
        return ReciterRewriteRule._match_exact(s, s_index, self.stem, 0, +1)

    def _match_prefix(self, s: str, s_index: int) -> bool:
        return ReciterRewriteRule._match_pattern(s, s_index - 1, self.prefix, len(self.prefix) - 1, -1)

    def _match_suffix(self, s: str, s_index: int) -> bool:
        return ReciterRewriteRule._match_pattern(s, s_index + len(self.stem), self.suffix, 0, +1)

    @staticmethod
    def _match_exact(s: str, s_index: int, p: str, p_index: int, direction: int) -> bool:
        if not (0 <= p_index < len(p)):
            # No pattern characters left to match.
            return True

        pattern_character = p[p_index]

        if not (0 <= s_index < len(s)):
            return False
        source_character = s[s_index]
        return source_character == pattern_character and ReciterRewriteRule._match_exact(s, s_index + direction, p, p_index + direction, direction)

    @staticmethod
    def _match_pattern(s: str, s_index: int, p: str, p_index: int, direction: int) -> bool:
        if not (0 <= p_index < len(p)):
            # No pattern characters left to match.
            return True

        pattern_character = p[p_index]

        if not is_letter_or_single_quote_character(pattern_character):
            if pattern_character == ' ':
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]
                return not is_letter_or_single_quote_character(source_character) and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)
            elif pattern_character == '#':
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]
                return is_vowel_character(source_character) and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)
            elif pattern_character == '.':
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]
                return source_character in "BDGJLMNRVWZ" and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)
            elif pattern_character == '&':
                # A '&' character in the rule matches any of the letters {C, G, J, S, X, Z} or a two-letter combination {CH, SH}.
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]

                return False
            elif pattern_character == '@':
                return False
            elif pattern_character == '^':
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]
                return is_consonant_character(source_character) and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)
            elif pattern_character == '+':
                if not (0 <= s_index < len(s)):
                    return False
                source_character = s[s_index]
                return source_character in "EIY" and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)
            elif pattern_character == ':':
                return False
            elif pattern_character == '%':
                return False
            else:
                raise RuntimeError()
        else:
            # Try to match a literal source character to the pattern character.
            if not (0 <= s_index < len(s)):
                return False
            source_character = s[s_index]
            return source_character == pattern_character and ReciterRewriteRule._match_pattern(s, s_index + direction, p, p_index + direction, direction)


class Reciter:

    def __init__(self, rules_dictionary: dict[Optional[str], list[ReciterRewriteRule]]):
        self.rules_dictionary = rules_dictionary

    def __call__(self, s: str) -> str:

        # Prepend a space character and map the individual characters to the range 0x00..0x5f.

        source_characters = [' ']
        for character_code in map(ord, s):
            character_code &= 0x7f
            if character_code >= 0x60:
                character_code -= 0x20
            source_characters.append(chr(character_code))

        source = "".join(source_characters)

        # Prepare an initially-empty list of phoneme strings.
        phonemes_list = []

        # Process all source characters.
        source_index = 0
        while source_index < len(source):
            (consume_source_characters, phonemes) = self._find_phoneme_replacement(source, source_index)
            source_index += consume_source_characters
            phonemes_list.append(phonemes)

        return "".join(phonemes_list)

    def _find_phoneme_replacement(self, source: str, source_index: int) -> tuple[int, str]:

        source_character = source[source_index]

        # If the source character is a period that is not followed by a digit, the period denotes an end of a sentence.
        # Handle this by putting emitting a period pseudo-phoneme.
        if source_character == "." and not ((source_index + 1) < len(source) and is_digit_character(source[source_index + 1])):
            return (1, ".")

        if is_miscellaneous_symbol_or_digit_character(source_character):
            rule_list = self.rules_dictionary[None]
        elif is_space_like_character(source_character):
            return (1, " ")
        else:
            rule_list = self.rules_dictionary[source_character]

        if rule_list is None:
            raise RuntimeError()

        # We will now try all rules in the rule list; we accept the first one that succeeds.
        for rule in rule_list:
            if rule.match(source, source_index):
                return (len(rule.stem), rule.replacement)

        # The rules are exhausted without a match. We should never get here.
        raise RuntimeError(f"No rule matched (source = {source!r} source_index = {source_index}).")


def read_reciter_rules_dictionary(filename: str) -> dict[Optional[str], list[ReciterRewriteRule]]:
    """Read a file containing Reciter rewrite rule specifications, and return it as a key-indexed dictionary."""

    with open(filename, "r") as fi:
        data = fi.read()

    key_regexp = re.compile(r"]([A-Z])")
    rule_regexp = re.compile(r"(.*)\((.*)\)(.*)=(.*)")

    # Prepare rules dictionary with all keys but no rules.
    rules_dictionary = {None: []}
    for key in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        rules_dictionary[key] = []

    key = None # Start processing rules with key value: None.

    for line in data.splitlines():

        # Empty lines are ignored.
        if len(line) == 0:
            continue

        # The rules file may optionally contain underscores; they are converted to spaces when reading the pattern.
        line = line.replace("_", " ")

        # Check if it is a "key" line. if yes, switch keys.
        match = key_regexp.fullmatch(line)
        if match is not None:
            key = match.group(1)
            continue

        # Check if it is a "rule" line. if yes, add the rule.
        match = rule_regexp.fullmatch(line)
        if match is not None:
            (prefix, stem, suffix, replacement) = match.groups()
            rule = ReciterRewriteRule(prefix, stem, suffix, replacement)
            rules_dictionary[key].append(rule)
            continue

        # The line is neither a key or a rule.
        raise RuntimeError(f"Badly formatted rules dictionary line: {line!r}")

    return rules_dictionary


def main():

    # Instantiate a Reciter and configure it with the English->Phoneme rules.
    reciter_rules_dictionary = read_reciter_rules_dictionary("english_reciter_rules.txt")
    reciter = Reciter(reciter_rules_dictionary)

    # Read testcases.
    filename = "tests/test_reciter_features.out"
    with open(filename) as fi:
        testcases = fi.read().splitlines()

    print()
    print(f"Testing the Python Reciter with {len(testcases)} testcases:")
    print()

    success = 0
    failure = 0

    testcase_regexp = re.compile("{(.*)} -> {(.*)}")
    for (testcase_index, testcase) in enumerate(testcases, 1):
        match = testcase_regexp.fullmatch(testcase)
        assert match is not None
        reciter_input = match.group(1)
        reciter_reference_output = match.group(2)
        reciter_test_output = reciter(reciter_input)
        if reciter_test_output == reciter_reference_output:
            success +=1
        else:
            failure += 1
            print(f"Testcase #{testcase_index}: {reciter_input!r} failed:")
            print()
            print(f"  Reference output ...... : {reciter_reference_output!r}")
            print(f"  Python output ......... : {reciter_test_output!r}")
            print()

    print(f"Python Reciter class tests: success = {success}, failure = {failure}.")
    print()

if __name__ == "__main__":
    main()
