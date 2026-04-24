var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vtDropDownMenu', function () {
  return {
    link: function (scope, elm) {
      elm.addClass('menu-closed');
      elm.click(function (event) {
        elm.addClass('menu-closed');
        event.stopPropagation();
      });
    }
  };
});
