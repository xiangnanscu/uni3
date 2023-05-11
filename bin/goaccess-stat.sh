#!/bin/sh
if [ -z $(find logs -name *.gz) ]; then
  cat logs/*.log | goaccess - --log-format='%h [%d:%t %^] "%r" %s %b "%R" "%u" %T' --date-format=%d/%b/%Y --time-format=%T -o html
else
  ( zcat logs/*.gz; cat logs/*.log ) | goaccess - --log-format='%h [%d:%t %^] "%r" %s %b "%R" "%u" %T' --date-format=%d/%b/%Y --time-format=%T -o html
fi