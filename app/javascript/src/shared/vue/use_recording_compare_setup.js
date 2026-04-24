import useRecordingHelper from './use_recording_helper';
/**
 * Composable returns methods related to playback media button in Add/Edit Intructor Note Modal.
 * @param {Object} refCompareInstance ref to store VHL.Audio.File instance.
 * @param {Object} refCompareButton ref to compare media button elm.
 * @param {Object} localState reactive object having following keys
 * recorderState: String,
 * @return {Object} an object wrapping following methods
 * setupAudioCompare,
 * initComparePlayer,
 * resetCompareMediaButton,
 * onCompareActivate,
 * onCompareDeactivate,
 */
const useRecordingCompareSetup = (refCompareInstance, refCompareButton, localState) => {
  const { pathToURL } = useRecordingHelper();

  /**
   * Setup method to initialize AudioPlayer.
   * @param {String} audioPromptPath - the path to the audio prompt
   * @param {String} recordingPath - The relative path to the recording
   */
  const setupAudioCompare = (audioPromptPath, recordingPath) => {
    initComparePlayer(audioPromptPath, recordingPath);
  };

  /**
   * Initialize AudioPlayer with a new recording path. Can be called repeatedly.
   * @param {String} audioPromptPath - the path to the audio prompt
   * @param {String} recordingPath - The relative path to the recording
   */
  const initComparePlayer = (audioPromptPath, recordingPath) => {
    if (!audioPromptPath || !recordingPath) {
      return;
    }

    const recordingUrl = pathToURL(localState);

    const urlsToPlay = [audioPromptPath, recordingUrl];

    refCompareInstance.value = new VHL.Audio.CollectionScheduler(urlsToPlay, 1000);

    // Media button callbacks 'activate' and 'deactivate' are already set via initial props
    // so only need to manage button state
    localState.compareState = 'loading';

    // iOS Safari raises 'Unhandled Promise Rejection' error,
    // if enough data has not been loaded to play the audio.
    refCompareInstance.value.files[0].audio.addEventListener('canplaythrough', () => {
      // Check 'state == 'loading'' is used as 'canplaythrough' event is firing multiple times,
      // eg on each replay, which would toggle UI state incorrectly otherwise.
      if (localState.compareState == 'loading') {
        localState.compareState = 'default';
      }
    });
  };

  /**
   * This method clears all button states and returns button to default state.
   * Note: media button callback functions 'activate' and 'deactivate' are not changing thoughout,
   * so did not need to call media button's resetMediaButton(callbacks)
   */
  const resetCompareMediaButton = () => {
    localState.compareState = 'default';
  };

  /**
   * Callback function for media button
   */
  const onCompareActivate = () => {
    if (refCompareInstance.value) {
      refCompareInstance.value.play_all({
        callback: () => {
          localState.compareState = 'active';
        },
        when: 'before',
        last_callback: resetCompareMediaButton,
      });
    }
  };

  /**
   * Callback function for media button
   */
  const onCompareDeactivate = () => {
    if (refCompareInstance.value) {
      refCompareInstance.value.stop_and_reset();
    }
  };

  return {
    setupAudioCompare,
    initComparePlayer,
    resetCompareMediaButton,
    onCompareActivate,
    onCompareDeactivate,
  };
};

export default useRecordingCompareSetup;
