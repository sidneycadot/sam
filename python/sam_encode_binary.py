#! /usr/bin/env python3

"""This is a build tool to encode binary file as a string for use in a Python source.

We use it to generate code for the 'sam_6502_code.py' that is part of the "samvoice" package.
"""

import gzip
import base64

def main():
    """Encode the "sam_2000_4650.bin" executable for inclusion as Python source code."""

    filename = "data/sam_2000_4650.bin"
    with open(filename, "rb") as fi:
        data = fi.read()

    compressed_data = gzip.compress(data)
    encoded_data = base64.b64encode(compressed_data).decode('ascii')

    print("import gzip")
    print("import base64")
    print()
    print("SAM_6502_CODE = gzip.decompress(base64.b64decode(\"\"\"")
    offset = 0
    while offset < len(encoded_data):
        line_length = 115
        part = encoded_data[offset:offset+line_length]
        if offset + len(part) == len(encoded_data):
            print(f"    {part}\"\"\"))")
        else:
            print(f"    {part}")

        offset += len(part)


if __name__ == "__main__":
    main()
