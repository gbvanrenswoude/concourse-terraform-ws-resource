#!/usr/bin/python3
"""
This will get a list and parse it in a terraform command
input: file
output: stdout
uses: #!/usr/bin/env python3
Example input:
[
"module.somemodule",
"module.someothermodule"
]


Example output:
-target=module.somemodule -target=module.someothermodule
"""

import sys
import json
import os

with open('list.json', encoding='utf-8') as data_file:
    data = json.loads(data_file.read())

for i in data:
    print("-target=" + i + " ")
