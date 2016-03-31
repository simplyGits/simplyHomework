#!/usr/bin/env bash
meteor npm install
docker build -t simplyhomework . && docker-compose up -d app
ssh simplyhomework 'docker rmi $(docker images -q -f dangling=true)' # reclaim some diskspace
tput bel
