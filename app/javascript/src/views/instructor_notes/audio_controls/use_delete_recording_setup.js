/**
 * Composable returns methods related to Delete Recording button in Add/Edit Intructor Note Modal.
 * @param {Object} refPlayerInstance ref to store VHL.Audio.File instance.
 * @param {Object} localState reactive object having following keys
 * playerState: String,
 * disableDelete: Boolean,
 * recordingPath: String.
 * @param {Function} resetPlayerMediaButton function to reset media button for audio player.
 * @param {Function} emitRecordingPathChange function to emit 'recordingPathChange' event.
 * @return {Object} an object wrapping following methods
 * onDelete,
 * resetRecordingControls,
 */
const useDeleteRecordingSetup = (
  refPlayerInstance,
  localState,
  resetPlayerMediaButton,
  emitRecordingPathChange
) => {
  const onDelete = () => {
    if (localState.disableDelete) {
      return;
    }

    if (confirm('Are you sure you want to delete this audio?')) {
      refPlayerInstance.value.stop();
      clearCurrentNoteRecording();
      localState.disableDelete = true;
    }
  };

  const clearCurrentNoteRecording = () => {
    localState.recordingPath = '';
    resetRecordingControls();
  };

  const resetRecordingControls = () => {
    // Reset recorder to have no recording
    resetRecorder();

    // Stop any recording playback
    if (refPlayerInstance.value?.is_playing()) {
      refPlayerInstance.value.stop();
    }

    // Reset playback button to have no recording
    resetPlayer();
    localState.playerState = 'disabled';

    localState.disableDelete = true;
  };

  const resetRecorder = () => {
    localState.recordingPath = '';
    emitRecordingPathChange(localState.recordingPath);
  };

  /**
   * Reset AudioPlayer to have no recording path or file player.
   */
  const resetPlayer = () => {
    // Media button callbacks 'activate' and 'deactivate' won't execute due to this null value
    refPlayerInstance.value = null;
  };

  return {
    onDelete,
    resetRecordingControls,
  };
};

export default useDeleteRecordingSetup;
