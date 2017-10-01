'use strict';

const {MongoClient} = require('mongodb');
const config = require('./configure');

const connect = module.exports = () => {
    return MongoClient.connect(config.mongoUrl, {poolSize: 10});
}
