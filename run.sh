#!/usr/bin/env bash
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "master" ]]; then
	>&2 echo "on 'master' branch"
	exit 1
fi

git submodule init
git submodule update --recursive --remote --merge ./
meteor npm install

base="DISABLE_WEBSOCKETS=true meteor $@"
if [[ -f settings.json ]]; then
	eval "$base --settings settings.json"
else
	eval $base
fi
