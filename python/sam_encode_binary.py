#! /usr/bin/env python3

import base64

filename = "sam_2000_4650.bin"
with open(filename, "rb") as fi:
    data = fi.read()

encoded_data = base64.b64encode(data).decode('ascii')

print("import base64")
print()
print("SAM_6502_CODE = base64.b64decode(\"\"\"")
offset = 0
while offset < len(encoded_data):
    line_length = 75
    part = encoded_data[offset:offset+line_length]
    if offset + len(part) == len(encoded_data):
        print("    {}\"\"\")".format(part))
    else:
        print("    {}".format(part))

    offset += len(part)
