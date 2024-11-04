"""This module provides the ReciterRewriteRule class, including matching functionality."""

from __future__ import annotations

import re
from typing import Optional


class ReciterCharacterClass:
    """Character classes used by SAM Reciter during rule matching."""

    # pylint: disable=too-few-public-methods

    SPACE = ' '
    SINGLE_QUOTE = '\''
    BACKSLASH = '\\'

    # Decimal digits.
    digits = frozenset({
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    })

    # Letters A-Z and the single quote are the "word characters". The single quote is considered a word character
    # because for the purpose of pronunciation, it is often best to consider it as a continuation character for a
    # word, e.g. "brother's", "isn't", or "hasn't".
    word_characters = frozenset({
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
    """The abstract base class for the ForwardStringScanner and BackwardStringScanner."""

    def peek(self, count: int) -> Optional[str]:
        """Take a peek at the next 'count' characters in the string."""
        raise NotImplementedError()

    def drop(self, count: int) -> StringScanner:
        """Return a scanner to the same string, with 'count' characters discarded."""
        raise NotImplementedError()


class ForwardStringScanner(StringScanner):
    """A string scanner that scans a string from left to right."""

    def __init__(self, s: str, offset: int):
        if not (0 <= offset <= len(s)):  # pylint: disable=superfluous-parens
            raise ValueError("Bad offset value.")
        self.s = s
        self.offset = offset

    def peek(self, count: int) -> Optional[str]:
        """Take a peek at the next 'count' characters in the string."""
        a = self.offset
        b = self.offset + count
        return self.s[a:b] if b <= len(self.s) else None

    def drop(self, count: int) -> ForwardStringScanner:
        """Return a scanner to the same string, with 'count' characters discarded."""
        b = min(self.offset + count, len(self.s))
        return ForwardStringScanner(self.s, b)


class BackwardStringScanner(StringScanner):
    """A string scanner that scans a string from right to left."""

    def __init__(self, s: str, offset: int):
        if not (0 <= offset <= len(s)):  # pylint: disable=superfluous-parens
            raise ValueError("Bad offset value.")
        self.s = s
        self.offset = offset

    def peek(self, count: int) -> Optional[str]:
        """Take a peek at the next 'count' characters in the string.

        Note that, even though we scan the string from right to left, the peek sub-string 
        has the same character order as the source string. This is very much intentional;
        we want to be able to see phonetically meaningful sub-strings like "SH" and "CH".
        """
        a = self.offset - count
        b = self.offset
        return self.s[a:b] if a >= 0 else None

    def drop(self, count: int) -> BackwardStringScanner:
        """Return a scanner to the same string, with 'count' characters discarded."""
        a = max(self.offset - count, 0)
        return BackwardStringScanner(self.s, a)


def match_exact(pattern_scanner: StringScanner, source_scanner: StringScanner) -> bool:
    """Perform an exact pattern match."""

    pattern_character = pattern_scanner.peek(1)
    if pattern_character is None:
        return True

    source_character = source_scanner.peek(1)
    if pattern_character != source_character:
        return False

    return match_exact(pattern_scanner.drop(1), source_scanner.drop(1))


def match_wildcard_pattern(pattern_scanner: StringScanner, source_scanner: StringScanner, fix_bugs: bool) -> bool:
    """Perform a wildcard pattern match according to the pattern language supported by the SAM Reciter.

    The pattern_scanner yields characters that are matched against the source_scanner. The following characters
    are supported in the pattern:

    * Letter (A-Z) or single quote:

      These characters are matched literally against themselves in the source string.

      Single quotes are assumed to be part of words, as in, for example, "haven't" or "brother's".

    * Wildcard ' ':

      This wildcard matches a small pause in the vocalization --- a "space".
      Any source character that is not a letter (A-Z) or a single quote matches this.
      The beginning or end of the source string is also considered a match.

    * Wildcard '#':

      This wildcard matches a single vowel, i.e., any of the single letters A, E, I, O, U, or Y.

    * Wildcard '.':

      This wildcard matches a subset of the consonants, specifically,
        any of the single letters B, D, G, J, L, M, N, R, V, W, or Z.

    * Wildcard '&':

      This wildcard intends to match the single characters C, G, J, S, X, or Z, as well as
        the two-character combinations "CH", or "SH".

      However, SAM Reciter has a bug in its matching code for this wildcard:

      * In the SUFFIX implementation, it actually matches the reversed two-character combinations
        "HC", or "HS" instead of "CH and "SH".

      Fortunately, there are no rules that use the '&' wildcard in the suffix pattern,
      so this bug is never triggered.

    * Wildcard '@':

      This wildcard intends to match the single characters D, J, L, N, R, S, T, or Z, as well as the
      two-character combinations "TH", "CH", or "SH".

      However, SAM Reciter has two bugs in its matching code for this wildcard:

      * In both the PREFIX and the SUFFIX matching code, the examination of the character after the
        'H' is done on the same character, and the two-letter matches cannot occur for that reason.
      * In the SUFFIX version, the attempted code would match "HT", "HC", and "HS" if it weren't
        for the previous bug. However, there are no rules that use the '&' wildcard in the suffix
        pattern, so this bug is never triggered.

      The net result is that only the single-character matches actually work.

      Some 0.1% of words are affected by this bug.
      Some examples of affected words: brochure, chew, enthusiasm, parachute.

    * Wildcard '^':

      This wildcard matches a single consonant, i.e., any of the single letters B, C, D, F, G, H,
        J, K, L, M, N, P, Q, R, S, T, V, W, X, or Z.

    * Wildcard '+':

      This wildcard matches a subset of the vowels, specifically, any of the single
        letters E, I, or Y.

    * Wildcard ':':

      This wildcard matches any number of consonants (including zero, i.e. no consonants at all).

    * Wildcard '%':

      This wildcard matches:

      - The literal strings ER, ES, ED, ELY, ING, EFUL;
      - A single 'E' at the end of the string, or before a non-word-character.

      This wildcard is implemented for suffixes only in the original SAM Reciter, and the original
        ruleset only uses it in suffix patterns.
    """

    # pylint: disable=too-many-return-statements, too-many-branches

    pattern_character = pattern_scanner.peek(1)
    if pattern_character is None:
        # The pattern is fully matched.
        return True

    if pattern_character in ReciterCharacterClass.word_characters:
        # Try to match a literal source character to the pattern character.
        source_character = source_scanner.peek(1)
        return (pattern_character == source_character) and \
          match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == ' ':
        source_character = source_scanner.peek(1)
        return source_character not in ReciterCharacterClass.word_characters and \
            match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == '#':
        source_character = source_scanner.peek(1)
        return source_character in ReciterCharacterClass.vowels and \
            match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == '.':
        source_character = source_scanner.peek(1)
        return source_character in ('B', 'D', 'G', 'J', 'L', 'M', 'N', 'R', 'V', 'W', 'Z') and \
            match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == '&':

        # We only need to look at the "prefix" (backward scanning) cases, as only those are used
        # with the English ruleset.
        #
        # A '&' character matches any of the letters {C, G, J, S, X, Z} or a two-letter
        # combination {CH, SH}.
        #
        # Order matters here. We should really try to match the two-letter combinations first, but
        # we follow here what the assembly does.

        # Check for one-letter matches.
        if source_scanner.peek(1) in {'C', 'G', 'J', 'S', 'X', 'Z'}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

        # Check for two-letter matches.
        if source_scanner.peek(2) in {"CH", "SH"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2), fix_bugs)

        return False

    if pattern_character == '@':
        # A '&' character matches any of the letters {D, J, L, N, R, S, T, or Z}, or a two-letter
        # combination {TH, CH, or SH}.
        #
        # Order matters here. We should really try to match the two-letter combinations first,
        # but we follow here what the assembly does (or tries to do).

        # Check for one-letter matches.
        if source_scanner.peek(1) in {'D', 'J', 'L', 'N', 'R', 'S', 'T', 'Z'}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

        if not fix_bugs:
            # Replicate bug in assembly code implementation of MATCH_PREFIX_WILDCARD_AT_SIGN.
            return False

        # Intended functionality: check for two-letter matches.
        if source_scanner.peek(2) in {"TH", "CH", "SH"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2), fix_bugs)

        return False

    if pattern_character == '^':
        source_character = source_scanner.peek(1)
        return source_character in ReciterCharacterClass.consonants and \
            match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == '+':
        # A '+' character matches any of the letters {E, I, Y}.
        source_character = source_scanner.peek(1)
        return source_character in {'E', 'I', 'Y'} and \
            match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(1), fix_bugs)

    if pattern_character == ':':
        # A '+' character matches any number of consonants.
        source_character = source_scanner.peek(1)
        if source_character in ReciterCharacterClass.consonants:
            return match_wildcard_pattern(pattern_scanner, source_scanner.drop(1), fix_bugs)

        return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner, fix_bugs)

    if pattern_character == '%':

        peek = source_scanner.peek(4)
        if peek == "EFUL":
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(4), fix_bugs)
        peek = source_scanner.peek(3)
        if peek in {"ELY", "ING"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(3), fix_bugs)
        peek = source_scanner.peek(2)
        if peek in {"ER", "ES", "ED"}:
            return match_wildcard_pattern(pattern_scanner.drop(1), source_scanner.drop(2), fix_bugs)

        peek = source_scanner.peek(1)
        if peek == "E":
            peek = source_scanner.peek(2)
            if peek is None:
                return True
            if peek[1] not in ReciterCharacterClass.word_characters:
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

    First, a determination is made if the rule matches. This is a three-step process; if any match
    step fails, the rule is considered a non-match.

    (1) Match the rewrite rule's 'stem' at the current position in the source text.
        This match must be verbatim; characters, including symbols, are matched literally.

    (2) Match the rewrite rule's 'prefix', going left from the current position in the source text.
        The prefix can consists of the letters A-Z and a number of wildcard symbols.

    (3) Match the rewrite rule's 'suffix', going right from the character following the stem in the
        source text. Note that we're sure that the stem is present in the source text, as it was
        matched during step (1). The suffix can consists of the letters A-Z and a number of
        wildcard symbols.

    If all three steps indicate a match, the rule is considered to match. In that case, the rewrite
    rule's 'replacement' string is emitted into the phoneme buffer for subsequent vocalization.
    """

    def __init__(self, prefix: str, stem: str, suffix: str, replacement: str):
        self.prefix = prefix
        self.stem = stem
        self.suffix = suffix
        self.replacement = replacement

    def __repr__(self) -> str:
        return f"ReciterRewriteRule(prefix={self.prefix!r}, stem={self.stem!r}, suffix={self.suffix!r}, replacement={self.replacement!r})"

    def match(self, source: str, source_offset: int, fix_bugs: bool) -> bool:
        """Determine if the rule matches at a certain offset in the source file."""
        return self._match_stem(source, source_offset) and \
            self._match_prefix(source, source_offset, fix_bugs) and \
            self._match_suffix(source, source_offset, fix_bugs)

    def _match_stem(self, source: str, source_offset: int) -> bool:
        pattern_scanner = ForwardStringScanner(self.stem, 0)
        source_scanner = ForwardStringScanner(source, source_offset)
        return match_exact(pattern_scanner, source_scanner)

    def _match_prefix(self, source: str, source_offset: int, fix_bugs: bool) -> bool:
        pattern_scanner = BackwardStringScanner(self.prefix, len(self.prefix))
        source_scanner = BackwardStringScanner(source, source_offset)
        return match_wildcard_pattern(pattern_scanner, source_scanner, fix_bugs)

    def _match_suffix(self, source: str, source_offset: int, fix_bugs: bool) -> bool:
        pattern_scanner = ForwardStringScanner(self.suffix, 0)
        source_scanner = ForwardStringScanner(source, source_offset + len(self.stem))
        return match_wildcard_pattern(pattern_scanner, source_scanner, fix_bugs)


def read_reciter_rules_into_dictionary(filename: str) -> dict[Optional[str], list[ReciterRewriteRule]]:
    """Utility class to read a file containing SAM Reciter rewrite rules and return them as a key-indexed dictionary."""

    # Prepare empty rules dictionary with all keys (None and A..Z), but no rules.
    rules_dictionary = {None: []}
    for key in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        rules_dictionary[key] = []

    key = None  # Start processing rules with key value: None.

    # A "key" entry is a right-angle-bracket character (']') followed by a capital letter A..Z.
    key_regexp = re.compile(r"]([A-Z])")

    # A "rule" entry is a line of the form: "prefix(stem)suffix=replacement".
    rule_regexp = re.compile(r"(.*)\((.*)\)(.*)=(.*)")

    # Read the entire file.
    with open(filename, "r", encoding="ascii") as fi:
        data = fi.read()

    # Process all lines in the file. They are either 'key' lines or 'rule' lines.
    for line in data.splitlines():

        # Empty lines are ignored.
        if len(line) == 0:
            continue

        # The rules file may optionally contain underscores; they are converted to spaces.
        line = line.replace("_", " ")

        # Check if it is a "key" line. if yes, switch to the specified key.
        match = key_regexp.fullmatch(line)
        if match is not None:
            key = match.group(1)
            continue

        # Check if it is a "rule" line. if yes, add the rule using the currently active key.
        match = rule_regexp.fullmatch(line)
        if match is not None:
            (prefix, stem, suffix, replacement) = match.groups()
            rule = ReciterRewriteRule(prefix, stem, suffix, replacement)
            rules_dictionary[key].append(rule)
            continue

        # The line is neither a key or a rule. This is a fatal error.
        raise RuntimeError(f"Badly formatted rules dictionary line: {line!r}")

    return rules_dictionary
