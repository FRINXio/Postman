/*
Usage: 
   1. before execution the script run --> npm init -y <-- to create package.json with the information of .js script
   2. after package.json is created run --> npm i async newman path <-- to install dependencies
   3. if package json does not contain "start":"node yourscript.js" under the script container put it manually or run command: --><--
   4. run --> node yourscript.js(in this case pc_uniconfig_parallel_tests.js) <-- to start the script 
 */

var path = require('path');
async = require('async'); 
newman = require('newman');
require('csv-parse/lib/es5')

parametersForTestRun = {
	collection: path.join(__dirname, 'pc_uniconfig_unsorted.json'),
	folder:'FRHD-506 Setup', // name or ID of item group in postman collection or folder
	environment: path.join(__dirname, 'xrv6.2.3-cli5.3.4_env.json'), //your env
	reporters: ['cli','junit' ],
	reporter : {junit : { export : './junit_results/FRHD-506 Setup.xml' }}
};
parametersForRequestA = {
	collection: path.join(__dirname, 'pc_uniconfig_unsorted.json'),
	folder:'FRHD-506-parallelA',
	environment: path.join(__dirname, 'xrv6.2.3-cli5.3.4_env.json'), //your env
	reporters: ['cli','junit'],
	reporter : {junit : { export : './junit_results/FRHD-506-parallelA.xml' }}
};
parametersForRequestB = {
	collection: path.join(__dirname, 'pc_uniconfig_unsorted.json'),
	folder:'FRHD-506-parallelB',
	environment: path.join(__dirname, 'xrv6.2.3-cli5.3.4_env.json'), //your env
	reporters: ['cli','junit' ],
	reporter :{junit : { export : './junit_results/FRHD-506-parallelB.xml' }}
};

parallelRequestRunA = function(exception) {
  newman.run(parametersForRequestA, exception);
};
parallelRequestRunB = function(exception) {
  newman.run(parametersForRequestB, exception);
};

newman.run(parametersForTestRun).on('start', function (err, summary) { // on start of run, log to console
}).on('done', function (err, summary) {
// Runs the Postman request collection twice, in parallel.
  async.parallel([
    parallelRequestRunA,
    parallelRequestRunB
  ],
  function(err, results) {
    err && console.error(err);

    results.forEach(function(result) {
      var failures = result.run.failures;
      console.info(failures.length ? `Failures for FRHD-506` + JSON.stringify(failures) :
        `There were no failures in parallel request`);
    });
   console.info(`Test FRHD-506 completed`);
  });
});
