#!/usr/bin/env bash
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" != "master" ]]; then
	>&2 echo "not on 'master' branch"
	exit 1
fi

if [ "npm-shrinkwrap.json" -ot "package.json" ]; then
	read -p "npm-shrinkwrap.json is older than package.json,
it's recommended to test if everything works and run \`meteor npm shrinkwrap\`.
are you sure you want to continue? [y/N] " response
	if ! [[ $response =~ ^(yes|y|Y|Yes)$ ]]; then
		exit 1
	fi
fi
meteor npm install
docker build -t simplyhomework . && docker-compose up -d app
ssh simplyhomework 'docker rmi $(docker images -q -f dangling=true)' # reclaim some diskspace
tput bel
