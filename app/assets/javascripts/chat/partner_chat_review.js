$(document).ready(function() {
  function checkVideoPermissions(pchatRecording, pchatContainer) {
    const pchatVideoHandler = (video_url) => {
      // Use hicks to play video.
      let videoHandler = new VHL.Video.File();

      videoHandler.init({ sourceURL: video_url || pchatRecording, videoContainer: pchatContainer });

      // Initialize hicks, show video, show controls and set background to black to match old
      // pchat implementation.
      videoHandler.initialize_video();
      videoHandler.show_video();
      /* This is to solve issue https://vistahl.atlassian.net/browse/MAE-59766
       * For some reason when reviewing the native controls get active, but on 
       * Firefox the native controls are not shown.
       * The fix is to force the VideoJS controls and display them.
       */
      videoHandler.videojs_player.on('ready', (event) => {
        videoHandler.videojs_player.usingNativeControls(false);
        videoHandler.videojs_player.controls(true);
      })
      videoHandler.video.style = 'background: black';
    };

    VHL.VideoAccessChecker.verifyRecordingPermission('/video_chat/video_permission', pchatRecording)
      .catch((err) => console.log('something bad happened', err))
      .then((video_url) => pchatVideoHandler(video_url)); // Then after catch so we always show hicks no matter what.
  }

  document.querySelectorAll('#partner_chat_container').forEach((container) => {
    const isSvr = container.getAttribute('data-is-svr') === 'true';
    if (
      !(
        (VHL.Common.metaTagContent('VHL.Controller') === 'review_work' ||
        VHL.Common.metaTagContent('VHL.Controller') === 'grading_sets') &&
        (VHL.Chat.CONFIG.activityType === 'solo_video_recording' || isSvr)
      )
    ) {
      let pchatRecording = $(container).siblings('#recording_file').val();
      checkVideoPermissions(pchatRecording, container);
    }
  });

  document.querySelectorAll('.js-pchat-video-container').forEach((container) => {
    container.style = 'width: 480px; height: 270px';

    let pchatRecording = $(container).siblings('#recording_file').val();
    checkVideoPermissions(pchatRecording, container);
  });
});
