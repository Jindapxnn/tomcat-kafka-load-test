#!/bin/bash

# Run k6 load tests
docker run --rm -i \
--network tomcat-kafka_network \
--env-file .env.dev \
-v "$(pwd)/k6/load-test.js:/load-test.js" \
-v "$(pwd)/k6/results:/results" \
grafana/k6 run /load-test.js