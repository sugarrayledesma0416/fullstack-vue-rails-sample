var VHL = VHL || {};

VHL.VocabWords.Directives.directive('newTag', function ($timeout) {
  return {
    require: 'ngModel',
    link: function (scope, elm, attrs, ctrl) {

      var default_tags = _.select(scope.vocab_word.vocab_tags, function (tag) {
        return _.has(tag, 'default_vocab_word_id');
      });

      scope.vocab_word.vocab_tags_attributes = _.map(default_tags, function (tag) {
        return { name: tag.name};
      });

      var BACKSPACE = 8;
      var ENTER = 13;
      var COMMA = 188;

      elm.on('focus', function (e) {
        // Due to a jQuery 1.7.2 bug this event automatically fires when 'blur' does
        // Wrapping it in a timeout with a delay longer than that of the 'blur' event ensures that this code doesn't interfere
        $timeout(function () {
          elm.data('removeTagClicked', false);
          $('#accent_bar').data('accentClicked', false);
        }, 200);
      });

      elm.on('blur', function (e) {
        $timeout(function () {
          //fire the scope.$apply if there are any tags in vocab_tags_attributes with _destroy = 1, or if the
          //current value in the input field is not an empty string, meaning someone typed 'blah' and just clicked
          //out of the input field...we want to capture blah and turn it into a tag
          var deletions_not_yet_in_db = !_.isEmpty(_.compact(_.pluck(scope.vocab_word.vocab_tags_attributes, '_destroy')));

          if (!elm.data('removeTagClicked') && !$('#accent_bar').data('accentClicked') && (deletions_not_yet_in_db || elm.val() !== '')) {
            scope.set_current_word(scope.vocab_word);

            scope.$apply(function () {
              if (elm.val() !== '') {
                new_vocab_tag = {};
                new_vocab_tag.name = elm.val();
                scope.add_vocab_tag(new_vocab_tag);
              }
              scope.save_vocab_tag_changes();
              elm.val('');
              elm.data('removeTagClicked', false);
              $('#accent_bar').data('accentClicked', false);
            });
          }
        }, 100);
      });
      var last_character_deleted;
      var backspace_tracker;
      elm.on('keyup', function (event) {
        var code = event.keyCode || event.which;
        if (code === BACKSPACE && last_character_deleted === "" && backspace_tracker === BACKSPACE) {
          scope.$apply(function () {
            var tag_text = $(elm).prev('.tag-text').text();
            scope.remove_vocab_tag(tag_text);
            backspace_tracker = null;
          });
        } else if (backspace_tracker === BACKSPACE && code !== BACKSPACE) {
          elm.parent().siblings('li:last').css({'background-color': 'transparent', 'color': 'black'});
          backspace_tracker = null;
        } else if (code === BACKSPACE && last_character_deleted === "") {
          elm.parent().siblings('li:last').css({'background-color': 'red', 'color': 'white'});
          backspace_tracker = BACKSPACE;
        }
      });

      elm.on('keydown', function (event) {
        var code = event.keyCode || event.which;
        if (code === BACKSPACE) {
          last_character_deleted = elm.val();
        } else if (code === COMMA || code === ENTER) {
          new_vocab_tag = {};
          new_vocab_tag.name = elm.val();
          elm.val('');

          event.preventDefault();
          scope.add_vocab_tag(new_vocab_tag);
          // Reset input field. We really should be using Angular's
          // 2-way data binding here, but this is a quick fix.
          // TODO spec
          scope.save_vocab_tag_changes(); // handles case when the user adds a tag and immediately leaves the page (no blur fired)
        }
      });
    }
  };
});

