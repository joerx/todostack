'use strict';

const express = require('express');
const bodyParser = require('body-parser');
const error = require('http-errors');
const config = require('./configure');
const pkg = require('./package.json');
const db = require('./db');
const uuid = require('uuid/v1');
const {ObjectID} = require('mongodb');

process.on('SIGINT', function() {
    console.log('bye');
    process.exit();
});

const app = express()

app.use(bodyParser.json());
app.set('view engine', 'hbs');

app.listen(config.port, () => console.log('Ready on :'+config.port));

const findAll = async () => {
    const conn = await db();
    const collection = conn.collection('todos');
    const results = await collection.find({}).limit(20).toArray();
    conn.close();
    return results;
}

const api = express.Router();

api.get('/', (req, res, next) => {
    res.json({
        message: 'ok',
        version: pkg.version
    });
});

api.get('/todos', async (req, res, next) => {
    try {
        const results = await findAll();
        res.json(results);
    } catch(err) {
        next(err);
    }
});

api.get('/todos/:id', async (req, res, next) => {
    try {
        const id = req.params.id;
        
        console.log('finding', id);

        const conn = await db();
        const collection = conn.collection('todos');

        const result = await collection.findOne({_id: ObjectID(id)});
        conn.close();
        
        console.log(result);
        res.json(result);

    } catch(err) {
        next(err);
    }
});

api.post('/todos', async (req, res, next) => {
    try {
        const data = req.body;

        console.log('inserting', data);

        const conn = await db();
        const collection = await conn.collection('todos');

        const result = await collection.insert(data);
        conn.close();

        console.log(result);
        res.json(data);

    } catch (err) {
        next(err);
    }
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

web.get('/', async (req, res, next) => {
    try {
        const todos = await findAll();
        res.render('index', {todos});
    } catch(err) {
        next(err);
    }
});

web.use((req, res, next) => {
    next(error.NotFound());
});

web.use((err, req, res, next) => {
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Unknown error';
    res.status(statusCode).render('error', {statusCode, message});
});


app.use('/assets', express.static(__dirname+'/public'));
app.use('/api', api);
app.use('/', web);
