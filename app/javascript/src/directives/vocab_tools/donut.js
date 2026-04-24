const DEFAULT_DIAMETER = 300;

export default {
  mounted(elm) {
    const percentCorrect = elm.getAttribute('percent-correct');
    const val = parseInt(percentCorrect, 10);

    if (typeof radialProgress !== 'undefined') {
      radialProgress(elm)
        .diameter(DEFAULT_DIAMETER)
        .value(val)
        .render();
    }
  },
};
