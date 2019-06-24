#!/usr/bin/python3
"""
This will get the input and return a key value pair file list.
input: file
output: file
uses: #!/usr/bin/env python3
Example input:
{
  "env": "addtfws",
  "somevar": "somevar"
}


Example output:
TF_VAR_env=dev
"""

import sys
import json
import os

with open('vars.json', encoding='utf-8') as data_file:
    data = json.loads(data_file.read())

for key, value in data.items():
    print("-var " + key + "='" + value + "'")
