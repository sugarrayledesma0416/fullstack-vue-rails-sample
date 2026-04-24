module.exports = {
  test: /\.s[ac]ss$/i,
  use: [
    // Creates `style` nodes from JS strings
    {
      loader: 'style-loader',
    },
    // Translates CSS into CommonJS
    {
      loader: 'css-loader',
      options: {
        sourceMap: true,
      },
    },
    // Compiles Sass to CSS
    {
      loader: 'sass-loader',
      options: {
        sourceMap: true,
        sassOptions: {
          quietDeps: true,
        },
      },
    },
  ]
};
