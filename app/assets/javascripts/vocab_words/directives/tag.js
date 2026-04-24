var VHL = VHL || {};

VHL.VocabWords.Directives.directive('tag', function () {
  return {
    link: function (scope, elm, attrs, ctrl) {
      elm.on('click', function (e) {
        e.stopPropagation();
        elm.siblings().find('input').focus();
      });
    }
  };
});
