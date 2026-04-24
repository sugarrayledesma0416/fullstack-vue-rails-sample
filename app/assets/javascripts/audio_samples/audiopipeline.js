/* global Logger */

function AudioPipeline(opts) {
  var serverUrl = opts.endpointUrl;
  var logger = opts.logger || new Logger;
  var userId = opts.userId;
  var language = opts.language;

  function onLoad() {
    if (this.readyState === 4) { // request complete
      if (this.status === 200) {
        var json = JSON.parse(this.responseText);
        opts.successCallback && opts.successCallback(json);
      } else {
        opts.failureCallback && opts.failureCallback();
      }
    }
  }

  function onError() {
    opts.failureCallback && opts.failureCallback();
    logger.log('Something went wrong');
  }

  function request(xhr, url) {
    if (xhr) {
      xhr.open('GET', serverUrl + url);
      xhr.addEventListener('load', onLoad);
      xhr.onerror = onError;
      xhr.send();
    }
  }

  function getTask(successCallback) {
    var xhr = new XMLHttpRequest();
    request(xhr, 'task_for_user?user_id=' + userId + "&language=" + language, successCallback);
  }

  function hasEnoughSamples(successCallback) {
    var xhr = new XMLHttpRequest();
    request(xhr, 'enough_samples', successCallback);
  }

  function hasEnoughSamplesFromUser(successCallback) {
    var xhr = new XMLHttpRequest();
    request(xhr, 'enough_samples_from_user?user_id=' + userId + "&language=" + language, successCallback);
  }

  return {
    getTask: getTask,
    hasEnoughSamples: hasEnoughSamples,
    hasEnoughSamplesFromUser: hasEnoughSamplesFromUser,
  };
}
