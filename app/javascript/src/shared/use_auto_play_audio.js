import { computed, reactive } from 'vue';

/**
 * A composable for managing autoplay audio functionality. 
 * Provides methods to play and pause a collection of audio files, 
 * along with reactive state for tracking playback status and audio availability.
 * 
 * @param {string[]} audioPaths - An array of paths to audio files to be played.
 * @returns {Object} retruns object wrapping following properties
 * isAudioPlaying - A boolean indicating whether audio is currently playing.
 * hasAudio - A boolean indicating whether there are audio files to play.
 * play - A method for starting audio playback.
 * pause - A method for pausing audio playback.
 */
export function useAutoPlayAudio(audioPaths) {
  const audioState = reactive({
    isPlaying: false,
    audioFiles: null,
  });

  if (audioPaths && audioPaths.length > 0) {
    audioState.audioFiles = new VHL.Audio.CollectionScheduler(audioPaths);
  }

  const hasAudio = computed(() => {
    return audioState.audioFiles?.files?.length > 0;
  })
  const isAudioPlaying = computed(() => {
    return audioState.isPlaying;
  });

  /**
   * Start playing all audio files in the collection. If the audio is already
   * playing, pause it and start playing from the beginning.
   */
  function play() {
    pause();
    if (hasAudio.value) {
      audioState.isPlaying = true;
      audioState.audioFiles.play_all({
        callback: () => {},
        when: 'before',
        last_callback: () => {
          audioState.isPlaying = false;
        },
      });
    }
  };

  /**
   * Pauses the audio playback and resets the audio files to the beginning.
   * Sets the isPlaying state to false.
   */
  function pause () {
    if (audioState.audioFiles) {
      audioState.audioFiles.stop_and_reset();
      audioState.isPlaying = false;
    }
  };

  return { hasAudio, isAudioPlaying, pause, play };
}
