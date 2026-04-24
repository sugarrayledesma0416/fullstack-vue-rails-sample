var VHL = VHL || {};

VHL.VocabWords.Directives.directive('isDisabled', function () {
  return {
    require: 'ngModel',
    link: function (scope, elm, attrs, ctrl) {
      ctrl.$parsers.unshift(function (viewValue) {
        if (viewValue) {
          scope.add_word_disabled = false;
          return viewValue;
        } else {
          scope.add_word_disabled = true;
          return undefined;
        }
      });
    }
  };
});
