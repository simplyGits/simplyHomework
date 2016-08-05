FROM node:4.4.7
MAINTAINER simplyApps <hello@simplyApps.nl>

ADD . /opt/app

RUN cd /opt/app/programs/server \
  && rm -rf node_modules \
  && npm i --prod

WORKDIR /opt/app

ENV PORT 80
EXPOSE 80

CMD ["node", "main.js"]
