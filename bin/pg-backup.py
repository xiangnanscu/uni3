#!/usr/bin/env python
import re
import os
import sys
import datetime

stamp = datetime.datetime.now().strftime('%Y%m%d%H%M')
app_name = 'postgres'
os.system('su - postgres -c "pg_dumpall -c > ~/%s.%s.sql"' % (app_name,stamp))

TRUNK_NUM = 7
files = sorted([f.strip() for f in os.popen(
    'ls /var/lib/postgresql/%s.*.sql'%app_name).readlines()], reverse=True)

for name in files[TRUNK_NUM:]:
    os.remove(name)
