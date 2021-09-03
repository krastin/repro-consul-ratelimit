# repro-consul-ratelimit
A repository for a reproduction of the effects on hitting Consul's rate-limiting

# Purpose

This is a small lab running on Docker with two Consul nodes - one server running in Development mode, and one client. The default connection limits of 200 have been lowered to 5, so that we can overload the Consul client/server communication and observe the effects.

# How to use

## Prerequisites

You will need to following tools - `curl`, `jq`, and `docker-compose` (a part of Docker)

## Setting up lab

Have Docker running. Then have Docker run the Consul client and server yaml with

    docker-compose -f consul.yml up

If everything goes smooth, you will have the Consul server accessible on `localhost:8501` and the Consul client on `localhost:8502` as defined in the yaml file.

The current Consul servers have been preset with only 5 http connections possible. This can be further changed in the yaml file, in the `CONSUL_LOCAL_CONFIG` parameter, under the section `limits`.

## Populating sample data

Execute the `populate_kv.sh` script. It will create the following KV structure in the Consul KV database:

    rate-test/
    rate-test/test1
    rate-test/test2
    [...]
    rate-test/test500

## Hitting the limits

Execute the `run_blocking_queries.sh` script, which by default will 
You should see a few queries already failing since we are firing off 10 queries by default, and the aforementioned limit was configured by 5. Moreover, there are backend queries ran by the Consul client towards the Consul server which are also counted towards the total.

Sample run:

    $ bash run_blocking_queries.sh 
    Firing up 10 requests for blocking queries towards 127.0.0.1:8502
    Setting a watch on KV rate-test/test1, index:19
    Request #2 failed: Server answered with an HTTP response different from 2xx
    Request #3 failed: Server answered with an HTTP response different from 2xx
    Request #4 failed: Server answered with an HTTP response different from 2xx
    Setting a watch on KV rate-test/test5, index:24
    Request #6 failed: Server answered with an HTTP response different from 2xx
    Setting a watch on KV rate-test/test7, index:21
    Request #8 failed: Server answered with an HTTP response different from 2xx
    Request #9 failed: Server answered with an HTTP response different from 2xx
    Request #10 failed: Server answered with an HTTP response different from 2xx

    Requests sent. Execution paused:
    Press enter to kill any currently running blocking queries:
    [ENTER]
    Killing 3 curl requests
    done, exiting

    $

While the open blocking connections are still running in the first minute (default time 1minute as the `wait=1m` parameter in the curl call in the script), you can further run more manual requests yourself and observe the behaviour of the Consul client:

    $ curl -vvvv --fail --silent --request GET --header "Accept: application/json" "http://127.0.0.1:8502/v1/kv/rate-test/test4"
    *   Trying 127.0.0.1...
    * TCP_NODELAY set
    * Connected to 127.0.0.1 (127.0.0.1) port 8502 (#0)
    > GET /v1/kv/rate-test/test4 HTTP/1.1
    > Host: 127.0.0.1:8502
    > User-Agent: curl/7.54.0
    > Accept: application/json
    > 
    * Empty reply from server
    * Connection #0 to host 127.0.0.1 left intact
    $ 

In this case, we observe that the server gave an empty response. Once a minute passes and the blocking queries are terminated, the request works again:

    $ curl -vvvv --fail --silent --request GET --header "Accept: application/json" "http://127.0.0.1:8502/v1/kv/rate-test/test4"
    *   Trying 127.0.0.1...
    * TCP_NODELAY set
    * Connected to 127.0.0.1 (127.0.0.1) port 8502 (#0)
    > GET /v1/kv/rate-test/test4 HTTP/1.1
    > Host: 127.0.0.1:8502
    > User-Agent: curl/7.54.0
    > Accept: application/json
    > 
    < HTTP/1.1 200 OK
    < Content-Type: application/json
    < Vary: Accept-Encoding
    < X-Consul-Index: 564
    < X-Consul-Knownleader: true
    < X-Consul-Lastcontact: 0
    < Date: Fri, 03 Sep 2021 13:00:29 GMT
    < Content-Length: 178
    < 
    [
        {
            "LockIndex": 0,
            "Key": "rate-test/test4",
            "Flags": 0,
            "Value": "dGVzdDQ=",
            "CreateIndex": 564,
            "ModifyIndex": 564
        }
    ]
    * Connection #0 to host 127.0.0.1 left intact

# Cleaning up

Issue a `docker-compose -f consul.yml rm --stop --force` within the project directory.