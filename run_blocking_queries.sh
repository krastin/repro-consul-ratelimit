#!/usr/bin/env bash

echo Firing up 10 requests for blocking queries towards 127.0.0.1:8502
for i in {1..10}; do
  request=$(curl --fail --silent --request GET --header "Accept: application/json" "http://127.0.0.1:8502/v1/kv/rate-test/test${i}")
  if [[ $? != 0 ]]; then
    echo Request \#${i} failed: Server answered with an HTTP response different from 2xx
    continue
  else
    index=$(echo $request | jq '.[].ModifyIndex')
    if [[ index == '' ]]; then
        echo Request \#${i} failed: Empty response
        continue
    fi
    echo Setting a watch on KV rate-test/test${i}, index:$index
    curl --fail --silent "http://127.0.0.1:8502/v1/kv/rate-test/test${i}?index=${index}&wait=1m" &
  fi
done

echo
echo All requests sent, successfull blocking request still running: $(jobs -r | wc -l). Execution paused:
echo Press enter to kill any currently running blocking queries:
read
echo Killing $(jobs -r | wc -l) curl requests
for i in $(jobs -r -p); do kill $i; done
echo done, exiting