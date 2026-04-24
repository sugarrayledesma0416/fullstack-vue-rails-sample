var VHL = VHL || {};

VHL.VocabWords.Directives.directive('ngConfirm', function (PopupService) {
  return {
    restrict: 'A',
    link: function (scope, elm, attrs) {
      elm.bind("click", function (event) {
        PopupService.confirm(attrs["ngTitle"], attrs["ngConfirm"],
                             attrs["ngBtnConfirm"], attrs["ngConfirmAction"], scope);
        event.preventDefault();
      });
    }
  };
});
