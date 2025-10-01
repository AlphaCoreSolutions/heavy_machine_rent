import json
import re

# Load the JSON file
with open('municipios.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Regex for valid ObjectId
objectid_pattern = re.compile(r'^[0-9a-f]{24}$')

invalid_ids = []

for item in data:
    oid = item['_id']['$oid']
    if not objectid_pattern.match(oid):
        invalid_ids.append(oid)

if invalid_ids:
    print("Invalid ObjectIds:")
    for oid in invalid_ids:
        print(oid)
else:
    print("All ObjectIds are valid.")
