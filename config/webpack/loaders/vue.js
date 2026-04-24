module.exports = {
  test: /\.vue(\.erb)?$/,
  use: [
    {
      loader: 'vue-loader',
      options: {
        compilerOptions: {
          isCustomElement: (tag) => {
            return (
              tag.startsWith('vhl-') ||
              tag.startsWith('music-') ||
              tag.startsWith('l-') ||
              tag.startsWith('sl-') ||
              tag === 'form-item'
            );
          }
        }
      }
    },
  ],
}
