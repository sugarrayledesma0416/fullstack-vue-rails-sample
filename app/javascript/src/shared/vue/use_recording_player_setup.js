import useRecordingHelper from './use_recording_helper';
/**
 * Composable returns methods related to playback media button in Add/Edit Intructor Note Modal.
 * @param {Object} refPlayerInstance ref to store VHL.Audio.File instance.
 * @param {Object} refPlaybackButton ref to playback media button elm.
 * @param {Object} localState reactive object having following keys
 * recorderState: String,
 * @return {Object} an object wrapping following methods
 * setupAudioPlayer,
 * initPlayer,
 * resetPlayerMediaButton,
 * onPlayerActivate,
 * onPlayerDeactivate,
 */
const useRecordingPlayerSetup = (refPlayerInstance, refPlaybackButton, localState) => {
  const { pathToURL } = useRecordingHelper();

  /**
   * Setup method to initialize AudioPlayer.
   * @param {String} recordingPath - The relative path to the recording
   */
  const setupAudioPlayBack = (recordingPath) => {
    initPlayer(recordingPath);
  };

  /**
   * Initialize AudioPlayer with a new recording path. Can be called repeatedly.
   * @param {String} recordingPath - The relative path to the recording
   */
  const initPlayer = (recordingPath) => {
    if (!recordingPath) {
      return;
    }

    let recordingUrl;

    if (localState.useSpecifiedPathAsUrl) {
      recordingUrl = recordingPath;
    } else {
      recordingUrl = pathToURL(localState);
    }

    refPlayerInstance.value = new VHL.Audio.File(recordingUrl);

    // Media button callbacks 'activate' and 'deactivate' are already set via initial props
    // so only need to manage button state
    localState.playerState = 'loading';

    // iOS Safari raises 'Unhandled Promise Rejection' error,
    // if enough data has not been loaded to play the audio.
    refPlayerInstance.value.audio.addEventListener('canplaythrough', () => {
      // Check 'state == 'loading'' is used as 'canplaythrough' event is firing multiple times,
      // eg on each replay, which would toggle UI state incorrectly otherwise.
      if (localState.playerState == 'loading') {
        localState.playerState = 'default';
      }
    });

    // handling jquery event from VHL.Audio.File
    refPlayerInstance.value.on('ended', resetPlayerMediaButton);
  };

  /**
   * This method clears all button states and returns button to default state.
   * Note: media button callback functions 'activate' and 'deactivate' are not changing thoughout,
   * so did not need to call media button's resetMediaButton(callbacks)
   */
  const resetPlayerMediaButton = () => {
    localState.playerState = 'default';
  };

  /**
   * Callback function for media button
   */
  const onPlayBackActivate = () => {
    if (refPlayerInstance.value) {
      refPlayerInstance.value.play();
      // Setting playerState var to keep in sync with button ui state
      localState.playerState = 'active';
    }
  };

  /**
   * Callback function for media button
   */
  const onPlayBackDeactivate = () => {
    if (refPlayerInstance.value) {
      refPlayerInstance.value.stop();
      // Setting playerState var to keep in sync with button ui state
      localState.playerState = 'default';
    }
  };

  return {
    setupAudioPlayBack,
    initPlayer,
    resetPlayerMediaButton,
    onPlayBackActivate,
    onPlayBackDeactivate,
  };
};

export default useRecordingPlayerSetup;
