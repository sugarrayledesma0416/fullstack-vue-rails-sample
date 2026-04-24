var VHL = VHL || {};

VHL.VocabWords.Directives.directive('ngDialog', function (PopupService) {
  return {
    restrict: 'A',
    link: function (scope, elm, attrs) {
      elm.bind("click", function (event) {
        PopupService.dialog(attrs["ngDialog"], attrs["ngClose"], {}, scope);
        event.preventDefault();
      });
    }
  };
});
