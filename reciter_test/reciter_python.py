#! /usr/bin/env python3

"""This is a Python re-implementation of the "SAM Reciter" program, which translates English text to SAM-style phonemes represented in ASCII."""

from __future__ import annotations

import argparse
import re
from typing import Optional, NamedTuple


class ReciterCharacterClass:
    """Character classes used by SAM Reciter during rule matching."""

    SPACE = ' '
    SINGLE_QUOTE = '\''
    BACKSLASH = '\\'

    digits = frozenset({
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    })

    letters_or_single_quote = frozenset({
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        SINGLE_QUOTE
    })

    miscellaneous_symbols_or_digits = frozenset({
        '!', '"', '#', '$', '%', '&', SINGLE_QUOTE, '*', '+', ',', '-', '.', '/',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        ':', ';', '<', '=', '>', '?', '@', '^'
    })

    vowels = frozenset({
        'A', 'E', 'I', 'O', 'U', 'Y'
    })

    consonants = frozenset({
        'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
        'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Z'
    })

    # These are the characters in the range '\x00' to '\x5f' for which the
    # character properties byte in the SAM reciter code is zero.
    space_like_characters = frozenset({
        '\x00', '\x01', '\x02', '\x03', '\x04', '\x05', '\x06', '\x07',
        '\x08', '\x09', '\x0a', '\x0b', '\x0c', '\x0d', '\x0e', '\x0f',
        '\x10', '\x11', '\x12', '\x13', '\x14', '\x15', '\x16', '\x17',
        '\x18', '\x19', '\x1a', '\x1b', '\x1c', '\x1d', '\x1e', '\x1f',
        SPACE, '(', ')', '[', BACKSLASH, ']', '_'
    })

    # Remove convenience constants from the class.
    del SPACE, SINGLE_QUOTE, BACKSLASH


class StringScanner:
    """The anstract base class for the ForwardStringScanner and BackwardStringScanner."""


class ForwardStringScanner(StringScanner):

    direction = +1

    def __init__(self, s: str, offset: int):
        if not (0 <= offset <= len(s)):
            raise RuntimeError()
        self.s = s
        self.offset = offset

    def peek(self, count: int) -> Optional[str]:
        a = self.offset
        b = self.offset + count
        return self.s[a:b] if b <= len(self.s) else None

    def drop(self, count: int) -> ForwardStringScanner:
        b = min(self.offset + count, len(self.s))
        return ForwardStringScanner(self.s, b)


class BackwardStringScanner:

    direction = -1

    def __init__(self, s: str, offset: int):
        if not (0 <= offset <= len(s)):
            raise RuntimeError()
        self.s = s
        self.offset = offset

    def peek(self, count: int) -> Optional[str]:
        a = self.offset - count
        b = self.offset
        return self.s[a:b] if a >= 0 else None

    def drop(self, count: int) -> BackwardStringScanner:
        a = max(self.offset - count, 0)
        return BackwardStringScanner(self.s, a)


def match_exact(pattern_scanner: StringScanner, source_scanner: StringScanner) -> bool:
    """Perform an exact pattern match."""

    while True:

        pattern_character = pattern_scanner.peek(1)
        if pattern_character is None:
            return True

        source_character = source_scanner.peek(1)
        if pattern_character != source_character:
            return False

        pattern_scanner = pattern_scanner.drop(1)
        source_scanner = source_scanner.drop(1)


