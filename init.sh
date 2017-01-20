#!/usr/bin/env bash
askQuit() {
	read -p "$1? (y/n) " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		exit 1
	fi
}

askOverwrite() {
	if [[ -s $1 ]]; then
		printf "\033[0;31m" # set fg color to red
		echo
		echo "$1 isn't empty:"
		cat $1
		echo
		printf "\033[0m" # reset fg color
		askQuit "do you want to overwrite $1"
	fi
}

echo 'This utility will help you generate sane simplyHomework configuration files'
echo

read -e -p "Kadira app ID: " -r KADIRA_APP_ID
read -e -p "Kadira app secret: " -r KADIRA_APP_SECRET

read -e -p "Root URL (without slashes, e.g: simplyhomework.nl): " -r ROOT_URL

read -e -p "SMTP mail URL (full with auth and protocol): " -r SMTP_URL

read -e -p "Scholieren client ID: " -r SCHOLIEREN_CLIENT_ID
read -e -p "Scholieren client password: " -r SCHOLIEREN_CLIENT_PW

read -e -p "Onesignal appid: " -r ONESIGNAL_APPID
read -e -p "Onesignal API key: " -r ONESIGNAL_API_KEY

askOverwrite settings.json
cat > settings.json <<EOF
{
	"scholieren": {
		"client_id": "$SCHOLIEREN_CLIENT_ID",
		"client_pw": "$SCHOLIEREN_CLIENT_PW"
	},
	"public": {
		"onesignal": {
			"appId": "$ONESIGNAL_APPID"
		}
	},
	"onesignal": {
		"apiKey": "$ONESIGNAL_API_KEY"
	}
}
EOF

askOverwrite docker-compose.yaml
cat > docker-compose.yaml <<EOF
app:
  image: simplyhomework
  restart: always
  ports:
   - "80"
  links:
   - mongo
  environment:
   - MONGO_URL=mongodb://mongo/simplyhomework
   - MONGO_OPLOG_URL=mongodb://mongo/local
   - 'METEOR_SETTINGS=WILL_BE_FILLED_BY_DEPLOY_SCRIPT'
   - HTTP_FORWARDED_COUNT=1
   - KADIRA_APP_ID=$KADIRA_APP_ID
   - KADIRA_APP_SECRET=$KADIRA_APP_SECRET
   - ROOT_URL=http://app.$ROOT_URL
   - MAIL_URL=$SMTP_URL
   - DISABLE_WEBSOCKETS=true
   - VIRTUAL_HOST=app.$ROOT_URL

web:
  image: homepage
  restart: always
  ports:
   - "80"
  environment:
   - 'VIRTUAL_HOST=*.$ROOT_URL'

mongo:
  image: mongo:latest
  restart: always
  command: mongod --replSet meteor

proxy:
  image: jwilder/nginx-proxy
  restart: always
  environment:
   - DEFAULT_HOST=www.$ROOT_URL
  ports:
   - "80:80"
  volumes:
   - /var/run/docker.sock:/tmp/docker.sock:ro
EOF
