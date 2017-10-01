'use strict';

const argv = require('yargs')
    .option('port', {
        alias: 'p', 
        describe: 'Port to listen on', 
        default: 3000})
    .option('mongo', {
        describe: 'MongoDB instance to connect to', 
        demandOption: true, 
        requiresArg: true
    })
    .argv;

const config = module.exports = {
    port: argv['port'],
    mongoUrl: argv['mongo']
}
