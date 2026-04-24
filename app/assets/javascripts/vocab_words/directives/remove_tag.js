var VHL = VHL || {};

VHL.VocabWords.Directives.directive('removeTag', function () {
  return {
    link: function (scope, elm, attrs, ctrl) {
      // 'Mousedown' fires before 'click', thereby ensuring that this code block executes before new-tag's blur event
      elm.on('mousedown', function (e) {
        scope.$apply(function () {
          // Find the input where we enter new tag names.
          var new_tag_input = elm.parent().siblings('.new-tag').children(':first');
          new_tag_input.data('removeTagClicked', true);
          e.stopPropagation();
          // Get the tag name that has been clicked and remove it from our word.
          var tag_text = $(e.target).siblings('.tag-text').text();
          scope.remove_vocab_tag(tag_text);
          // Save the word.
          scope.save_vocab_tag_changes();
          // Reset the state of the input and focus on it for adding any new words.
          elm.data('removeTagClicked', false);
          new_tag_input.focus();
        });
      });
    }
  };
});
