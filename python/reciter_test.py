#! /usr/bin/env -S python3 -B

"""This is a test tool for the Python re-implementation of the SAM Reciter program."""

import argparse
import re

from reciter import Reciter
from reciter_rewrite_rules_dictionary import read_rewrite_rules_dictionary_from_file


def test_reciter_with_testcase_file(reciter: Reciter, filename: str):
    """Feed testcases from a file into the reciter and report results.

    The file must contain lines of the form:

    {SOURCE_STRING} -> {SAM_PHONEMES_STRING}

    The curly braces should be present as literal characters. They serve to precisely
    indicate the beginning and end of both the SOURCE_STRING and SAM_PHONEMES_STRING,
    both of which may start or end with whitespace characters.

    The SOURCE_STRING will be translated to SAM phonemes by passing it to
    the Reciter. The result will be then compared with the SAM_PHONEMES_STRING.
    """

    # Read the testcases.

    with open(filename, "r", encoding="ascii") as fi:
        testcases = fi.read().splitlines()

    # Process the testcases.

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
        reciter_test_output = reciter.to_phonemes(reciter_input)
        if reciter_test_output == reciter_reference_output:
            success_count +=1
        else:
            failure_count += 1
            print(f"Testcase #{testcase_index}: {reciter_input!r} failed:")
            print()
            print(f"  Reference (SAM Reciter) output ...... : {reciter_reference_output!r}")
            print(f"  Python Reciter output ............... : {reciter_test_output!r}")
            print()

    print(f"Python Reciter tests: success = {success_count}, failure = {failure_count}"
          f" ({success_count/(success_count+failure_count)*100.0:.2f}%).")
    print()


def main():
    """Test the Python Reciter ."""

    # Parse command line arguments.

    default_rules_filename = "reciter_rules_english.txt"

    parser = argparse.ArgumentParser(description="Test the Python re-implementation of the SAM Reciter.")

    parser.add_argument("--rules-filename", default=None,
                        help=f"rewrite rule definition file")
    parser.add_argument("--fix-bugs", action='store_true',
                        help="fix known bugs in the rewrite rule matching")
    parser.add_argument("filename", help=f"testcase filename")

    args = parser.parse_args()

    if args.rules_filename is None:
        # Use the default ruleset.
        rules_dictionary = None
    else:
        rules_dictionary = read_rewrite_rules_dictionary_from_file(args.rules_filename)

    reciter = Reciter(rules_dictionary=rules_dictionary, fix_bugs=args.fix_bugs)

    # Test the Reciter against testcases read from a file.

    test_reciter_with_testcase_file(reciter, args.filename)


if __name__ == "__main__":
    main()
