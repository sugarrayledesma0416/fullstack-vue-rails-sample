var VHL = VHL || {};

VHL.VocabWords.Directives.directive('vocabAudioRecorder', function () {
  return {
    scope: {
      recorder: '=vocabAudioRecorder'
    },
    link: function (scope, elm, attrs) {

      var recorder_params = {server_host: attrs.recordingHost,
                             recording_path: attrs.recordingPath,
                             container: $('.activity_recorder')};

      scope.recorder = new VHL.VocabWordAudioRecorder(recorder_params);

      $(elm).find('.recorder_reset').on('click', function (event) {
        event.preventDefault();
        if (window.confirm('Replace existing recording?')) {
          scope.recorder.reset();
        }
      });

      scope.$on('stop_recorder', function () {
        scope.recorder.reset();
      });
    }
  };
});