def match_wildcard_pattern(pattern_scanner: StringScanner, source_scanner: StringScanner) -> bool:
    """Perform a wildcard pattern match according to the pattern language supported by the SAM Reciter.

    The following wildcards are supported:

    * Wildcard ' ':

      This wildcard matches a small pause in the vocalisation -- a "space".

      Any character that is not a letter A-Z or a single quote matches this.
      Single quotes are assumed to also imply that the character is preceded by a letter, e.g. "haven't" or "brother's",
      so those trailing 't' and 's' characters at the end are not preceded by a space, for example.

      The beginning or end of the source text is also considered a match.

    * Wildcard '#':

      This wildcard matches a single vowel, i.e., any of the single letters A, E, I, O, U, or Y.

    * Wildcard '.':

      This wildcard matches a subset of the consonants, specifically, any of the single letters B, D, G, J, L, M, N, R, V, W, or Z.

    * Wildcard  '&':

      This wildcard matches the single characters C, G, J, S, X, or Z, as well as the two-character combinations "CH", or "SH".

      That is the intention anyway. In SAM Reciter, this works in the case of prefix matching, but the implementation for suffix matching
      of the '&' wildcard is buggy, so in the suffix it actually matches the two-character combinations "HC", or "HS".

      Fortunately, in the standard rule-set of SAM Reciter, the '&' wildcard is never used in rule suffixes. Phew.

    * Wildcard '@':

      This wildcard matches the single characters D, J, L, N, R, S, T, or Z, as well as the two-character combinations "TH", "CH", or "SH".

      That is the intention anyway. In SAM Reciter, this works in the case of prefix matching, but the implementation for suffix matching
      of the '@' wildcard is buggy, so in the suffix it actually matches the two-character combinations "HT", "HC", or "HS".

      Fortunately, in the standard rule-set of SAM Reciter, the '@' wildcard is never used in rule suffixes. Phew.

    * Wildcard '^':

      This wildcard matches a single consonant, i.e., any of the single letters B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, or Z.

    * Wildcard '+':

      This wildcard matches a subset of the vowels, specifically, any of the single letters E, I, or Y.

    * Wildcard ':':

      This wildcard matches any number of consonants (including zero).

    * Wildcard '%':

      (TBW)

      Note: in SAM Reciter, this wildcard is only implemented for suffixes, not for prefixes.

    """

    pattern_character = pattern_scanner.peek(1)
    if pattern_character is None:
        # The pattern is fully matched.
        return True

    if pattern_character in ReciterCharacterClass.letters_or_single_quote:
        # Try to match a literal source character to the pattern character.
        source_character = source_scanner.peek(1)
        return (pattern_character == source_character) and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == ' ':
        source_character = source_scanner.peek(1)
        return source_character not in ReciterCharacterClass.letters_or_single_quote and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == '#':
        source_character = source_scanner.peek(1)
        return source_character in ReciterCharacterClass.vowels and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == '.':
        source_character = source_scanner.peek(1)
        return source_character in ('B', 'D', 'G', 'J', 'L', 'M', 'N', 'R', 'V', 'W', 'Z') and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == '&':

        # TODO: we want to replicate what actually happens in the code.
        # This needs a thorough investigation.
        # We only need to look at the "prefix" (backward scanning) cases, as only those are used with the English ruleset.

        # A '&' character matches any of the letters {C, G, J, S, X, Z} or a two-letter combination {CH, SH}.

        source_duplet = source_scanner.peek(2)
        if source_scanner.direction > 0:
            # --- THE SUFFIX (FORWARD SCAN CASE) IS NOT USED WITH THE ENGLISH RULESET ---
            raise RuntimeError("The '&' wildcard is not used in the suffix pattern.")
            if source_duplet in {"CH", "SH"}:
                return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2))
        else:
            # --- THE PREFIX (BACKWARD SCAN CASE) *IS* USED WITH THE ENGLISH RULESET ---
            if source_duplet in {"CH", "SH"}:
            #if source_duplet in {"HC", "HS"}:
                return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2))

        source_character = source_scanner.peek(1)
        if source_character in {'C', 'G', 'J', 'S', 'X', 'Z'} and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1)):
            return True

        return False

    if pattern_character == '@':
        # A '&' character matches any of the letters {D, J, L, N, R, S, T, or Z}, or a two-letter combination {TH, CH, or SH}.

        # TODO: we want to replicate what actually happens in the code.
        # This needs a thorough investigation.
        # We only need to look at the "prefix" (backward scanning) cases, as only those are used with the English ruleset.

        source_duplet = source_scanner.peek(2)
        if source_scanner.direction > 0:
            # --- THE SUFFIX (FORWARD SCAN CASE) IS NOT USED WITH THE ENGLISH RULESET ---
            raise RuntimeError("The '@' wildcard is not used in the suffix pattern.")
            if source_duplet in {"TH", "CH", "SH"}:
                return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2))
        else:
            # --- THE PREFIX (BACKWARD SCAN CASE) *IS* USED WITH THE ENGLISH RULESET ---
            #if source_duplet in {"TH", "CH", "SH"}:
            if source_duplet in {"HT", "HC", "HS"}:
                return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2))

        source_character = source_scanner.peek(1)
        if source_character in {'D', 'J', 'L', 'N', 'R', 'S', 'T', 'Z'} and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1)):
            return True

        return False

    if pattern_character == '^':
        source_character = source_scanner.peek(1)
        return source_character in ReciterCharacterClass.consonants and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == '+':
        # A '+' character matches any of the letters {E, I, Y}.
        source_character = source_scanner.peek(1)
        return source_character in {'E', 'I', 'Y'} and match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1))

    if pattern_character == ':':
        # A '+' character matches any number of consonants.
        source_character = source_scanner.peek(1)
        if source_character in ReciterCharacterClass.consonants:
            return match_wildcard_pattern(pattern_scanner, source_scanner.drop(1))

        return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner)

    if pattern_character == '%':
        peek = source_scanner.peek(4)
        if peek == "EFUL":
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(4))
        peek = source_scanner.peek(3)
        if peek in {"ELY", "ING"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(3))
        peek = source_scanner.peek(2)
        if peek in {"ER", "ES", "ED"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2))

        peek = source_scanner.peek(1)
        if peek == "E":
            peek = source_scanner.peek(2)
            if peek is None:
                return True
            if peek[1] not in ReciterCharacterClass.letters_or_single_quote:
                return True

        return False


    raise RuntimeError(f"Bad wildcard character: {pattern_character!r}")



