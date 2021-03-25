#!/bin/bash

while true; do
  COUNT=$(ls test | wc -l)
  if [[ $COUNT < 4 ]]; then
    break
  fi
  echo Waiting for a free runner slot...
  sleep 1
done

