#!/usr/bin/env bash

git submodule init
git submodule update --recursive --remote --merge ./
meteor npm install
base="MAIL_URL='smtp://lieuwerooijakkers@gmail.com:3_oSTg-KlPmYICxcGivZMg@smtp.mandrillapp.com:587' DISABLE_WEBSOCKETS=true meteor"
if [[ -f settings.json ]]; then
	eval "$base --settings settings.json"
else
	eval $base
fi
