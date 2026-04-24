process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const webpack = require('webpack')

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  jasmineRequire: 'jasmine-core/lib/jasmine-core/jasmine.js'
}))

/**
 * Disable generating source maps.
 */
environment.config.merge(
  {
    devtool: false,
    optimization: {
      minimize: false,
    },
  },
);
module.exports = environment.toWebpackConfig()
