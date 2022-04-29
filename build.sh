#!/bin/bash

docker build --progress plain --rm -f ./dockerfile -t ibga ./
docker images
