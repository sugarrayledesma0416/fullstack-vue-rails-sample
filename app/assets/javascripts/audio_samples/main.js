/* global Logger, AudioUploader, MetaDataUpdater, StreamRecorder */

var VHLRecorder = (function() {
  // constants - should not be mutated
  var TOTAL_WORDS = 24;
  var CYGNUS_URL = VHL.CygnusConfig.audioEndpoint;

  // user-interface elements
  var recordingContainer = $('#recording_container');
  var recordingList = $('#recordingslist');
  var recordButton = $('#record');
  recordButton.attr('disabled', true);
  var stopButton = $('#stop');
  var submitButton = $('#upload');
  var nextButton = $('#next_word');
  var wordDataContainer = $('#words');

  // data from dom
  var wordsToRecord = [];
  var recordingTask = null;
  var recordedWordCount = wordDataContainer.data('recorded-word-count');
  var csrfToken = $("meta[name='csrf-token']").attr('content');
  var userId = $("meta[name='VHL.user_id']").attr('content');
  var userEmail = wordDataContainer.data('user-email');
  var userFirstName = wordDataContainer.data('user-first');
  var userLastName = wordDataContainer.data('user-last');
  var language = wordDataContainer.data('language');

  var currentTarget;

  // cygnus interface variables
  var logger = new Logger('#log');
  var currentAudioBlob = null;
  var recorder;
  var audioUploader;
  var metaDataUpdater;
  var audioPipeline;
  var enoughSamples = null;
  var enoughSamplesFromUser = null;

  // constants - should not be mutated
  function onUploadFailure() {
    recorder.clear(function() {
      recordButton.attr('disabled', false);
      recordingList.html('');
    });
  }

  function successfullUpload() {
    getNextWord();
  }

  function updateProgress() {
    $('#words_done').html(recordedWordCount + ' / ' + TOTAL_WORDS);
  }

  function incrementWordsDone() {
    currentTarget.done = true;
    recordedWordCount++;
    updateProgress();
  }

  function updateUI(blob) {
    var url = URL.createObjectURL(blob);
    var li = document.createElement('li');
    var au = document.createElement('audio');
    au.controls = true;
    au.src = url;
    li.appendChild(au);
    recordingList.html(li);
  }

  function startRecording(button) {
    recorder.startRecording(function() {
      button.disabled = true;
      button.nextElementSibling.disabled = false;
    });
  }

  function stopRecording(button) {
    recorder.stopRecording(function(audio_data) {
      button.disabled = true;
      button.previousElementSibling.disabled = false;
      submitButton.attr('disabled', false);
      if (audio_data.type && audio_data.type === "lossless") {
        var blob = audio_data.blob;
        currentAudioBlob = blob;
        updateUI(blob);
      }
    });
  }

  function submitRecording(button) {
    recordButton.attr('disabled', true);
    audioUploader.upload(currentAudioBlob, currentTarget.term);
    recorder.clear();
    button.disabled = true;
    $('#current_word').css('display', 'none');
    $('#prompt').css('display', 'none');
  }

  function getNextWord() {
    recordButton.attr('disabled', true);

    if (wordsToRecord.length === 0) {
      recordingContainer.html('Thank you for participating in Project George!');
      return 0;
    }

    currentTarget = wordsToRecord.shift();
    // $('#current_audio').attr('src', currentTarget.audio_file);
    $('#current_word span').text(currentTarget.term);
    $('#current_word').css('display', 'block');
    $('#prompt').css('display', 'none');
    recordButton.attr('disabled', false);
  }

  function init() {

    recorder = new StreamRecorder({
      logger: logger
    });

    audioUploader = new AudioUploader({
      endpointUrl: CYGNUS_URL,
      userId: userId,
      userEmail: userEmail,
      userFirstName: userFirstName,
      userLastName: userLastName,
      logger: logger,
      failureCallback: onUploadFailure,
      successCallback: successfullUpload,
    });

    audiopipeline = new AudioPipeline({
      endpointUrl: CYGNUS_URL,
      userId: userId,
      language: language,
      logger: logger,
      successCallback: function (responseText) {
        recordingTask = responseText['task'];
        wordsToRecord = responseText['terms'];
      },
    }).getTask();

    updateProgress();

    if (recordedWordCount >= TOTAL_WORDS) {
      recordingContainer.html('Thank you for participating on Project George!');
      return 0;
    }

    nextButton.click(function() {
      getNextWord();
    });

    recordButton.click(function() {
      startRecording(this);
    });

    stopButton.click(function() {
      stopRecording(this);
    });

    submitButton.click(function() {
      submitRecording(this);
    });

    var intervalId;
    intervalId = setInterval(function () {
      if ($('#log').html().indexOf('Recorder initialised') >= 0 && recordingTask != null) {
        getNextWord();
        clearInterval(intervalId);
      }
    }, 150);
  }

  function availability() {
    new AudioPipeline({
      endpointUrl: CYGNUS_URL,
      userId: userId,
      logger: logger,
      language: language,
      successCallback: function (response) {
        enoughSamples = response;
      },
    }).hasEnoughSamples();


    new AudioPipeline({
      endpointUrl: CYGNUS_URL,
      userId: userId,
      logger: logger,
      language: language,
      successCallback: function (response) {
        enoughSamplesFromUser = response;
      },
    }).hasEnoughSamplesFromUser();

    var intervalId = setInterval(function() {
      if(enoughSamples != null && enoughSamplesFromUser != null) {
        clearInterval(intervalId);

        if(enoughSamples) {
          recordingContainer.html($('#project_george_closed').html());
        }
        if(enoughSamplesFromUser){
          recordingContainer.html($('#thank_you_for_participation').html());
        }
      }
    }, 150);
  }

  return {
    init: init,
    availability: availability,
  };
})();

$(document).ready(function() {
  VHLRecorder.availability()
});

$('#start_activity').click(function(evt) {
  $('#user-recording-section').css('visibility', 'visible');
  VHLRecorder.init();
  $(this).css('visibility', 'hidden');
});
