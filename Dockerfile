FROM node:8.15-jessie

EXPOSE 8000

RUN npm install --global gatsby-cli

RUN mkdir /site

WORKDIR /site
