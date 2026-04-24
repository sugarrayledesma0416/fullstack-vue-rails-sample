const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')
const sass = require('./loaders/sass')
const path = require('path')

environment.splitChunks()
const musicPath = path.resolve(__dirname, '..', '..', 'node_modules', 'music');

environment.config.merge({
  module: {
    rules: [
      {
        test: /\.js$/,
        include: /node_modules/, // Limit to `node_modules`
        resolve: {
          modules: ['node_modules'], // Only search in `node_modules`
        }
      },
      {
        test: /\.js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
            plugins: ['@babel/plugin-proposal-optional-chaining']
          }
        },
      },
      {
        test: /\.mjs$/,
        include: /node_modules/,
        type: 'javascript/auto',
      },
      {
        test: /\.svg$/,
        oneOf: [
          {
            resourceQuery: /inline/,
            use: [
              'vue-loader',
              {
                loader: 'vue-svg-loader',
                options: {
                  svgo: {
                    plugins: [{ removeViewBox: false }]
                  }
                }
              }
            ],
          },
          {
            use: {
              loader: 'file-loader',
              options: { name: '[path][name]-[hash].[ext]' },
            },
          },
        ],
      },
    ],
  },
  output: {
    // Makes exports from entry packs available to global scope, e.g.
    // Packs.application.myFunction
    library: ['Packs', '[name]'],
    libraryTarget: 'var'
  },
  resolve: {
    alias: {
      handlebars: 'handlebars/dist/handlebars.min.js',
      Music: path.resolve(musicPath, 'app', 'javascript', 'src'),
      MusicAssets: path.resolve(musicPath, 'app', 'assets'),
      MusicV3: path.resolve(musicPath, 'app', 'javascript', 'src'),
    },
    symlinks: false,
  }
});

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
environment.loaders.prepend('sass', sass)
module.exports = environment
