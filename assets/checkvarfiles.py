#!/usr/bin/python3
"""
This will get a list and parse it in a terraform command
input: file
output: stdout
uses: #!/usr/bin/env python3
Example input:
[
"filea",
"fileb"
]


Example output:
filea fileb
"""

import sys
import json
import os

with open('varfiles.json', encoding='utf-8') as data_file:
    data = json.loads(data_file.read())

for i in data:
    print(i + " ")
