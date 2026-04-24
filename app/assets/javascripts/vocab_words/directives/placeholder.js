var VHL = VHL || {};

// This solves IE9 input helper text
// Shiv for placeholder HTML5 attribute.
// Browsers without support will return an empty object
// here, default behvior is not changed.

VHL.VocabWords.Directives.directive('placeholder', function ($timeout) {
  var i = document.createElement('input');
  //check to see if i.placeholder exists
  if ('placeholder' in i) {
    return {};
  }
  return {
    link: function (scope, elm, attrs) {
      //proper behavior should ignore this attr on type=password
      if (attrs.type === 'password') {
        return;
      }
      $timeout(function () {
        elm.val(attrs.placeholder);
        elm.bind('focus', function () {
          if (elm.val() === attrs.placeholder) {
            elm.val('');
          }
        }).bind('blur', function () {
          if (elm.val() === '') {
            elm.val(attrs.placeholder);
          }
        });
      });
    }
  };
});
