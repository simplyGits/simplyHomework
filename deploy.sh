#!/usr/bin/env bash
meteor npm install
docker build -t simplyhomework . && docker-compose up -d app
tput bel
