#!/usr/bin/env sh

trap 'exit 0' SIGTERM
while true
do
  ./delete_files_if_low_memory.sh
  if [ $? -eq 0 ]
  then
    sleep "1m"
  fi
done