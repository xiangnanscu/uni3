import re
import os
import sys
import datetime

import argparse

import subprocess

def exec(com):
    ex = subprocess.Popen(com, stdout=subprocess.PIPE, shell=True)
    out, err  = ex.communicate()
    status = ex.wait()
    print("cmd in:", com)
    print("cmd out: ", out.decode())
    return out.decode()


# create parser
parser = argparse.ArgumentParser()

# add arguments to the parser
parser.add_argument("message")
# parser.add_argument("name")
parser.add_argument("-b","--build", default=False, help="是否使用vite打包")
parser.add_argument("-m","--migrate", default=False, help="是否执行数据库变化")
parser.add_argument("-g","--github", default=False, help="是否将变化推送到github(origin master)")
parser.add_argument("-p","--production", default=False, help="是否将变化推送到生产服务器(p master)")

# parse the arguments
args = parser.parse_args()

print(args)

if args.build:
    exec(f'''yarn build''')

exec(f'''git add . && git commit -am "{args.message}";''')

if args.production:
    migrate_token = "--push-option=migrate:commit"  if args.migrate else ""
    exec(f"git push p master {migrate_token};")

if args.github:
    exec('''while true
do
  git push origin master
  if [ $? -eq 0 ]
  then
    echo "Git push succeeded"
    break
  else
    echo "Git push failed, retrying in 1 seconds"
    sleep 1
  fi
done''')
