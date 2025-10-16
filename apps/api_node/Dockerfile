FROM node:20-alpine AS base

WORKDIR /usr/src/app

COPY ../../package*.json ./
RUN npm install

COPY ../../ ./

WORKDIR /usr/src/app/apps/api_node
RUN npm install

CMD ["npm", "run", "start:dev"]
