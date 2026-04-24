var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vtCloseDropDowns', function () {
  return {
    link: function (scope, elm, attr) {
      elm.click(function () {
        $(elm).find('[data-js-dropdown]').addClass('menu-closed');
      });
    }
  };
});
