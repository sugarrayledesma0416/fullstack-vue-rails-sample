process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const webpack = require('webpack')
const path = require('path');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  jasmineRequire: 'jasmine-core/lib/jasmine-core/jasmine.js'
}))

environment.config.merge(
  {
    /*
     * Enables source maps used for locating source files from within the
     * browser console.  This should work for both JS and any CSS included in
     * the bundle, e.g. Vue components.
     *
     * @SEE: https://webpack.js.org/configuration/devtool/#devtool
     */
    devtool: 'eval',
    resolve: {
      alias: {
        vue: path.resolve('./node_modules/vue/dist/vue.runtime.esm-browser.js'),
      },
    },
    /* @see: https://v4.webpack.js.org/configuration/stats */
    stats: {
      all: false,
      builtAt: true,
      colors: true,
      errors: true,
      performance: true,
      timings: true,
      warnings: true,
    },
  },
);

module.exports = environment.toWebpackConfig()
