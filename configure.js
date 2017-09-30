'use strict';

const argv = require('yargs')
    .option('port', {alias: 'p', describe: 'Port to listen on', default: 3000})
    .argv;


const config = module.exports = {
    port: argv.port
}
