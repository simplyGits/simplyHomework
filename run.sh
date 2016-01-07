#!/usr/bin/env bash
set -e

git submodule init
git submodule update --recursive --remote --merge ./
base="MAIL_URL='smtp://lieuwerooijakkers@gmail.com:gV1afFmrhN7IUG7VS-x89w@smtp.mandrillapp.com:587' DISABLE_WEBSOCKETS=true meteor"
meteor remove force-ssl
trap "meteor add force-ssl" EXIT
if [[ -f settings.json ]]; then
	eval "$base --settings settings.json"
else
	eval $base
fi
