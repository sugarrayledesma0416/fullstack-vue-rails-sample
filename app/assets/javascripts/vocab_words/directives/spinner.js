var VHL = VHL || {};

VHL.VocabWords.Directives.directive('ngSpinner', function () {
  return {
    link: function (scope, elm, attrs, ctrl) {
      scope.$on('hide_spinner', function () {
        elm.hide();
      });
      scope.$on('show_spinner', function () {
        elm.show();
      });
    }
  };
});
