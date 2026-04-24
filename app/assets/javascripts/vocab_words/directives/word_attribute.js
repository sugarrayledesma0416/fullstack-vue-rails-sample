var VHL = VHL || {};

VHL.VocabWords.Directives.directive('wordAttribute', function () {
  return {
    require: 'ngModel',
    link: function (scope, elm, attrs, ctrl) {

      elm.on('accented_character_added', function () {
        ctrl.$setViewValue($(this).val());
      });
    }
  };
});
