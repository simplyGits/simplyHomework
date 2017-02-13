#!/usr/bin/env bash

# check if we're on the master branch
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" != "master" ]]; then
	>&2 echo "not on 'master' branch"
	exit 1
fi

# check if we've set a docker host
if [[ -z "$DOCKER_HOST" ]]; then
	>&2 echo "DOCKER_HOST env var not set"
	exit 1
fi

# check if npm-shrinkwrap.json is up to date.
if [ "npm-shrinkwrap.json" -ot "package.json" ]; then
	read -p "npm-shrinkwrap.json is older than package.json,
it's recommended to test if everything works and run \`meteor npm shrinkwrap\`.
are you sure you want to continue? [y/N] " response
	if ! [[ $response =~ ^(yes|y|Y|Yes)$ ]]; then
		exit 1
	fi
fi

# check if remote is already up to date.
headcommit=$(git rev-parse HEAD)
remotecommit=$(curl -Ls "https://app.simplyhomework.nl/_commitversion")
if [[ "$headcommit" = "$remotecommit" && "$1" != "force" ]]; then
	>&2 echo "remote up-to-date"
	exit 1
fi

# set version.js
commit=$(git rev-parse HEAD)
buildDate="$(date +%s)000"
echo "export default { commit: '$commit', buildDate: new Date($buildDate) }" > ./imports/version.js

# copy versions to docker-compose file as env var
settings=$(jq -c . settings.json)
sed -i "s/METEOR_SETTINGS[^']\+/METEOR_SETTINGS=$settings/" ./docker-compose.yml

# build simplyHomework
BUILD_DIR=$TMPDIR/simplyHomework-build
rm -rf $BUILD_DIR
meteor build --architecture=os.linux.x86_64 --directory $BUILD_DIR
cp Dockerfile $BUILD_DIR/bundle/

# deploy simplyHomework
docker build -t simplyhomework $BUILD_DIR/bundle/ && docker-compose up -d app
ssh simplyhomework 'docker rmi $(docker images -q -f dangling=true)' # reclaim some diskspace
tput bel
