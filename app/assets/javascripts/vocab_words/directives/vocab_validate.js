var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vocabvalidate', function () {
  return {
    link: function (scope, elm) {
      function is_blank(text) {
        // Text goes to the salon for a trim. :3
        if (text) {
          text = text.trim();
        }
        return text === '<br>' || text === '';
      }

      function all_fields_blank() {
        return is_blank(scope.vocab_word.target_word) &&
          is_blank(scope.vocab_word.target_definition) &&
          is_blank(scope.vocab_word.base_word);
      }

      function validate(value) {
        if (all_fields_blank()) {
          elm.toggleClass('invalid_word', true);
        } else {
          elm.toggleClass('invalid_word', false);
        }
      }

      scope.$watch('vocab_word.target_word', validate);
      scope.$watch('vocab_word.target_definition', validate);
      scope.$watch('vocab_word.base_word', validate);
      scope.$watch('lesson_at_edit', function (new_val) {
        if (new_val && scope.vocab_word) {
          scope.vocab_word.lesson_id = new_val.id;
          var new_lesson_name = (new_val.label == '') ? new_val.name : new_val.label;
          scope.vocab_word.lesson_name = new_lesson_name;
        }
      });
    }
  };
});
