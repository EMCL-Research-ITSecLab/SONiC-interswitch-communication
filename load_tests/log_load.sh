#!/bin/bash
while true; do
  echo "$(date +"%T") - $(sar 1 1 | awk '/Average:/ {print $5"% system"}')" >> load.log
    sleep 5
done
