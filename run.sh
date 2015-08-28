#!/usr/bin/env bash

git submodule init
git submodule update --recursive ./
if [[ -f settings.json ]]; then
	meteor --settings settings.json
else
	meteor
fi
