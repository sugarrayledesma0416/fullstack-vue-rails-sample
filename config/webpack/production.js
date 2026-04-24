process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const environment = require('./environment')

/**
 * For the QA build, we want to generate source maps for debugging.
 *
 * For the production build, we disable them to shorten compilation
 * time (and to obscure our JS source).
 */
const devtool = process.env.RAILS_ENV === 'qa' ? 'source-map' : false;

/*
 * We can tell the environment loader function which files that live within app/javascript/src
 * the precompiling process needs to ignore. So we specify a test key, which contains a regex
 * that is going to be evaluated against each full filepath. If the regex test passes, it will
 * ignore that particular file and it will exclude it from the precompilation process.
 *
 * In this case, we are telling webpack to ignore all js files that ends with (_spec.js).
 */
environment.loaders.append('ignore', {
  test: /_spec.js$/,
  loader: 'ignore-loader'
});

// Ignore jasmine.js and specs.js files.
environment.loaders.append('ignore', {
  test: /app\/javascript\/packs\/(jasmine|specs).js$/,
  loader: 'ignore-loader'
});

environment.config.merge(
  {
    devtool,
  },
);
module.exports = environment.toWebpackConfig()
