/******************************************************************/
/**
 * Class to handle audio control Media buttons in reply/edit modal.
 * Used by Forums when reply/edit modal UI is displayed
 */
class AudioControls {

  constructor($currentForm) {
    this.audio = null;
    this.recorder = new StreamRecorder({});
    this.$form = $currentForm;

    // Create Media Button for Record
    let $audioRecordButton = $currentForm.find('.js-record-media-button');
    this.recordButton = new VHL.Music.V1.MediaButton({
      $button: $audioRecordButton,
      activate: this._recordButtonPlayhandler.bind(this),
      deactivate: this._recordButtonStophandler.bind(this),
      volume: () => { return this.recorder.volume() }
    });

    // Create Media Button for Listen
    let $audioListenButton = $currentForm.find('.js-listen-media-button');
    this.listenButton = new VHL.Music.V1.MediaButton({
      $button: $audioListenButton,
      activate: this._listenButtonPlayHandler.bind(this),
      deactivate: this._listenButtonStopHandler.bind(this)
    });
    this.listenButton.state = VHL.Music.V1.MediaButton.states.DISABLED;

    // Create Button for Delete
    this.$audioDeleteButton = $currentForm.find('.js-delete-button');
    this.$audioDeleteButton.on('click', () => this._deleteButtonHandler());
  }

  /**
    * @summary handles play event for record button 
    */
  _recordButtonPlayhandler() {
    // In case the recording already exists, confirm if user wishes to override that recording
    if (this.audio &&
      !window.confirm('Do you want to discard the existing recording?')) {
      this.recordButton.reset();
    }

    this.recorder.startRecording(function () {/*noop*/});
  }

  /**
  * @summary handles stop event for record button 
  */
  _recordButtonStophandler() {
    // Tell Recorder to Stop Recording
    // And then call my stop recording callback
    this.recorder.stopRecording(this._stopRecordingCallback.bind(this));
  }

  /**
   * Callback function for stop recording event. 'this' is bind to Forums instance  
   * @param  {Recording} recording | The touchstart event
   */
  _stopRecordingCallback(recording) {
    /* This callback is passed for several
     * messages within recorder, but we only
     * we only want to call it for target recordings
     */
    if (recording.type !== 'target') return;

    this.$audioDeleteButton.prop('disabled', false);
    this.listenButton.state = VHL.Music.V1.MediaButton.states.DEFAULT;

    // Create Audio object and get blob
    this.audio = new Audio();
    this.audio.src = URL.createObjectURL(recording.blob);
    this.blob = recording.blob;
    const formElm = this.$form.length && this.$form[0];
    formElm?.dispatchEvent(new CustomEvent('audio:changed', {
      detail: { hasAudio: true },
      bubbles: true
    }));
    // Bind on ended to reset Listen Button once the audio ends
    this.audio.onended = () => {
      this.listenButton.reset();
      this.$audioDeleteButton.prop('disabled', false);
    };
  }

  /**
  * @summary handles play event for listen button 
  */
  _listenButtonPlayHandler() {
    this.audio.play();
  }

  /**
  * @summary handles pause event for listen button 
  */
  _listenButtonStopHandler() {
    this.audio.load();
  }

  /**
  * @summary handles click event for delete button 
  */
  _deleteButtonHandler() {
    // Clear Recorder and dispable delete button
    this.recorder.clear();
    this.$audioDeleteButton.prop('disabled', true);
    
    // Reset Media buttons
    this.recordButton.state = VHL.Music.V1.MediaButton.states.DEFAULT;
    this.listenButton.state = VHL.Music.V1.MediaButton.states.DISABLED;

    this.audio = null;
    this.blob = null;
  }
}
