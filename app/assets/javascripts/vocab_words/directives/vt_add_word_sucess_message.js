var VHL = VHL || {};

//Handle showing a message if a new word is added while in a search
VHL.VocabWords.Directives.directive('vtAddWordSuccessMsg', function ($timeout) {
  return {
    link: function (scope, elm, attr) {
      //if new word flag is set and there is a current search, show the msg
      scope.$watch(attr.vtAddWordSuccessMsg, function () {
        if (scope.add_word_success_enabled && scope.search_term) {
          elm.fadeIn(500, function () {
           $timeout(function () {elm.fadeOut(1000); }, 5000);
          });
        }
        scope.add_word_success_enabled = false;
      });
    }
  };
});
