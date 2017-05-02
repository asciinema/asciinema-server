#!/usr/bin/env bash

export S3_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
export S3_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}

exec java -server -jar /app/target/uberjar/asciinema-0.1.0-SNAPSHOT-standalone.jar
