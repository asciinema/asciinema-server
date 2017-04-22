#!/usr/bin/env bash

export DATABASE_URL=jdbc:${DATABASE_URL}
export S3_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
export S3_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}
export A2PNG_BIN_PATH="/app/a2png/a2png.sh"

exec java -server -jar /app/target/uberjar/asciinema-0.1.0-SNAPSHOT-standalone.jar
