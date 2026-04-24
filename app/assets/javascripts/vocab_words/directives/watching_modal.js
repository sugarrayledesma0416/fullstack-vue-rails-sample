var VHL = VHL || {};

VHL.VocabWords.Directives.directive('watchingModal', ['$parse', function ($parse) {
  function safeApply(scope, fn) {
    var phase = scope.$root.$$phase;
    if (phase === '$apply' || phase === '$digest') {
      scope.$eval(fn);
    } else {
      scope.$apply(fn);
    }
  }

  return {
    link: function (scope, elm, attrs) {
      var dialog_div = $(attrs.watchingModal);
      var dialog_shown_model = $parse(attrs.dialogShown);

      dialog_div.hide();

      // ensure dialog is initialized (closed by default)
      dialog_div.dialog({
        autoOpen: false,
        resizable: false,
        modal: true,
        dialogClass: "fixed",
        open: function () {
          $('.ui-widget-overlay').bind('click', function () {
            dialog_div.dialog('close');
          });
        },
        close: function () {
          safeApply(scope, function () {
            dialog_shown_model.assign(scope, false);
          });
        }
      });

      // make cancel link work, even before the dialog has been opened for the first time
      dialog_div.find('.cancel_link a').on('click', function (click_event) {
        safeApply(scope, function () {
          dialog_shown_model.assign(scope, false);
        });
        click_event.preventDefault();
      });

      elm.on('click', function (click_event) {
        dialog_div.dialog('open');

        safeApply(scope, function () {
          dialog_shown_model.assign(scope, true);
        });

        click_event.preventDefault();
      });

      scope.$on('image_saved', function () {
        dialog_div.dialog('close');
        $('#modal-upload').find('.qq-upload-list-selector.qq-upload-list').html('');
      });

      scope.$on('recording_saved', function () {
        dialog_div.dialog('close');
      });

      scope.$watch(attrs.dialogShown, function (shown) {
        if (shown) {
          dialog_div.dialog('open');
        } else {
          dialog_div.dialog('close');
          $('#modal-upload').find('.qq-upload-list-selector.qq-upload-list').html('');
        }
      });

    }
  };
}]);
