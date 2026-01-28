#!/bin/bash

# Run k6 load tests
docker run --rm -i \
--network tomcat-kafka_network \
-e K6_OUT=json=/results/results.json \
-v "$(pwd)/k6/load-test.js:/load-test.js:ro" \
-v "$(pwd)/k6/results:/results" \
grafana/k6 run /load-test.js