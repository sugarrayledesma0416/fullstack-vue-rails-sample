import Handlebars from 'handlebars';

// from https://gist.github.com/areichman/3502068
Handlebars.registerHelper('options_for_select', function(items, selectedValue = '') {
  let sortedItems = items.sort((a, b) => {
    if (a[0] > b[0]) {
      return 1;
    }

    if (a[0] < b[0]) {
      return -1;
    }

    return 0;
  });

  let output = sortedItems.map(item => {
    let display = item[0];
    let value = item[1];
    /** I use the equality (==) rather than identity (===) operator here
     *    because the pair of values to be compared could be an integer
     *    and a string.
     */
    let selected = item[1] == selectedValue ? 'selected' : '';
    return `<option ${selected} value="${value}">${display}</option>`;
  }).join('');

  return new Handlebars.SafeString(output);
});
