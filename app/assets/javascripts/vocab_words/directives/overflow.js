var VHL = VHL || {};

VHL.VocabWords.Directives.directive('overflow', function ($timeout, overflowService) {
  return {
    link: function (scope, element, attr, timeout) {
      $timeout(function () {
        overflowService.create_hover(element);
      });
    }
  };
});
