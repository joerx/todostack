FROM node:8.6-alpine

RUN npm -g install yarn nodemon

RUN adduser -HD app
RUN mkdir /src && chown app /src/
WORKDIR /src 

COPY package.json yarn.lock /src/

USER app
RUN yarn install

COPY . /src

EXPOSE 3000

# ENTRYPOINT ["node"]
CMD ["node", "server", "--port", "3000"]
