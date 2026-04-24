var VHL = VHL || {};

VHL.VocabWords.Directives.directive('saveOnBlur', function () {
  return {
    link: function (scope, element, attr) {
      element.bind('blur', function (e) {
        var vocab_field = $(element).attr("data-current-field");
        if (vocab_field === "target_word" || vocab_field === "target_definition" || vocab_field === "base_word") {
          scope.current_word[vocab_field] = $(element).val();
        }
        scope.$emit('save_word');
      });

      element.bind('keypress', function (event) {
        if (event.which === 13) {
          event.preventDefault();
          element.blur();
        }
      });
    }
  };
});
