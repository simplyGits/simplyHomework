#!/usr/bin/env bash
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "master" ]]; then
	>&2 echo "on 'master' branch"
	exit 1
fi

git submodule init
git submodule update --recursive --remote --merge ./
meteor npm install

# kill all child processes on exit
trap 'trap - SIGTERM && kill 0' SIGINT SIGTERM EXIT

echo "Starting mongod"
mongod --dbpath .meteor/local/db &>/dev/null &

base="MONGO_URL=mongodb://localhost:27017/meteor MAIL_URL='smtp://lieuwerooijakkers@gmail.com:3_oSTg-KlPmYICxcGivZMg@smtp.mandrillapp.com:587' DISABLE_WEBSOCKETS=true meteor $@"
if [[ -f settings.json ]]; then
	eval "$base --settings settings.json"
else
	eval $base
fi
