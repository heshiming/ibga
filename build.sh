#!/bin/bash

docker buildx build --platform linux/arm64,linux/amd64 --rm -f ./dockerfile -t ibga ./
docker images
