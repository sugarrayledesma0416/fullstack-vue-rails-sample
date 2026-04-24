function initializeAudioTranscriptDisclosures() {
  document.querySelectorAll('.js-disclosure').forEach(
    (button) => {
      let disclosure = new VHL.Music.V1.Disclosure(button);
      const headerElm = disclosure.$header[0];
      headerElm.addEventListener(
        'click',
        (evt) => {
          const isOpened = evt.currentTarget.getAttribute('aria-expanded') === 'true';
          const label = isOpened ? 'Hide' : 'Show';
          headerElm.textContent = `${label} Audio Transcript`;

          if (isOpened) {
            VHL.Dispatcher.send(VHL.Stats.Counter('audio_transcript.show_audio_text'));
          }
        }
      );
    }
  );
}

document.addEventListener(
  'DOMContentLoaded',
  initializeAudioTranscriptDisclosures
);
