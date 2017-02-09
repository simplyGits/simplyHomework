FROM node:4.7.3
MAINTAINER simplyApps <hello@simplyApps.nl>

ADD . /opt/app

RUN cd /opt/app/programs/server \
    && rm -rf node_modules \
    && npm i --prod --unsafe-perm -q

WORKDIR /opt/app

ENV PORT 80
EXPOSE 80

CMD ["node", "main.js"]
