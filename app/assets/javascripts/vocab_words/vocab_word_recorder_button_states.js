VHL.VocabWordRecorderButtonStates = (function () {

  var constructor = function (params) {
    VHL.Common.add_event_handling(this);
    this.play_button = params.play_button;
    this.record_button = params.record_button;
    this.volume_indicator = params.volume_indicator;

    this.current_state = 'stopped';
    this.has_recorded = false;

    this.valid_states = new Array('stopped', 'playing', 'waiting-record', 'recording');
  };

  /*
possible states (from vhl-arc.js docs)
* stopped
* stopping-play
* stopping-record
* waiting-play
* waiting-record
* playing
* recording
* All but playing, recording, and stopped will be ignored for now.
*/
  constructor.prototype.update_button_states = function (new_state) {
    // ignore all but the states we care about
    if (!_.contains(this.valid_states, new_state)) {
      return false;
    }

    if (this.is_stopped() && new_state === 'playing') {
      this.stop_to_play_state();
    }

    if (this.is_waiting_to_record() && new_state === 'recording') {
      this.has_recorded = true;
      this.stop_to_record_state();
      this.enable_record_button();
    }

    if (new_state === 'stopped') {
      if (this.is_playing()) {
        this.play_to_stop_state();
      }
      if (this.is_recording()) {
        this.record_to_stop_state();
      }
      this.volume_indicator.addClass('hidden_helper');
    }
    this.current_state = new_state;
  };

  constructor.prototype.reset = function () {
    this.record_button.removeClass('stop hidden_helper');
    this.play_button.addClass('stop hidden_helper');
  };

  constructor.prototype.is_playing = function () {
    return (this.current_state === 'playing');
  };

  constructor.prototype.is_recording = function () {
    return (this.current_state === 'recording');
  };

  constructor.prototype.is_stopped = function () {
    return (this.current_state === 'stopped');
  };

  constructor.prototype.is_disabled = function () {
    return this.record_button.hasClass('disabled');
  };

  constructor.prototype.is_waiting_to_record = function () {
    return (this.current_state === 'waiting-record');
  };

  constructor.prototype.play_to_stop_state = function () {
    // Used in Playback of Recordings
    this.play_button.removeClass('stop');
    // Enables Record Button
    this.record_button.disable_link_toggle({
      meth: 'enable'
    });
    this.play_button.siblings('.volume_spinner').addClass('hidden_helper');
    this.record_button.addClass('hidden_helper');
  };

  constructor.prototype.stop_to_play_state = function () {
    // Used in Playback of Recordings
    this.play_button.addClass('stop');
    // Disables Record Button
    this.record_button.disable_link_toggle({
      meth: 'disable',
      disable: ''
    });
  };

  constructor.prototype.record_to_stop_state = function () {
    this.record_button.removeClass('stop').addClass('hidden_helper');
    this.play_button.removeClass('stop').removeClass('hidden_helper');
  };

  constructor.prototype.enable_record_button = function () {
    this.record_button.removeClass('disabled');
  };

  constructor.prototype.disable_record_button = function () {
    this.record_button.addClass('disabled');
  };

  constructor.prototype.stop_to_record_state = function () {
    this.record_button.addClass('stop');
    this.record_button.siblings('.volume_spinner').removeClass('hidden_helper');
  };

  constructor.prototype.hide_play_button = function () {
    this.play_button.removeClass('stop').addClass('hidden_helper');
    this.play_button.siblings('.volume_spinner').addClass('hidden_helper');
  };

  constructor.prototype.toggle_play_button = function(new_recording) {
    if (new_recording) {
      this.hide_play_button();
    } else {
      this.play_to_stop_state();
    }
  };

  return constructor;
}());
