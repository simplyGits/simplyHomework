#!/usr/bin/env bash

git submodule init
git submodule update --recursive ./
base="MAIL_URL='smtp://lieuwerooijakkers@gmail.com:gV1afFmrhN7IUG7VS-x89w@smtp.mandrillapp.com:587' DISABLE_WEBSOCKETS=true meteor"
if [[ -f settings.json ]]; then
	eval "$base --settings settings.json"
else
	eval $base
fi
