import useRecordingHelper from './use_recording_helper';
/**
 * Composable returns methods related to recorder media button in custom assessments
 * @param {Object} refRecorderInstance ref to store VHL.Audio.Recorder instance.
 * @param {Object} localState reactive object having following keys
 * recorderState: String,
 * playerState: String,
 * disableDelete: Boolean,
 * recordingPath: String.
 * @param {Function} initPlayer function to re-initialize recorder button.
 * @param {Function} emitRecordingPathChange function to emit 'recordingPathChange' event.
 * @return {Object} an object wrapping following methods
 * setupAudioRecorder,
 * updateRecorderForPath,
 * onRecorderActivate,
 * onRecorderDeactivate,
 * onRecorderVolume,
 */
const useRecorderSetup = (
  refRecorderInstance,
  localState
) => {
  const { sanitizePath } = useRecordingHelper();

  /**
   * Setup method to initialize Audio Recorder.
   * @param {object} config - Instructor Notes Config object
   */
  const setupAudioRecorder = (config) => {
    refRecorderInstance.value = new VHL.Audio.Recorder(config);

    // handling jquery event from VHL.Audio.Recorder
    if (typeof $ !== 'undefined') {
      $(refRecorderInstance.value).on('uploadComplete', (data) => {
        if (config.skipSanitize) {
          localState.recordingPath = data.path;
        } else {
          localState.recordingPath = sanitizePath(data.path);
        }
        onUploadComplete();
      });
    }
  };

  /**
   * Update for a new recording path. Can be called repeatedly.
   * @param {String} recordingPath - The relative path to the recording
   */
  const updateRecorderForPath = (recordingPath) => {
    localState.recordingPath = recordingPath;
  };

  /**
   * This method clears all button states and returns button to default state.
   * Note: media button callback functions 'activate' and 'deactivate' are not changing thoughout,
   * so did not need to call media button's resetMediaButton(callbacks)
   */
  const resetRecorderMediaButton = () => {
    localState.recorderState = 'default';
  };

  const onRecordStart = () => {
    // Setting recorderState var to keep in sync with button ui state
    localState.recorderState = 'active';
    localState.isRecordingInProgress = true;
  };

  const onRecordStop = () => {
    resetRecorderMediaButton();
    localState.playerState = 'loading';
    localState.compareState = 'loading';
    // Setting recorderState var to keep in sync with button ui state
    localState.recorderState = 'default';
  };

  const onUploadComplete = () => {
    localState.disableDelete = false;
    localState.isRecordingInProgress = false;
  };

  /**
   * Callback function for media button
   */
  const onRecorderActivate = () => {
    if (refRecorderInstance.value) {
      refRecorderInstance.value.start();
      onRecordStart();
    }
  };

  /**
   * Callback function for media button
   */
  const onRecorderDeactivate = () => {
    if (refRecorderInstance.value) {
      refRecorderInstance.value.stop();
      onRecordStop();
    }
  };

  /**
   * Callback function for media button
   * @return {Number} volume of the player between 1-100
   */
  const onRecorderVolume = () => {
    if (refRecorderInstance.value?.volume) {
      return refRecorderInstance.value?.volume();
    }
  };

  return {
    setupAudioRecorder,
    updateRecorderForPath,
    onRecorderActivate,
    onRecorderDeactivate,
    onRecorderVolume,
  };
};

export default useRecorderSetup;
