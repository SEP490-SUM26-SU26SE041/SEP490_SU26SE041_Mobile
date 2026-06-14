#!/usr/bin/env python3
import re

path = r'd:\SEP490-FE\SEP490_SU26SE041_FE_Mobile\flutter_application_2\lib\features\dashboard\presentation\researcher_dashboard_screen.dart'

with open(path, 'rb') as f:
    content = f.read()

# Find ALL occurrences of \xc2\xa0 (non-breaking space in UTF-8)
idx = 0
count = 0
while True:
    pos = content.find(b'\xc2\xa0', idx)
    if pos < 0:
        break
    ctx = content[max(0,pos-10):pos+15]
    print(f'Found xc2xa0 at pos {pos}: {ctx.hex()} = {ctx.decode("utf-8", errors="replace")}')
    idx = pos + 1
    count += 1
    if count > 10:
        break

print(f'\nTotal: {count} occurrences of non-breaking space')

# Find ALL occurrences of \xad (soft hyphen in various encodings)
idx = 0
count2 = 0
while True:
    pos = content.find(b'\xad', idx)
    if pos < 0:
        break
    ctx = content[max(0,pos-5):pos+10]
    print(f'Found xad at pos {pos}: {ctx.hex()} = {ctx.decode("utf-8", errors="replace")}')
    idx = pos + 1
    count2 += 1
    if count2 > 10:
        break

print(f'\nTotal: {count2} occurrences of soft hyphen')
