'use strict';

const express = require('express');
const bodyParser = require('body-parser');
const error = require('http-errors');
const config = require('./configure');
const pkg = require('./package.json');

const app = express()

app.use(bodyParser.json());
app.set('view engine', 'hbs');


app.listen(config.port, () => console.log('Ready on :'+config.port));

const api = express.Router();

api.get('/', (req, res, next) => {
    res.json({
        message: 'ok',
        version: pkg.version
    });
});

api.get('/todos', (req, res, next) => {
    next(error.NotImplemented());
});

api.get('/todos/:id', (req, res, next) => {
    next(error.NotImplemented());
});

api.post('/todos', (req, res, next) => {
    next(error.NotImplemented());
});

api.use((req, res, next) => {
    next(error.NotFound());
});


api.use((err, req, res, next) => {
    const message = err.message || 'Internal Server Error';
    const statusCode = err.statusCode || 500;

    if (statusCode >= 500) {
        console.error(err.stack || err);
    }

    res.status(statusCode).json({message: message});
});



const web = express.Router();

web.get('/', (req, res, next) => {
    res.render('index', {title: 'Hello World!'});
});

web.use((req, res, next) => {
    next(error.NotFound());
});

web.use((err, req, res, next) => {
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Unknown error';
    res.status(statusCode).render('error', {statusCode, message});
});


app.use('/api', api);
app.use('/', web);
