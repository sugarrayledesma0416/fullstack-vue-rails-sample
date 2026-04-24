var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vtAccentBlur', function () {
  return {
    require: 'ngModel',
    link: function (scope, elm, attr, ngModelCtrl) {
      var initial_value;
      elm.bind('focus', function () {
        if ($('#accent_bar').data('accentClicked')) {
          $('#accent_bar').data('accentClicked', false);
        } else {
          initial_value = elm.text();
        }
      });

      elm.bind('blur', function () {
        var new_value;
        if (elm.is('input')) {
          new_value = elm.val();
        } else {
          new_value = elm.text();
        }
        if (!$('#accent_bar').data('accentClicked') && new_value !== initial_value) {
          scope.$apply(function () {
            ngModelCtrl.$setViewValue(new_value);
            scope.update_vocab_word(scope.vocab_word);
          });
        }
      });
    }
  };
});
