var VHL = VHL || {};

VHL.VocabWords.Directives.directive('toggleable', function () {
  return {
    scope: {
      vocabword: '='
    },
    link: function (scope, elm, attrs) {
      elm.find('.drop_control').bind('click', function () {
        var opened = elm.hasClass('open_row');

        if (!opened) {
          scope.$emit('select_word', scope.vocabword);
        } else {
          scope.$emit('clear_selected_word');
        }

      });
    }
  };
});
