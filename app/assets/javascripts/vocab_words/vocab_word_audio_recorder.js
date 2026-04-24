//= require maestro_activity_engine/bindable
//= require maestro_activity_engine/audio_item_recorder
//= require ./vocab_word_recorder_button_states

VHL.VocabWordAudioRecorder = (function () {

  // We store the params here and set defaults
  var constructor = function (params) {
    this.params = params;
    this.params.volume_size = 'small';
  };

  constructor.prototype = new VHL.AudioItemRecorder();

  // We initialize calling this method because
  // we don't want to initialize the recorder as
  // soon as a new and ance of this class is called.
  constructor.prototype.initialize = function (new_params) {
    this.init(_.extend(this.params, { button_manager: VHL.VocabWordRecorderButtonStates}, new_params));
    this.button_states.toggle_play_button(new_params.new_recording);
  };

  constructor.prototype.reset = function () {
    this.player.stop();
    this.button_states.reset();
  };

  constructor.prototype.recording_path = function () {
    if (this.button_states.has_recorded) {
      return this.new_recording_path;
    }
    return null;
  };

  constructor.prototype.bind_events = function (item_player) {
    this.player.bind("state_change", function (new_state) {
      item_player.button_states.update_button_states(new_state);
    });

    this.record_button.on('click', function (click_event) {
      if (item_player.button_states.is_recording()) {
        item_player.player.stop();
      } else if (item_player.button_states.is_stopped()) {
        item_player.player.record();
      }
      click_event.preventDefault();
    });

    this.play_button.on('click', function (click_event) {
      if (item_player.button_states.is_playing()) {
        item_player.player.stop();
      } else if (item_player.button_states.is_stopped()) {
        item_player.player.play();
      }
      click_event.preventDefault();
    });

    this.player.bind('volume_change', function (volume) {
      item_player.volume_indicator.push(volume);
    });

    ARC.mic_disabled = function () {
      $('#vhlarccontainer').css({'top': '30%', 'left': '45%', 'position' : 'fixed', 'z-index' : '10011'});
    };

    /* If the user decides to enable the microphone the we trigger the recording for this item since the recording call on this.player.bind('done_playing') would have failed. */
    ARC.mic_enabled = function () {
      item_player.player.record();
      $('#vhlarccontainer').css('left', '-1000px');
    };

    /* If the user decides no to enable the microphone we just close the dialog. */
    ARC.mic_not_enabled = function () {
      $('#vhlarccontainer').css('left', '-1000px');
    };
  };

  return constructor;
}());
