function streamAudioUploader(opts) {
  return {
    upload: function upload(data) {
      return new Promise(function(resolve, reject){
        var xhr = new XMLHttpRequest();
        if (xhr) {
          if (opts.url) {
            xhr.open('POST', opts.url, true);
            xhr.onreadystatechange = onCompletion;
            xhr.send(data);
          } else {
            reject(Error('No POST URL provided'));
          }
        }

        function onCompletion(statusEvent) {
          var xhr = statusEvent.target;
          if (xhr.readyState === 4) { // request complete
            if (xhr.status === 200) {
              opts.successCallback && opts.successCallback();
              resolve(xhr.responseText);
              console.log('You have successfully uploaded your recording');
            } else {
              reject(Error('upload failed'));
            }
          }
        }
      });
    }
  };
}
