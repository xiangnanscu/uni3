#!/bin/bash

while true
do
  git pull
  if [ $? -eq 0 ]
  then
    echo "Git pull succeeded"
    break
  else
    echo "Git pull failed, retrying in 1 seconds"
    sleep 1
  fi
done
