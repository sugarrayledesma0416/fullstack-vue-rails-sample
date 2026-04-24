VHL = VHL || {};

class VideoAccessChecker {
  static grabSignedURL(cookieEndpoint, recordingPath) {
    const index = 'vhl-chat-client-cloudfront';
    const dispatcher = new VHL.CarlinDispatch.Logstash(index);
    // We can have three responses from server:
    // 200 OK - User can play recording. Use signed URL from response.
    // 403 UNAUTHORIZED - User does not have permissions to play recording.
    // 422 UNPROCESSABLE ENTITY - Something's wrong with recording path.
    // 500 SERVER ERROR - Something went wrong on the ruby side.
    const promise = new Promise((resolve, reject) => {
      $.ajax({ type: 'POST',
        url: cookieEndpoint,
        cache: false,
        contentType: 'application/json', // by default, POST request sends data as multipart.
        data: JSON.stringify({ recording_path: recordingPath }) // make a valid JSON string to send.
      })
        .done((data) => {
          console.log('New signed URL generated to play recording.');
          resolve(data.video_url); // Send signed URL to resolution.
        })
        .fail((xhr) => {
          console.log('Error occurred:', xhr.statusText);
          let error_info = {
            recordingPath: recordingPath,
            responseText: xhr.responseText,
            statusCode: xhr.status
          };
          dispatcher.dispatch('access_recording_denied',
            { error: error_info, service: 'cloudfront' }
          );
          reject(error_info); // Send error to catch or to the error callback.
        });
    });

    return promise;
  }

  static verifyRecordingPermission(cookieEndpoint, recordingPath) {
    // It checks if current logged in user can access to recording.
    // It tries to play the specified recordingPath.
    // If there's an issue, it will try to retrieve new signed URL from M3 so the user can
    // play the recording with new fresh valid access.

    const promise = new Promise((resolve, reject) => {
      let videoCheck = document.createElement('video');
      videoCheck.type = 'video/mp4';
      videoCheck.muted = true;
      videoCheck.src = recordingPath;

      videoCheck.play().then(() => {
        videoCheck.pause();
        videoCheck = null;
        console.log('User can play recording');
        resolve(); // Resolve promise.
      }).catch(() => {
        console.log('User cannot play video. Trying to retrieve signed URL');

        this.grabSignedURL(cookieEndpoint, recordingPath)
          .then((video_url) => resolve(video_url)) // Resolve promise because we got 200 OK. Send signed URL to resolution.
          .catch((err) => reject(err)); // Reject promise because we did not got a 200 OK from cloudfront.
      }); // On error, try to grab a new signed URL.
    });

    return promise;
  }
}

VHL.VideoAccessChecker = VideoAccessChecker;
