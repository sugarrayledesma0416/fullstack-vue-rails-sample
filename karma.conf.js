// Karma configuration
// Generated on Tue Jun 23 2020 10:06:08 GMT+0000 (Coordinated Universal Time)

const webpackConfig = require('./config/webpack/test.js')

module.exports = function(config) {
  config.set({
    // Setting mode as 'development' overrides the default of 'production'
    // and greatly shortens the time it takes to start the test suite.
    webpack: Object.assign({}, webpackConfig, { mode: 'development' }),

    // avoid walls of useless text
    webpackMiddleware: {
      noInfo: true
    },

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine'],


    // list of files / patterns to load in the browser
    files: [
      'app/javascript/spec/**/*_spec.js'
    ],

    plugins: [
      "karma-jasmine",
      "karma-webpack",
      "karma-chrome-launcher",
      "karma-coverage"
    ],

    // list of files / patterns to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'app/javascript/src/**/*.js': ['webpack'],
      'app/javascript/spec/**/*_spec.js': ['webpack']
    },

    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress', 'coverage'],

    coverageReporter: {
      dir: 'public/js_coverage',
      reporters: [
       { type: 'html', subdir: '.' },
       { type: 'text-summary', subdir: '.', file: 'coverage.txt' }
      ]
    },

    // web server port
    // FIXME: This port is not open in the AWS dev envs;
    //        we will need a workaround if we want to run
    //        specs in the browser.
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['ChromiumHeadlessCustom'],

    customLaunchers: {
      ChromiumHeadlessCustom: {
        base: 'ChromiumHeadless',
        flags: ['--disable-dev-shm-usage',
                '--ignore-certificate-errors',
                '--no-sandbox',
                '--window-size=1920,1280']
      }
    },

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: true,

    // Concurrency level
    // how many browser should be started simultaneous
    concurrency: Infinity
  })
}
