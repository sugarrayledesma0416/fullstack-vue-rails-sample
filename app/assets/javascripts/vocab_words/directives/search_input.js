var VHL = VHL || {};

VHL.VocabWords.Directives.directive('searchInput', function () {
  return {
    require: 'ngModel',
    link: function (scope, elm, attrs, ctrl) {
      var BACKSPACE = 8;
      var SPACE = 32;
      var keys = {
        no_action: [9, 16, 17, 18, 19, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 45],
        deletion: [8, 46, 91]
      };

      function trigger_search() {
        scope.search_results = scope.vocab_words;
        scope.search_by_lesson();
        scope.$apply(function () {
          scope.search_and_paginate_results();
        });
      }

      elm.on('accented_character_added', function() {
        scope.search_term = $(elm).val();
        trigger_search();
      });

      elm.keyup(function (event) {
        var code = event.keyCode || event.which;
        if (_.contains(keys.no_action, code)) { // Exit if the keypress was one we don't care about
          return;
        } else if (_.contains(keys.deletion, code)) {
          // Reset the search results to the entire list filtered by selected lesson if a character was deleted
          trigger_search();
        } else { // For all other key presses (i.e. character, number insertions) refine the search results as-is
          scope.$apply(function () {
            scope.search_and_paginate_results();
          });
        }
      });
    }
  };
});
