#!/bin/bash

while true
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
done
