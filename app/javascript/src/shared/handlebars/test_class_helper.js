import Handlebars from 'handlebars';

Handlebars.registerHelper('test_class', function(env, className, id) {
  let output = '';

  if (env === 'test') {
    output = `test-${ className }-${ id }`;
  }

  return new Handlebars.SafeString(output);
});
