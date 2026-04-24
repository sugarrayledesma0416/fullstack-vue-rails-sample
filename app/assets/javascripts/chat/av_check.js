/* global VHL */

/* This code has been ported from Compro's reference implementation:
 *
 * https://github.com/vhl/dirt-driver-chat/blob/master/app/public/js/custom-preflight.js
 */

VHL.Chat.AVCHECK_DURATION = 10;

VHL.Chat.AVCheck = class AVCheck {
  constructor() {
    this.ui = {
      AVCheckDone:          '.js-av-check-done',
      openAVCheck:          '.js-open-av-check',
      runTest:              '.js-run-av-test'
    };

    this.audioContext = null;
    this.audioMeter = null;
    this.canvasContext = null;
    this.audioBarWidth = 264;
    this.audioBarHeight = 50;

    /* Stores the return value of window.requestAnimationFrame().
     *   This value could be passed to window.cancelAnimationFrame()
     *   to cancel the refresh request, though we don't do so here.
     */
    this.rafID = null;

    this.mediaStreamSource = null;

    // Bind updateAudioBar so that its "this" is consistent.
    this.updateAudioBar = this.updateAudioBar.bind(this);

    let videoDisclosure = new VHL.Music.V1.Disclosure($('.js-disclosure-video'));
    let audioDisclosure = new VHL.Music.V1.Disclosure($('.js-disclosure-audio'));

    const index = 'vhl-chat-client-tokbox-avcheck';
    this.dataDispatcher = new VHL.CarlinDispatch.Logstash(index);
  }

  startAVCheck() {
    const checkStartTime = Date.now();
    const avCheckLoadingModal = document.querySelector('.js-av-check-loading-modal');
    const trapFocusHandler = (e) => this.trapFocus(e, avCheckLoadingModal);
    var avCheck = this;

    var config = {
      test_duration: VHL.Chat.AVCHECK_DURATION,
      audio_threshold: {
        bits_per_second: 25000,
        packet_loss_ratio_per_second: 0.05
      },
      video_threshold: {
        bits_per_second: 250000,
        packet_loss_ratio_per_second: 0.03
      }
    };

    var mediaOptions = {
      'api_key': VHL.Chat.CONFIG.tokboxApiKey,
      'media_base_url': '/video_chat',
      'my_media_element': 'my-subscribed-media'
    };

    VHL.AVChecks.Adapter.setup(config, mediaOptions,
      function(adapter) {
        // Dispatch latency
        avCheck.dataDispatcher.dispatch('avcheck_setup_latency',
          { latency: { duration: Date.now() - checkStartTime },
            service: 'tokbox',
            config: config }
        );

        avCheckLoadingModal.removeEventListener('keydown', trapFocusHandler);
        $('.js-av-check-loading-modal').vhlModal('close');
        $('.js-av-run-test-modal').vhlModal('open');
        avCheck.avTestAdapter = adapter;
        console.log(avCheck.avTestAdapter);
      },
      function(error) {
        avCheckLoadingModal.removeEventListener('keydown', trapFocusHandler);
        $('.js-av-check-loading-modal').vhlModal('close');
        console.log('Failed to set up the test process.');

        // Dispatch error
        avCheck.dataDispatcher.dispatch('avcheck_setup_error', { error: error, service: 'tokbox' });
        console.log('dispatched avcheck setup error');
      }
    );
    $('.js-av-check-loading-modal').vhlModal('open');
    avCheckLoadingModal.addEventListener('keydown', trapFocusHandler);
  }

  runTest() {
    const runTestStartTime = Date.now();
    const avCheck = this;
    const progressBarModal = document.querySelector('.js-av-progress-bar-modal');
    const trapFocusHandler = (e) => this.trapFocus(e, progressBarModal);
    console.log("runTest called");
    var timeElapsed = 0, percentageCompletion;

    let progressBarDiv = $('.ui-progressbar');
    let progressBarLabelDiv = $('.progress-label');

    $(".js-av-run-test-modal").vhlModal('close');
    $("#my-subscribed-media").hide();
    progressBarLabelDiv.text('0%');
    progressBarDiv.show();
    $(".js-av-progress-bar-modal").vhlModal('open');
    progressBarModal.addEventListener('keydown', trapFocusHandler);

    avCheck.avTestAdapter.runTest(
      function(testResults) {
        // Dispatch results for test
        avCheck.dataDispatcher.dispatch('run_test_latency',
          { latency: { duration: Date.now() - runTestStartTime },
            service: 'tokbox',
            results: testResults });

        console.log("Test concluded", testResults);

        progressBarModal.removeEventListener('keydown', trapFocusHandler);
        $(".js-av-progress-bar-modal").vhlModal('close');
        progressBarDiv.hide();

        // prepare HTML background for showing test results
        $(".column-background").css("background-color", "#eeeeee");
        //$("#cleanup-res").show();
        $("#my-subscribed-media").show();
        $("#audio-bar").show();
        $("#mic-icon").show();

        // Show Stats
        avCheck.showTestResults(testResults);
        // Show Audio Bar
        //_setupAudioBar();
      },
      function(error) {
        progressBarModal.removeEventListener('keydown', trapFocusHandler);
        $(".js-av-progress-bar-modal").vhlModal('close');
        console.log('Failed to set up the test process.');

        if(error.name === "OT_USER_MEDIA_ACCESS_DENIED") {
          // Dispatch hardware denied error
          avCheck.dataDispatcher.dispatch('hardware_access_denied_error',
            { error: error, service: 'tokbox' });

          console.log('dispatched access denied error');
          var testResults = {
              audio: {
                  is_hardware_available_with_permissions: false
              },
              video: {
                  is_hardware_available_with_permissions: false
              }
          };
          // prepare HTML background for showing test results
          $('.js-av-results-modal').vhlModal('open');
          $("#audio-bar").show();
          $("#mic-icon").show();
          //show stats
          avCheck.showTestResults(testResults);
        } else {
          // Dispatch error
          avCheck.dataDispatcher.dispatch('run_test_error', { error: error, service: 'tokbox' });
          alert("Failed to start test. error: " + JSON.stringify(error));
          $("#cleanup-res").show();
        }
      }
    );

    progressBarDiv.progressbar({
      value: 0,
      change: () => {
        progressBarLabelDiv.text(`${progressBarDiv.progressbar('value')}%`);
      }
    });
    $('.ui-progressbar.ui-widget-content').css({ 'background': 'honeydew' });
    $('.ui-progressbar > .ui-widget-header').css({ 'background': 'green' });
    $('.progress-label').css({ 'color': 'white',
                               'text-shadow': '-1px 1px 0 green, 1px 1px 0 green, 1px -1px 0 green, -1px -1px 0 green' });

// Show Progress Bar / Completion Percentage
    var intervalId = setInterval(function() {
        timeElapsed++;
        percentageCompletion = (timeElapsed/VHL.Chat.AVCHECK_DURATION) * 100 ;
        percentageCompletion = Math.round((percentageCompletion * 100) / 100);
        if(percentageCompletion > 100) {
            clearInterval(intervalId);
        } else {
          progressBarDiv.progressbar('value', percentageCompletion);
        }
    }, 1000);
  }

  formatQuality(quality) {
    if(quality == 'good') {
      return '<span class="u-txt-green">Good</span>';
    } else {
      return '<span class="u-txt-light-red">Bad</span>';
    }
  }

  displayStats(testResults, type) {

    var packet_loss_ratio_per_second = 0;
    var bits_per_second = 0;
    var typeTitleCase = type.charAt(0).toUpperCase() + type.slice(1);

    if(testResults[type].is_hardware_available_with_permissions) {
      // Add details; make detail dropdown visible.avCheck
      packet_loss_ratio_per_second = Math.round(
        testResults[type].stats.packet_loss_ratio_per_second * 100
      ) / 100;
      bits_per_second = Math.round(testResults[type].stats.bits_per_second);

      let quality = this.formatQuality(testResults[type].quality);

      $(`#${type}-results h2`).html(`${typeTitleCase} quality: ${quality}`);
      $(`#${type}-details`).removeClass('u-hidden');

      if(type === 'audio') {
        this.setupAudioBar();
      }
    }
    else {
      // Add title no available device in avCheck
      $(`#${type}-results h2`).html(`${typeTitleCase} not available`);
    }

    $(`.js-av-${type}-details`).html(
      `<div>${packet_loss_ratio_per_second}% ${type} packet loss</div>
       <div>${typeTitleCase} Bitrate ${bits_per_second} bps</div>`
    );
  }

  showTestResults(testResults) {
    $('.js-av-results-modal').vhlModal('open');
    this.displayStats(testResults, 'video');
    this.displayStats(testResults, 'audio');
    this.setMuteButtonInitialAriaState();
  }

  setupAudioBar() {
      // grab the canvas
      this.canvasContext = document.getElementById("audio-bar").getContext("2d");

      window.AudioContext = window.AudioContext || window.webkitAudioContext;

      // grab an audio context
      this.audioContext = new AudioContext();
      let avCheck = this;

      let cbFailure = function (error) {
      console.log("Audio stream generation failed.");
      avCheck.dataDispatcher.dispatch('audio_stream_error',
        { error: error, service: 'usermedia' });
  };

      let cbSuccess = function (stream) {
        // Create an AudioNode from the stream.
        avCheck.mediaStreamSource = avCheck.audioContext.createMediaStreamSource(stream);

        // Create a new volume meter and connect it.
        avCheck.audioMeter = avCheck.createAudioMeter(avCheck.audioContext);
        avCheck.mediaStreamSource.connect(avCheck.audioMeter);

        // kick off the visual updating
        avCheck.updateAudioBar();
      };

      try {
          navigator.getUserMedia =
            navigator.getUserMedia ||
            navigator.webkitGetUserMedia ||
            navigator.mozGetUserMedia ||
            navigator.msGetUserMedia;

          // ask for an audio input
          navigator.getUserMedia({ "audio": true }, cbSuccess, cbFailure);
      } catch (e) {
        console.log("getUserMedia threw exception :" + e);
        this.dataDispatcher.dispatch('getusermedia_error', { error: e, service: 'usermedia' });
      }
  }

  /*
   * This function creates the audio-meter from the AudioContext.
   *
   * This meter is used only in the audio-video check, not during
   *   actual chat.
   */
  createAudioMeter(audioContext) {
    let processor = audioContext.createScriptProcessor(512);
    processor.onaudioprocess = this.audioEventHandler;
    processor.clipping = false;
    processor.lastClip = 0;
    processor.volume = 0;
    processor.clipLevel =  0.98;
    processor.averaging =  0.95;
    processor.clipLag =  750;

    // this will have no effect, since we don't copy the input to the output,
    // but works around a current Chrome bug.
    processor.connect(audioContext.destination);

     processor.checkClipping = function(){
         if(!this.clipping) {
             return false;
         }
         if((this.lastClip + this.clipLag) < window.performance.now()) {
             this.clipping = false;
         }
         return this.clipping;
     };
    processor.shutdown = function(){
        this.disconnect();
        this.onaudioprocess = null;
    };

    return processor;
  }

  /*
   * This is an event handler, listenning to the MIC activity.
   */
  audioEventHandler(event) {
    var buf = event.inputBuffer.getChannelData(0);
    var bufLength = buf.length;
    var sum = 0;
    var x;

  // Do a root-mean-square on the samples: sum up the squares...
    for (var i=0; i<bufLength; i++) {
        x = buf[i];
        if (Math.abs(x)>=this.clipLevel) {
            this.clipping = true;
            this.lastClip = window.performance.now();
        }
        sum += x * x;
    }

    // ... then take the square root of the sum.
    var rms =  Math.sqrt(sum / bufLength);

    // Now smooth this out with the averaging factor applied
    // to the previous sample - take the max here because we
    // want "fast attack, slow release."
    this.volume = Math.max(rms, this.volume*this.averaging);
  }

  /*
   * Update the audio-bar with real time MIC audio levels.
   */
  updateAudioBar() {
    // clear the background
    this.canvasContext.clearRect(0,0, this.audioBarWidth, this.audioBarHeight);
    this.canvasContext.fillStyle = "green";

    // draw a bar based on the current volume
    this.canvasContext.fillRect(0, 0, this.audioMeter.volume*this.audioBarWidth*1.4, this.audioBarHeight);

    // set up the next visual callback
    this.rafID = window.requestAnimationFrame(this.updateAudioBar);
  }

  attachEventHandlers() {
    let self = this;

    $('.js-chat-widget')
      .on('click', this.ui['openAVCheck'], () => {
        self.startAVCheck();
      });

    $('.js-av-check')
      .on('click', this.ui['AVCheckDone'], function() {
        self.avTestAdapter.cleanUp(
          function() {
            $('.js-av-results-modal').vhlModal('close');
          }
        );
      })

      .on('click', this.ui['runTest'], function() {
        self.runTest();
      });

    $('.js-av-video-summary')
    .on('click', '.js-av-toggle-video-details', function() {
        $('.js-av-video-details').toggleClass('u-hidden');
      });

    $('.js-av-results-modal')
    .on('keyup', function(event) {
        if (event.which === VHL.UI.Keys.ESC) {
        self.avTestAdapter.cleanUp(
          function() {
            $('.js-av-results-modal').vhlModal('close');
          }
        );
        }
     })
     this.bindforMuteButtonAriaState();
  }

  /**
   * Bind event handlers for updating mute button aria state.
   * Handling for keyboard action is not required separately here
   * because those actions are covered by click handler.
   */
  bindforMuteButtonAriaState() {
    const avModal = document.querySelector('.js-av-results-modal');
    avModal.addEventListener('click', (e) => {
      const muteBtn = e.target.closest('.OT_mute');
      if (!muteBtn) return;
      
      this.setMuteButtonAriaState(muteBtn);
    });
  }

  /**
   * Set initial aria-pressed state for mute button based on OT_active css class applied by OpenTok.
   */
  setMuteButtonInitialAriaState() {
    const muteBtn = document.querySelector('.js-av-results-modal .OT_mute');
    if (muteBtn && !muteBtn.hasAttribute('aria-pressed')) {
      this.setMuteButtonAriaState(muteBtn);
    }
  }

  /**
   * Set aria-pressed state for mute button based on OT_active css class applied by OpenTok.
   * This relies upon OT_active css class instead of toggling values ourselves on mouse /kb actions. 
   */
  setMuteButtonAriaState(muteBtn) {
    const bMute = muteBtn.classList.contains('OT_active');
    muteBtn.setAttribute('aria-pressed', String(bMute));
  }

  /**
   * Traps focus within the given modal when Tab is pressed.
   * @param {KeyboardEvent} e
   * @param {HTMLElement} modal
   */
  trapFocus(e, modal) {
    if (e.key === 'Tab') {
      e.preventDefault();
      modal.focus();
    }
  }
};

