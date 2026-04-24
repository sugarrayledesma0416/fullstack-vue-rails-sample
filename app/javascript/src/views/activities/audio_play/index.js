document.addEventListener('DOMContentLoaded', () => {
  // Post Show View - Listen (Play) Audio Button - Event Handlers
  document.querySelectorAll('.js-play-audio').forEach((audioComment) => {
    // Get the Span element containing audio data
    const $clickedCommentButton = $(audioComment);
    const url = $clickedCommentButton.siblings('.js-audio-url').data('audio-url');

    // Create new media button
    new VHL.Music.V1.MediaButton({
      $button: $(audioComment),
      activate: function() {
        // Create Audio Object
        let audio;
        if ($clickedCommentButton.data('audio')) {
          // Extract Audio Object in case it already exists
          audio = $clickedCommentButton.data('audio');
        } else {
          // Create a new Audio object and save
          audio = new Audio(url);
          $clickedCommentButton.data({ audio: audio });
        }
        audio.onended = () => {
          this.reset();
          $clickedCommentButton.data({ audio: false });
        };

        // Play Audio
        audio.play();
      },
      deactivate: () => {
        $clickedCommentButton.data('audio').load();
      },
    });
  });
});