class ReciterRewriteRule:

    """This class represents a single SAM Reciter rewrite rule.

    SAM Reciter rewrite rules are written in the SAM reciter assembly code as:

        prefix(stem)suffix=replacement

    Rewrite rules are represented in the same way in the rule file that we read in Python, with the
    added feature that the rule file allows underscore ('_') characters to represent a space.

    The rewrite rules are used as follows by the SAM Reciter:

    First, a determination is made if the rule matches. This is a three-step process; if any match step fails,
    the rule is considered a non-match.

    (1) Match the rewrite rule's 'stem' at the current position in the source text.
        This match must be verbatim; characters, including symbols, are matched literally.

    (2) Match the rewrite rule's 'prefix', going left from the current position in the source text.
        The prefix can consists of the letters A-Z and a number of wildcard symbols.

    (3) Match the rewrite rule's 'suffix', going right from the character following the stem in the source text.
        Note that we're sure that the stem is present in the source text, as it was matched during step (1).
        The suffix can consists of the letters A-Z and a number of wildcard symbols.

    If all three steps indicate a match, the rule is considered to match. In that case, the rewrite rule's
    'replacement' string is emitted into the phoneme buffer for subsequent vocalisation.
    """

    def __init__(self, prefix: str, stem: str, suffix: str, replacement: str):
        self.prefix = prefix
        self.stem = stem
        self.suffix = suffix
        self.replacement = replacement

    def __repr__(self) -> str:
        return f"ReciterRewriteRule(prefix={self.prefix!r}, stem={self.stem!r}, suffix={self.suffix!r}, replacement={self.replacement!r})"

    def match(self, source: str, source_offset: int) -> bool:
        """Determine if the rule matches at a certain offset in the source file."""
        return self._match_stem(source, source_offset) and self._match_prefix(source, source_offset) and self._match_suffix(source, source_offset)

    def _match_stem(self, source: str, source_offset: int) -> bool:
        #print("_match_stem")
        pattern_scanner = ForwardStringScanner(self.stem, 0)
        source_scanner = ForwardStringScanner(source, source_offset)
        return match_exact(pattern_scanner, source_scanner)

    def _match_prefix(self, source: str, source_offset: int) -> bool:
        #print("_match_prefix")
        pattern_scanner = BackwardStringScanner(self.prefix, len(self.prefix))
        source_scanner = BackwardStringScanner(source, source_offset)
        return match_wildcard_pattern(pattern_scanner, source_scanner)

    def _match_suffix(self, source: str, source_offset: int) -> bool:
        #print("_match_suffix")
        pattern_scanner = ForwardStringScanner(self.suffix, 0)
        source_scanner = ForwardStringScanner(source, source_offset + len(self.stem))
        return match_wildcard_pattern(pattern_scanner, source_scanner)


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
        if source_character == "." and not ((source_index + 1) < len(source) and source[source_index + 1] in ReciterCharacterClass.digits):
            return (1, ".")

        if source_character in ReciterCharacterClass.miscellaneous_symbols_or_digits:
            rule_list = self.rules_dictionary[None]
        elif source_character in ReciterCharacterClass.space_like_characters:
            return (1, " ")
        else:
            rule_list = self.rules_dictionary[source_character]

        # We will now try all rules in the rule list; we accept the first one that succeeds.
        for rule in rule_list:
            if rule.match(source, source_index):
                return (len(rule.stem), rule.replacement)

        # The rules were all tried, without a match. If the rules are well-written, this cannot happen.
        raise RuntimeError(f"No rule matched (source = {source!r} source_index = {source_index}).")


def read_reciter_rules_into_dictionary(filename: str) -> dict[Optional[str], list[ReciterRewriteRule]]:
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

    default_filename = "tests/test_reciter_features.out"
    #default_filename = "tests/test_wordlist_short.out"
    #default_filename = "tests/test_wordlist_long.out"

    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--filename", default=default_filename)

    args = parser.parse_args()

    # Instantiate a Reciter and configure it with the English->Phoneme rules.
    reciter_rules_dictionary = read_reciter_rules_into_dictionary("english_reciter_rules.txt")
    reciter = Reciter(reciter_rules_dictionary)

    # Read testcases.
    with open(args.filename) as fi:
        testcases = fi.read().splitlines()

    print()
    print(f"Testing the Python Reciter with {len(testcases)} testcases:")
    print()

    success_count = 0
    failure_count = 0

    testcase_regexp = re.compile("{(.*)} -> {(.*)}")
    for (testcase_index, testcase) in enumerate(testcases, 1):
        match = testcase_regexp.fullmatch(testcase)
        if match is None:
            raise RuntimeError(f"Bad testcase: {testcase!r}.")
        reciter_input = match.group(1)
        reciter_reference_output = match.group(2)
        reciter_test_output = reciter(reciter_input)
        if reciter_test_output == reciter_reference_output:
            success_count +=1
        else:
            failure_count += 1
            print(f"Testcase #{testcase_index}: {reciter_input!r} failed:")
            print()
            print(f"  Reference output ...... : {reciter_reference_output!r}")
            print(f"  Python output ......... : {reciter_test_output!r}")
            print()

    print(f"Python Reciter tests: success = {success_count}, failure = {failure_count} ({success_count/(success_count+failure_count)*100.0:.2f}%).")
    print()


if __name__ == "__main__":
    main()
