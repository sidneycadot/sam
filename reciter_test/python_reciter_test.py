#! /usr/bin/env -S python3 -B

"""This is a tester for the Python re-implementation of the SAM Reciter program."""

import argparse
import re

from python_reciter import Reciter
from python_reciter_rewrite_rules import read_reciter_rules_into_dictionary


def main():
    """Main test function."""

    # pylint: disable=too-many-locals

    # Parse command line arguments.

    default_testcase_filename = "tests/reciter_features.out"
    default_rules_filename = "english_reciter_rules.txt"

    parser = argparse.ArgumentParser(description="Test the Python re-implementation of the SAM Reciter.")

    parser.add_argument("-f", "--filename", default=default_testcase_filename,
                        help=f"testcase filename (default: {default_testcase_filename})")
    parser.add_argument("--rules-filename", default=default_rules_filename,
                        help=f"rewrite rule definition filename (default: {default_rules_filename})")
    parser.add_argument("--fix-bugs", action='store_true',
                        help="fix known bugs in the rewrite rule matching")

    args = parser.parse_args()

    # Read the rewrite rule file into a rewrite rule dictionary.

    reciter_rules_dictionary = read_reciter_rules_into_dictionary(args.rules_filename)

    # Make a Reciter instance that will use the rewrite rule dictionary we just read.

    reciter = Reciter(reciter_rules_dictionary, fix_bugs=args.fix_bugs)

    # Read the testcases.

    with open(args.filename, "r", encoding="ascii") as fi:
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
        reciter_test_output = reciter(reciter_input)
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


if __name__ == "__main__":
    main()
