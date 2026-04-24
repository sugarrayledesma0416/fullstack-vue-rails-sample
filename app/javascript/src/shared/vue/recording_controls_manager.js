import usePlayerSetup from './use_player_setup';
import useRecorderSetup from './use_recorder_setup';
import useRecordingCompareSetup from './use_recording_compare_setup';
import useRecordingPlayerSetup from './use_recording_player_setup';
import { reactive, ref } from 'vue';

/**
 * A manager for the audio recording controls
 */
export default class RecordingControlsManager {
  /**
   * @typeDef {RecorderStateObject}
   * @type {Object}
   * @property {boolean} isRecordingInProgress,
   * @property {Object} playerState - reactive object with state information
   * about player instance.
   * @property {Object} compareState - reactive object with state information
   * about compare button.
   * @property {Object} recorderState - reactive object with state information
   * about recoder instance.
   * @property {string} recordingCdnPrefix - URL prefix for playing back recorded audio.
   * @property {string} recordingEndpoint - URL to which audio recordings are uploaded.
   */

  /**
   * @typeDef {RecordingConfigObject}
   * @type {Object}
   * @property {string} [audioPromptSrc] - URL for audio prompt in recording v2 activities.
   * @property {string} baseDir - URL base path to build URL to which audio recirdings
   * are uploaded.
   * @property {string} cdnPrefix - URL prefix for playing back recorded audio.
   * @property {string} endpoint - URL to which audio recordings are uploaded.
   * @property {boolean} [hasCompareButton]
   */

  /**
   * @param {RecoderStateObject} recorderState
   * @param {RecordingConfigObject} recordingConfig
   * @param {Object} refCompareButton - Vue.js reference to compare button.
   * @param {Object} refPlaybackButton - Vue.js reference to play back button.
   */
  constructor(
    recorderState,
    recordingConfig,
    refCompareButton,
    refPlaybackButton
  ) {
    this.recorderState = recorderState;
    this.recordingConfig = recordingConfig;
    this.refPlaybackButton = refPlaybackButton;
    this.refPlayerInstance = ref(null);
    this.refRecorderInstance = ref(null);

    // This component state is passed in composables and would be updated
    // by their code
    this.audioButtonState = reactive({
      playerState: 'disabled',
      recordingPath: recordingConfig.audioPromptSrc,
    });

    // Include methods related to player
    this.playerSetup = usePlayerSetup(
      this.refPlayerInstance,
      this.audioButtonState,
      this.recorderState
    );

    // Include methods related to the recorder player
    this.recordingPlayerSetup = useRecordingPlayerSetup(
      this.refPlayerInstance,
      this.refPlaybackButton,
      this.recorderState
    );

    // Include methods related to recorder
    this.recorderSetup = useRecorderSetup(this.refRecorderInstance, this.recorderState);

    this.onPlayBackActivate = this.recordingPlayerSetup.onPlayBackActivate;
    this.onPlayBackDeactivate = this.recordingPlayerSetup.onPlayBackDeactivate;
    this.onPlayerActivate = this.playerSetup.onPlayerActivate;
    this.onPlayerDeactivate = this.playerSetup.onPlayerDeactivate;
    this.onRecorderActivate = this.recorderSetup.onRecorderActivate;
    this.onRecorderDeactivate = this.recorderSetup.onRecorderDeactivate;
    this.onRecorderVolume = this.recorderSetup.onRecorderVolume;
    this.resetPlayerMediaButton = this.recordingPlayerSetup.resetPlayerMediaButton;

    this.initAudioCompare(refCompareButton);
  }

  /**
   * Initializes the audio player, recorder and playback
   * to their initial states
   */
  initRecordingControls() {
    this.setupAudioPlayBack(this.recorderState.recordingPath);
    this.setupAudioPlayer(this.audioButtonState.recordingPath);
    this.setupAudioRecorder(this.recordingConfig);
  }

  /**
   * Re-initializes the audio prompt player when the audio prompt
   * id changes or is deleted.
   * @param {string} newAudioSrc - the new recording source
   */
  refreshPromptPlayer(newAudioSrc) {
    this.audioButtonState.recordingPath = newAudioSrc;
    this.setupAudioPlayer(this.audioButtonState.recordingPath);
    this.initAudioCompare(this.refCompareButton);
  }

  /**
   * Resets the recording controls stoping any audio that is playing
   */
  resetRecordingControls() {
    // Reset recorder to have no recording
    this.resetRecorder();

    // Stop any recording playback
    if (this.refPlayerInstance.value?.is_playing()) {
      this.refPlayerInstance.value.stop();
    }

    // Stop any compare playback
    if (this.refCompareInstance?.value?.in_autoplay()) {
      this.refCompareInstance.value.stop_and_reset();
    }

    // Reset playback button to have no recording
    this.resetPlayer();
    this.recorderState.playerState = 'disabled';

    this.recorderState.disableDelete = true;
  }

  /**
   * @param {string} audioPromptPath - The path to the audio prompt.
   * @param {string} recordingPath - The path to the recording.
   */
  setupAudioCompare(audioPromptPath, recordingPath) {
    this.compareSetup.setupAudioCompare(audioPromptPath, recordingPath);
  }

  /**
   * @param {string} recordingPath - The path for the recording.
   */
  setupAudioPlayBack(recordingPath) {
    this.recordingPlayerSetup.setupAudioPlayBack(recordingPath);
  }

  /**
   * @param {string} audioPath - the audio path for the player.
   */
  setupAudioPlayer(audioPath) {
    this.playerSetup.setupAudioPlayer(audioPath);
  }

  /**
   * typeDef {ConfigObject}
   * @type {Object}
   * @property {string} recordingCdnPrefix - URL prefix for the recording.
   * @property {string} recordingPath - Path for the recording.
   */

  /**
   * @param {ConfigObject} config - Configuration settings for uploading the recording.
   */
  setupAudioRecorder(config) {
    this.recorderSetup.setupAudioRecorder(config);
  }

  /**
   * @private
   * Initializes audio compare functionality if hasCompareButton property
   * of config is true.
   * @param {Object} refCompareButton - Vue.js reference for compare button.
   */
  initAudioCompare(refCompareButton) {
    // Include methods related to the recorder compare
    // if hasCompareButton is true.
    if (this.recordingConfig.hasCompareButton) {
      this.refCompareInstance = ref(null);
      this.refCompareButton = refCompareButton;

      this.compareSetup = useRecordingCompareSetup(
        this.refCompareInstance,
        this.refCompareButton,
        this.recorderState
      );

      this.onCompareActivate = this.compareSetup.onCompareActivate;
      this.onCompareDeactivate = this.compareSetup.onCompareDeactivate;
    }
  }

  /**
   * @private
   * Reset AudioPlayer to have no recording path or file player.
   */
  resetPlayer() {
    // Media button callbacks 'activate' and 'deactivate' won't
    // execute due to this null value
    this.refPlayerInstance.value = null;
  }

  /**
   * @private
   * Resets the recording path.
   */
  resetRecorder() {
    this.recorderState.recordingPath = '';
  }
}
