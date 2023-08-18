FROM node:16.20-alpine
WORKDIR /app

COPY --chown=node:node . /app

RUN npm install

USER node

CMD ["npm", "start"]

