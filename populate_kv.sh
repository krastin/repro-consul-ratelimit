#!/usr/bin/env bash

echo Populating Consul KV with some test data: path "rate-test/testX", X ranging from 1 to 500
for i in {1..500}; do
  curl --silent --request PUT --data "test${i}" http://localhost:8502/v1/kv/rate-test/test${i} > /dev/null
done
echo ...done!