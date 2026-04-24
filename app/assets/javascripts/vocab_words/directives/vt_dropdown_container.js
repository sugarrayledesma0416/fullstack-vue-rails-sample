var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vtDropDownContainer', function () {
  return {
    link: function (scope, elm) {
      elm.click(function (event) {
        $('[data-js-dropdown]').addClass('menu-closed');
        elm.find('[data-js-dropdown]').removeClass('menu-closed');
        event.stopPropagation();
      });
    }
  };
});
