var VHL = VHL || {}; //Standard VHL namespace
VHL.Msg = VHL.Msg || {}; //New Msg (sub-namespace) to avoid collision with existing/previous version.
VHL.Msg.SessionStorage = VHL.Msg.SessionStorage || {};

VHL.Msg.SessionStorage.ErrorTypes = {
    "SET_SESSION_DATA_FAILED": "SET_SESSION_DATA_FAILED",
    "GET_SESSION_DATA_FAILED": "GET_SESSION_DATA_FAILED",
    "REMOVE_SESSION_DATA_FAILED": "REMOVE_SESSION_DATA_FAILED"
};

VHL.Msg.SessionStorage.Manager = (function () {
    var _sessionStorageKey = "VHL.Msg.ClientWrapper.Session";

    /**
     * Function to check if the session storage supported by browser.
     */
    var __isSessionStorageSupported = function() {
        return (typeof(Storage) !== "undefined");
    };

    /**
     * Function to store data in session storage
     */
    var __setData = function(data) {
        if (__isSessionStorageSupported()) { // Web storage supported by browser.
            sessionStorage.setItem(_sessionStorageKey,
                                               JSON.stringify(data));
            return { "error": false };
        } else { // No Web Storage support.
            return {
                "error": true,
                "code": VHL.Msg.SessionStorage.ErrorTypes.SET_SESSION_DATA_FAILED,
                "message": "Web storage not supported by browser"
            };
        }
    };

    /**
     * Function to get data from session storage
     */
    var __getData = function() {
        if (__isSessionStorageSupported()) { // Web storage supported by browser.
            var sessionStorageData = JSON.parse(sessionStorage.getItem(_sessionStorageKey));
            if(sessionStorageData) {
                return {
                    "error": false,
                    "data": sessionStorageData
                };
            } else {
                return {
                    "error": true,
                    "code": VHL.Msg.SessionStorage.ErrorTypes.GET_SESSION_DATA_FAILED,
                    "message": "No data found in browser sessionStorage."
                };
            }
        } else { // No Web Storage support.
            return {
                "error": true,
                "code": VHL.Msg.SessionStorage.ErrorTypes.GET_SESSION_DATA_FAILED,
                "message": "Web storage not supported by browser"
            };
        }
    };

    /**
     * Function to remove data from session storage
     */
    var __removeData = function() {
        if (__isSessionStorageSupported()) { // Web storage supported by browser.
            sessionStorage.removeItem(_sessionStorageKey);
            return { "error": false };
        } else { // No Web Storage support.
            return {
               "error": true,
                "code": VHL.Msg.SessionStorage.ErrorTypes.REMOVE_SESSION_DATA_FAILED,
                "message": "Web storage not supported by browser"
            };
        }
    };

    return {
        "setData": __setData,
        "getData": __getData,
        "removeData": __removeData,
        "isSessionStorageSupported" : __isSessionStorageSupported
    };
}) ();

var VHL = VHL || {};
VHL.Msg = VHL.Msg || {};

/**
 * Log Level module.
 * Purpose - Serves as a pseudo enum (list) of log levels.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.LogLevels = (function () {
    "use strict";
    return {
        "DEBUG": "debug",
        "INFO": "info",
        "WARN": "warn",
        "ERROR": "error"
    };
}) ();

/**
 * LOGGER
 * Logger provide the following capabilities:
 * (1) Centralize logging; send to browser console or an API
 * (2) Manage Log levels -  DEBUG, ERROR, ETC
 * (3) Inject Context - Add additional context data automatically (session id)
 *
 * USAGE:
 * var myLogger = VHL.Msg.Logger(options);
 * myLogger.info("foo log me");
 *
 */
VHL.Msg.Logger = function(options) {

    if (typeof _ !== "function") {
        console.log("Underscore not available. Exiting");
        return;
    }        

    // Array of supported logger level in the order of there priority.
    var supportedLevels = [
        VHL.Msg.LogLevels.DEBUG,
        VHL.Msg.LogLevels.INFO,
        VHL.Msg.LogLevels.WARN,
        VHL.Msg.LogLevels.ERROR
    ];

    /**
     * Initialization validations
     */
    if(options.level) {
        if(supportedLevels.indexOf(options.level) === -1) {
            /**
             * Level provided by user is not supported.
             * Return null
             */
            console.log(options.level + " is not a supported. Supported levels are : " +
                        supportedLevels);
            return null;
        }
    } else {
        options.level = VHL.Msg.LogLevels.DEBUG; // Setting default level "debug".
    }

    /* ====== Private Methods */
    /**
     * This function is used get the selected log level of the logger.
     */
    var _getLogLevel = function() { return options.level; };

    /**
     * This function is used get the static log context.
     */
    var _getLogContext = function() { return options.context || {}; };

    /**
     * This function returns a formated date string
     * Format - (MMM DD  hh : mm : ss)
     */
    var _getFormatedDate = function() {
        var date = new Date();
        var locale = "en-us";
        var options = { // Setting date format - (MMM DD  hh : mm : ss)
            month: "short", day: "2-digit", hour: "2-digit",
            minute: "2-digit", second: "2-digit"
        };
        return date.toLocaleString(locale, options);
    };

    /**
     * This function performs the logging. By default the function logs to the console.
     * Log String - (MMM DD  hh : mm : ss) [(optional) data - key/value pair)] - [Log message]
     *              { optional data } - This will "pretty" formatted object
     */
    var _log = function(level, options) {
        var logString = _getFormatedDate(); // Added date to logString
        logString += " " + level.toUpperCase();

        /**
        * Adding logContext to the logString
        */
        if(!options.context) { options.context = {}; }
        options.context = _.extend(_getLogContext(), options.context);
        for(var key in options.context) {
            // Ading key / value pairs from context
            logString += " " + key.toUpperCase() + ": " + options.context[key];
        }
        logString += " - " + options.message;
        console.log(logString);
        if(options.data) {
            try { // Trying to parse the data object.
                console.log(JSON.stringify(options.data, null, 4)); // Logging data in next line
            } catch(e) { /* Ignore - Error while parsing JSON */ }
        }
    };

    /* ====== Public Methods */
    var __debug = function(options) {
        if(supportedLevels.indexOf(_getLogLevel()) <=
            supportedLevels.indexOf(VHL.Msg.LogLevels.DEBUG))
        { // Current level's priority is less than or equal to debug's priority
            _log(VHL.Msg.LogLevels.DEBUG, options);
        }
    };

    var __info = function(options) {
        if(supportedLevels.indexOf(_getLogLevel()) <=
            supportedLevels.indexOf(VHL.Msg.LogLevels.INFO))
        { // Current level's priority is less than or equal to info's priority
            _log(VHL.Msg.LogLevels.INFO, options);
        }
    };

    var __warn = function(options) {
        if(supportedLevels.indexOf(_getLogLevel()) <=
            supportedLevels.indexOf(VHL.Msg.LogLevels.WARN))
        { // Current level's priority is less than or equal to warn's priority
            _log(VHL.Msg.LogLevels.WARN, options);
        }
    };

    var __error = function(options) {
        if(supportedLevels.indexOf(_getLogLevel()) <=
            supportedLevels.indexOf(VHL.Msg.LogLevels.ERROR))
        { // Current level's priority is less than or equal to error's priority
            _log(VHL.Msg.LogLevels.ERROR, options);
        }
    };

    /**
     * This function can be used to change the logger level.
     * Supported Levels - ['debug', 'info', 'warn', 'error']
     */
    var __setLevel = function(level, cbSuccess, cbFailure) {
        if(supportedLevels.indexOf(level) > -1) {
            options.level = level;
            if(typeof cbSuccess === "function") {
                cbSuccess();
            }
        } else {
            if(typeof cbFailure === "function") {
                cbFailure({
                    "code": "LOGGER_SET_LEVEL",
                    "error": true,
                    "message": "Level: " + level + " is not supported.",
                });
            }
        }
    };


    return {
        "error": __error,
        "warn": __warn,
        "info": __info,
        "debug": __debug,
        "setLevel": __setLevel
    };
};

//Start of filteredcanvas.js
/**
 * Canvas Filter Module.
 * Purpose: Adds the name of the students to their respective videostreams.
 *          Takes the videostream and puts the text over the video as a 
 *          custom filter.
 */

var VHL = VHL || {}; //Standard VHL namespace
VHL.Msg = VHL.Msg || {}; //New Msg (sub-namespace) to avoid collision with existing/previous version.
VHL.Msg.CanvasFilter = class CanvasFilter {
  constructor(studentMediaStream) {    
    this.studentMediaStream = studentMediaStream;
    this.WIDTH = 640;
    this.HEIGHT = 480;
    this.videoEl = document.createElement("video");
    //Main Canvas
    this.canvas = document.createElement("canvas");
    this.ctx = this.canvas.getContext("2d");
    this.canvas.width = this.WIDTH;
    this.canvas.height = this.HEIGHT;
    //Temp Canvas
    this.tmpCanvas = document.createElement("canvas");
    this.tmpCtx = this.tmpCanvas.getContext("2d");
    this.tmpCanvas.width = this.WIDTH;
    this.tmpCanvas.height = this.HEIGHT;
    //Bind drawFrame, addText, addGradient to instance.
    this.drawFrame = this.drawFrame.bind(this);
    this.addText = this.addText.bind(this);
    this.addGradient = this.addGradient.bind(this);
    this.isPortraitVideo = this.isPortraitVideo.bind(this);
   }

  addGradient() {
    let gradient = this.tmpCtx.createLinearGradient(0,this.tmpCanvas.height, 0,this.tmpCanvas.height*0.33);
    gradient.addColorStop(0, 'black');
    gradient.addColorStop(0.15, 'rgba(0,0,0,0.5)');
    gradient.addColorStop(0.25, 'rgba(0,0,0,0)');
    this.tmpCtx.fillStyle = gradient;
    this.tmpCtx.fillRect(0, 0, this.tmpCanvas.width, this.tmpCanvas.height);
  }

  isPortraitVideo() {
    let videoAspectRatio = this.videoEl.videoHeight !== 0 ? this.videoEl.videoWidth/this.videoEl.videoHeight : 0;
    let isPortrait = (videoAspectRatio <= 1) ? true : false;
    return isPortrait;
  }

  addText() {
    let scaledFontSize = 0;
    if (this.isPortraitVideo()) {
      scaledFontSize = this.videoEl.videoWidth !== 0 ? Math.trunc(this.videoEl.videoWidth*0.75*0.1) : 48;
    } else {
      scaledFontSize = this.videoEl.videoHeight !== 0 ? Math.trunc(this.videoEl.videoHeight/10) : 48;
    }
    this.tmpCtx.font = `${scaledFontSize}px Arial`;
    let text_to_show;
    if (VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(VHL.Chat.CONFIG.activityType)) {
      text_to_show = '';
    } else {
      text_to_show = VHL.Chat.CONFIG.session.user.last_name + ", " + VHL.Chat.CONFIG.session.user.first_name;
    }
    this.tmpCtx.fillStyle = "white";
    // Move participant name to top-left to avoid overlapping with control bar background for group chat.
    if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      this.tmpCtx.fillText(text_to_show, scaledFontSize, scaledFontSize);
    } else {
      this.tmpCtx.fillText(text_to_show, scaledFontSize, this.tmpCanvas.height-(scaledFontSize*0.4));
    }
  }

  drawFrame() {
    if (this.isPortraitVideo()) {
      let offsety = Math.trunc((this.videoEl.videoHeight - this.videoEl.videoWidth*0.75)*0.5);
      this.tmpCtx.drawImage(this.videoEl, 0, offsety, this.tmpCanvas.width, this.tmpCanvas.height, 0, 0,this.tmpCanvas.width, this.tmpCanvas.height);
    } else {
      let offset = Math.trunc((this.videoEl.videoWidth - this.tmpCanvas.width)*0.5);
      this.tmpCtx.drawImage(this.videoEl, offset, 0, this.tmpCanvas.width, this.tmpCanvas.height, 0, 0,this.tmpCanvas.width, this.tmpCanvas.height);
    } 
    //Draw background gradient and text.
    this.addGradient();
    this.addText();
    let imgData = this.tmpCtx.getImageData(0, 0, this.tmpCanvas.width, this.tmpCanvas.height);
    // Draw the filtered image data onto the main canvas
    this.ctx.putImageData(imgData, 0, 0);
    this.reqId = requestAnimationFrame(this.drawFrame);
  };

  getFilteredCanvas() {
    this.videoEl.srcObject = this.studentMediaStream;
    this.videoEl.setAttribute("playsinline", "");
    this.videoEl.muted = true;
    setTimeout(() => { this.videoEl.play(); });
    this.videoEl.addEventListener("resize", () => {
      if (this.isPortraitVideo()) {
        this.canvas.width = this.tmpCanvas.width = this.videoEl.videoWidth;
        this.canvas.height = this.tmpCanvas.height = this.videoEl.videoWidth*0.75;
      } else {
        this.canvas.width = this.tmpCanvas.width = Math.trunc(this.videoEl.videoHeight*(4/3));
        this.canvas.height = this.tmpCanvas.height = this.videoEl.videoHeight;
      }
    });

    this.reqId = {};
    // Draw each frame of the video
    this.reqId = requestAnimationFrame(this.drawFrame);

    return {
      canvas: this.canvas,
      stop: () => {
        // Stop the video element, the media stream and the animation frame loop
        this.videoEl.pause();
        if (this.studentMediaStream.stop) {
          this.studentMediaStream.stop();
        }
        if (MediaStreamTrack && MediaStreamTrack.prototype.stop) {
          this.studentMediaStream.getTracks().forEach((track) => { track.stop()  });
        }
        cancelAnimationFrame(reqId);
      }
    };
  };
}

//end of filteredcanvas.js

var VHL = VHL || {};

VHL.Msg = VHL.Msg || {};

VHL.Msg.WebRTC = VHL.Msg.WebRTC || {};

/**
 * Media Client API endpoints.
 * Purpose - These endpoints are used to interact with external media service
 *           providers like Tokbox.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.WebRTC.Endpoints = {
    "START_RECORDING": "/sessions/{{sessionId}}/recordings",
    "STOP_RECORDING": "/sessions/{{sessionId}}/recordings/{{recordingId}}/stop",
    "GET_RECORDING": "/sessions/{{sessionId}}/recordings/{{recordingId}}/status",
    "CREATE_SESSION": "/sessions",
    "CREATE_TOKEN": "/sessions/{{sessionId}}/tokens"
};

if (typeof _ === "function") {
    _.templateSettings = {
        "interpolate": /\{\{(.+?)\}\}/g
    };
}


/**
 * Use this constructor to setup a webRTC session. A webRTC session comprises of a
 * session_id and token.
 * @params config {object} - session specific config.
 *         config.api_key - tokbox api key to initiate a session.
 *         config.session_id - tokbox session_id to join an existing session.
 *         config.my_media_element - DOM id of the div to show own stream
 *         config.partner_media_element - DOM id of the div to show partner stream
 *         config.playback_media_element - DOM id of the div to show recorded stream.
 *         config.media_base_url - Base url of the webRTC endpoints.
 * @params eventHandler {function} - Event handler for communicating with mediastream_manager
 */
VHL.Msg.WebRTC.SessionManager = function (config, eventHandler, cbSuccess, cbFailure) {
    var _session, _subscriber, _publisher, _token, _playbackVideo;
    var _mapRecordings = {},
        _APIKey = config.api_key,
        _sessionId = config.session_id,
        _myMediaElement = config.my_media_element,
        _partnerMediaElement = config.partner_media_element,
        _playbackMediaElement = config.playback_media_element,
        _mediaBaseUrl = config.media_base_url,
        _defaultRecordingPollingInterval = 2000,
        _recordingPollingInterval = config.recording_polling_interval*1000 || _defaultRecordingPollingInterval,
        _defaultRecordingPollingTimeout = 5*60*1000,
        _recordingPollingTimeout = config.recording_polling_timeout*1000 || _defaultRecordingPollingTimeout,
        _audioLevelEvents = false; // default value for listening to audio level events.

    /**
     * PRIVATE LOGGER
     *
     * A wrapper around VHL.Msg.Logger for inject additional
     * context (session data, module-source) into log strings.
     *
     */
    var _log = (function () {
        var _myLogger = VHL.Msg.Logger({
            "level": VHL.Msg.LogLevels.INFO, //GLOBAL LOGGING LEVEL for ClientWrapper
            "context": {
                "type": "MEDIA_CLIENT"
            }
        });

        /**
         * This function calls the VHL Logger instance that was created above.
         */
        function callMyLogger(level, message, sessionId, data) {
            var context = {};
            if (_myLogger[level]) {
                _myLogger[level]({
                    "context": context,
                    "message": message,
                    "data": data
                });
            }
        }

        return {
            "info": function (message, data) {
                callMyLogger(VHL.Msg.LogLevels.INFO, message, data);
            },
            "warn": function (message, data) {
                callMyLogger(VHL.Msg.LogLevels.WARN, message, data);
            },
            "error": function (message, data) {
                callMyLogger(VHL.Msg.LogLevels.ERROR, message, data);
            }
        };
    })();


    /**
     * This hashmap is used to store partner user's media stream.
     */
    var _partnerMediaStream = {
        stream: {}
    };

    /**
     * This hashmap is used to store my media states.
     * This inputs are used to toggle my audio /a video stream while playing recording.
     */
    var _myMediaInputs = {
        hasAudio: true,
        hasVideo: true
    };

    /**
     * Map to store callback references.
     */
    var _mapCallbacks = {};

    /**
     * The eventHandler to communicate back with media stream manager.
     */
    var _externalWebRTCEventHandler = eventHandler;

    /** PRIVATE FUNCTIONS - UTILITY FUNCTIONS TO INTERACT WITH MEDIA SERVER */

    /**
     * This function is used to initialize the playbackMediaElement in the DOM.
     */
    var _initPlaybackUI = function (playbackMediaElement) {
        /**
         * _playbackVideoDOMElements contain all the VIDEO elements inside playback media container.
         * If VIDEO element is not present, then create a new VIDEO element, else delete the existing
         * VIDEO element.
         */
        var _playbackVideoDOMElements = document.getElementById(playbackMediaElement)
                                            .getElementsByTagName("VIDEO");
        if (_playbackVideoDOMElements.length > 0) {
            document.getElementById(playbackMediaElement).removeChild(_playbackVideoDOMElements[0]);
        }
        _playbackVideo = document.createElement("VIDEO");
        _playbackVideo.style.height = "inherit";
        _playbackVideo.style.width = "inherit";
        document.getElementById(playbackMediaElement).appendChild(_playbackVideo);
    };

    /**
     * This function is use to check device status.
     * Currently it only checks for audio device availability.
     * TOKBOX also provides capability to check video device availability.
     */
    var _deviceStatus = function (cbSuccess, cbFailure) {
        OT.getDevices(function (error, devices) { // Calling tokbox SDK
            if (error) {
                cbFailure(error);
            } else {
                var audioInputDevices = devices.filter(function (element) {
                    return element.kind === "audioInput";
                });
                if (audioInputDevices.length) {
                    /**
                     * One or more audio device (microphone) detected.
                     * Permissions for these devices will be checked while publishing audio.
                     */
                    cbSuccess();
                } else {
                    cbFailure("Audio device not found. Please attach audio device.");
                }
            }
        });
    };

    /**
     * This function is used to perform AJAX calls.
     * @params {string} endPoint - AJAX url endpoint.
     * @params {string} method - HTTP request method (GET | PUT | POST | DELETE).
     * @params {object} queryParams - key value pair representing query params.
     * @params {json} body - HTTP request payload.
     * @params {function} cbSuccess - A function that accepts a single argument,
                                      which is a success response to the HTTP call.
     * @params {function} cbFailure - A function that accepts a single argument,
                                      which is a failure response to the HTTP call.
     */
    var _doAJAX = function (endPoint, method, queryParams, body, cbSuccess, cbFailure) {
        var queryString = [];
        if (queryParams) {
            for (var param in queryParams) {
                queryString.push(param + "=" + queryParams[param]);
            }
            queryParams = queryString.join("&");
            endPoint = endPoint + "?" + queryParams;
        }
        var AJAXOptions = {
            dataType: "json",
            contentType: "application/json",
            success: cbSuccess,
            error: cbFailure,
            type: method,
            url: endPoint
        };
        if (method !== "GET") {
            body = body || {};
            AJAXOptions.data = JSON.stringify(body);
        }
        $.ajax(AJAXOptions);
    };

    /**
     * This function is used to create a tokbox session.
     * INVITING USER - A new session_id is created and session is initialized with that id.
     * INVITED USER - INVITING_USER's session_id is used to is initialize the session.
     */
    var _createSession = function (cbSuccess, cbFailure) {
        if (_sessionId) {
            _log.info("Using existing tokbox session: " + _sessionId);
            // in case of user being invited.
            _session = OT.initSession(_APIKey, _sessionId);
            cbSuccess(_session);
        } else {
            // in case, user is inviting.
            _doAJAX(
                _mediaBaseUrl + VHL.Msg.WebRTC.Endpoints.CREATE_SESSION,
                "POST", null, null,
                function success(sessionData) {
                    _sessionId = sessionData.id;
                    _log.info("New tokbox session created: " + _sessionId);
                    _session = OT.initSession(_APIKey, _sessionId);
                    cbSuccess(_session);
                },
                function failure(error) {
                    if (typeof cbFailure === "function") {
                        cbFailure(error);
                    }
                }
            );
        }
    };

    /**
     * This function is used to create a tokbox token for a session.
     */
    var _createToken = function (cbSuccess, cbFailure) {
        var endPoint = _.template(VHL.Msg.WebRTC.Endpoints.CREATE_TOKEN);
        endPoint = endPoint({
            "sessionId": _sessionId
        });
        _doAJAX(
            _mediaBaseUrl + endPoint,
            "POST", null, null,
            function success(tokenData) {
                _token = tokenData.id;
                _log.info("New tokbox token created: " + _token);
                cbSuccess(_token);
            },
            function failure(error) {
                // This call will never return an error, except for Request Time Out.
                if (typeof cbFailure === "function") {
                    cbFailure(error);
                }
            }
        );
    };

    /**
     * This function returns the chat media stream type based on the activity type.
     * @returns {string} chat media stream type
     */
    let _getChatMediaStreamType = function() {
        if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            return VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_MEDIA_STREAM;
        } else {
            return VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_MEDIA_STREAM;
        }
    };

    /**
     * This function is used to get the status of a recording.
     * @params {string} recordingID - unique identifier for a recording.
     *
     * Once a recording is stopped, this function is used to poll the recording
     * status. When status === "available", then a "COMBINE COMPLETED" event is
     * emitted to the mediastream_manager.
     */
    var _getRecording = function (userId, recordingID) {
        if (_mapRecordings[recordingID] && _mapRecordings[recordingID].interval) {
            var endPoint = _.template(VHL.Msg.WebRTC.Endpoints.GET_RECORDING);
            endPoint = endPoint({
                "sessionId": _sessionId,
                "recordingId": recordingID
            });
            _doAJAX(
                _mediaBaseUrl + endPoint,
                "GET", null, null,
                function success(response) {
                    if (_mapRecordings[recordingID] && _mapRecordings[recordingID].interval) {
                        if (response.status === "available") {
                            /**
                             * Recording has been successfully saved on our AWS S3 bucket.
                             * Stopping recording status polling.
                             */
                            clearInterval(_mapRecordings[recordingID].interval);
                            delete _mapRecordings[recordingID].interval;
                            delete _mapRecordings[recordingID].polling_start_time;

                            // Propagating event to mediastream_manager.
                            var recordingAvailableEvent = {
                                "type": _getChatMediaStreamType(),
                                "action": VHL.Msg.MediaStream.Events.Actions.COMBINE_COMPLETED,
                                "mediaStreamData": {
                                    "recording_id": recordingID,
                                    "session_id": _sessionId,
                                    "url": response.path
                                }
                            };
                            _externalWebRTCEventHandler(recordingAvailableEvent);
                        } else if (response.status === "error") {
                            /**
                             * Error occured while saving 'recording' on our secondary AWS S3 bucket.
                             * Stopping recording status polling.
                             */
                            clearInterval(_mapRecordings[recordingID].interval);
                            delete _mapRecordings[recordingID].interval;
                            delete _mapRecordings[recordingID].polling_start_time;

                            // Propagating event to mediastream_manager.
                            var recordingErrorEvent = {
                                "type": _getChatMediaStreamType(),
                                "action": VHL.Msg.MediaStream.Events.Actions.COMBINE_FAILED,
                                "mediaStreamData": {
                                    "recording_id": recordingID,
                                    "session_id": _sessionId
                                }
                            };
                            _externalWebRTCEventHandler(recordingErrorEvent);
                        } else {
                            if(Date.now() - _mapRecordings[recordingID].polling_start_time >
                                                                _recordingPollingTimeout) {
                                /**
                                 * A long time has passed, stopping polling DynamoDB.
                                 */
                                clearInterval(_mapRecordings[recordingID].interval);
                                delete _mapRecordings[recordingID].interval;
                                delete _mapRecordings[recordingID].polling_start_time;

                                // Propagating event to mediastream_manager, if session exists.
                                var recordingPollTimeoutEvent = {
                                    "type": _getChatMediaStreamType(),
                                    "action": VHL.Msg.MediaStream.Events.Actions.COMBINE_POLLING_TIMEOUT,
                                    "mediaStreamData": {
                                        "recording_id": recordingID,
                                        "session_id": _sessionId
                                    }
                                };
                                _externalWebRTCEventHandler(recordingPollTimeoutEvent);
                            }
                        }
                    }
                },
                function error() {
                    /**
                     * IGNORE: Error occured while polling recording status.
                     * Stopping recording status polling.
                     */
                    _log.warn("Error while getting recording status for recordingID: " +
                        recordingID + ". Stopping recording status polling.");
                    clearInterval(_mapRecordings[recordingID].interval);
                    delete _mapRecordings[recordingID].interval;
                    delete _mapRecordings[recordingID].polling_start_time;
                }
            );
        }
    };
  
    /**
     * This function is used to get the user id from an opentok stream event.
     * @returns {string} user id.
     * @params {object} event - tokbox stream event.
     */
    var _getUserIdFromStream = function (event) {
      let metadata = event.stream.connection.data
      return metadata.split(",").pop().replace("user_id=","");
    };

    /**
     * This function is used to setup tokbox session specifc event handlers.
     * (1) streamCreated - This event is emitted when the partner user publishes his stream.
     * (2) archiveStarted - This event is emitted when a recording is started.
     * (3) archiveStopped - This event is emitted when a recording is stopped.
     * (4) streamDestroyed - This event is emitted when a partner user destroys, stops
     *                       publishing his stream.
     */
    var _setupSessionEventHandlers = function () {
        if (_session) {
            _session.on("streamCreated", function (event) {
                /**
                 * Partner user's media stream is created and is published on the session.
                 * Subscribe to the stream if you want play the stream.
                 */
                _partnerMediaStream.stream = event.stream;
                var partnerStreamCreatedEvent = {
                    "type": VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_PAIRING,
                    "action": VHL.Msg.MediaStream.Events.Actions.PARTNER_STREAM_CREATED,
                    "session_id": event.target.sessionId
                };
                _externalWebRTCEventHandler(partnerStreamCreatedEvent);
            });

            _session.on("streamDestroyed", function (event) {
                var streamTerminatedEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.STREAM_TERMINATED,
                    "mediaStreamData": {
                        "session_id": _sessionId
                    }
                };
                if (VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType)) {
                  _hidePlaybackDOM();
                  __endSession();
                } else {
                  let user_id = _getUserIdFromStream(event);
                  streamTerminatedEvent.mediaStreamData.user_id = user_id;
                }
                _externalWebRTCEventHandler(streamTerminatedEvent); 
            });

            _session.on("archiveStarted", function (event) {
                const archiveStartedEvent = {
                    "type": VHL.Msg.MediaStream.Events.Types.ARCHIVE_STARTED,
                    "action": VHL.Msg.MediaStream.Events.Actions.ARCHIVE_STARTED,
                    "session_id": event.target.sessionId
                };
                _externalWebRTCEventHandler(archiveStartedEvent);
            });

            _session.on("archiveStopped", function (event) {
                const archiveStoppedEvent = {
                    "type": VHL.Msg.MediaStream.Events.Types.ARCHIVE_STOPPED,
                    "action": VHL.Msg.MediaStream.Events.Actions.ARCHIVE_STOPPED,
                    "session_id": event.target.sessionId
                };
                _externalWebRTCEventHandler(archiveStoppedEvent);
            });

            _session.on("sessionReconnecting", function (event) {
                var sessionReconnectingEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTING,
                    "mediaStreamData": {
                        "session_id": _sessionId,
                        "event_data": event
                    }
                };
                _externalWebRTCEventHandler(sessionReconnectingEvent);
            });

            _session.on("sessionReconnected", function (event) {
                var sessionReconnectedEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTED,
                    "mediaStreamData": {
                        "session_id": _sessionId,
                        "event_data": event
                    }
                };
                _externalWebRTCEventHandler(sessionReconnectedEvent);
            });

            _session.on("sessionDisconnected", function (event) {
                var sessionDisconnectedEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.SESSION_DISCONNECTED,
                    "mediaStreamData": {
                        "session_id": _sessionId,
                        "event_data": event
                    }
                };
                _hidePlaybackDOM();
                _externalWebRTCEventHandler(sessionDisconnectedEvent);
                __endSession();
            });

            _session.on("exception", function (event) {
                var genericErrorEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.GENERIC_ERROR,
                    "mediaStreamData": {
                        "session_id": _sessionId,
                        "event_data": event
                    }
                };
                _externalWebRTCEventHandler(genericErrorEvent);
            });
        }
    };

    /**
     * This function is used to pause subscription and publishing of a live stream.
     */
    var _pauseLiveStreaming = function () {
        if (_myMediaInputs.hasAudio) {
            _publisher.publishAudio(false);
        }
        if (_myMediaInputs.hasVideo) {
            _publisher.publishVideo(false);
        }
    };

    /**
     * This function is used to resume subscription and publishing of a live stream.
     */
    var _resumeLiveStreaming = function () {
        if (_myMediaInputs.hasAudio) {
            _publisher.publishAudio(true);
        }
        if (_myMediaInputs.hasVideo) {
            _publisher.publishVideo(true);
        }
    };

    /**
     * This function is used to show playback media element and hide live streaming (subscriber
     * and publisher) media elements
     */
    var _showPlaybackDOM = function () {
        document.getElementById(_myMediaElement).style.display = "none";
        document.getElementById(_partnerMediaElement).style.display = "none";
        document.getElementById(_playbackMediaElement).style.display = "block";
    };

    /**
     * This function is used to hide playback media element and show live streaming (subscriber
     * and publisher) media elements
     */
    var _hidePlaybackDOM = function () {
        document.getElementById(_myMediaElement).style.display = "block";
        document.getElementById(_partnerMediaElement).style.display = "block";
        document.getElementById(_playbackMediaElement).style.display = "none";
    };

    /*
     * This function registers all the event handlers associated with an publisher object.
     */
    var _registerPublisherEventHandler = function () {
        if(_audioLevelEvents) {
            _publisher.on("audioLevelUpdated", function(event) {
                var audioLevelUpdatedEvent = {
                    "type": _getChatMediaStreamType(),
                    "action": VHL.Msg.MediaStream.Events.Actions.AUDIO_LEVEL_UPDATED,
                    "session_id": event.target.sessionId,
                    "mediaStreamData": {
                        "audio_level": event.audioLevel
                    }
                };
                _externalWebRTCEventHandler(audioLevelUpdatedEvent);
            });
        }
    };

    /**
     * This function cleans the maps and data.
     * @private
     */
    var _cleanup = function() {
        // Update UI
        _hidePlaybackDOM();

        // Update maps and clear variables
        for(var i in _mapRecordings) {
            if(_mapRecordings[i].interval) {
                clearInterval(_mapRecordings[i].interval);
            }
        }
        _mapRecordings = {};
        _session = undefined;
        _subscriber = undefined;
        _publisher = undefined;
        _token = undefined;
        _playbackVideo = undefined;
    };

    /**
     * This function returns an adapter with functions to interact with media server like Tokbox.
     */
    var _constructWebRTCAdapter = function () {
        return {
            "getSessionMediaData": __getSessionMediaData,
            "publishMyMediaStream": __publishMyMediaStream,
            "playPartnerMediaStream": __playPartnerMediaStream,
            "startRecording": __startRecording,
            "stopRecording": __stopRecording,
            "getRecordingStatus": __getRecordingStatus,
            "endSession": __endSession,
            "startRecordingPlayback": __startRecordingPlayback,
            "stopRecordingPlayback": __stopRecordingPlayback,
            "enableAudio": __enableAudio,
            "enableVideo": __enableVideo
        };
    };

    /** END OF PRIVATE FUNCTIONS */

    /** PUBLIC FUNCTIONS - EXPOSED TO MEDIA STREAM MANAGER VIA WEBRTC ADAPTER */

    /**
     * This function returns the media server session_id and recording data
     */
    var __getSessionMediaData = function () {
        return {
            "session_id": _sessionId,
            "recordings": _mapRecordings
        };
    };


    /**
     * Publishes a given publisher object to the session.
     *
     * @param {Object} publisher - The publisher object to be published.
     * @param {Function} cbSuccess - Callback function to execute upon successful publication.
     * @param {Function} cbFailure - Callback function to execute if there's an error.
     */
    const __publishSession = (publisher, cbSuccess, cbFailure) => {
        _session.publish(publisher, (error) => {
            if (error) {
                return cbFailure(error);
            }
            // storing the default state
            _myMediaInputs.hasAudio = _publisher.stream.hasAudio;
            _myMediaInputs.hasVideo = _publisher.stream.hasVideo;
            // send the final audio / video status which is being published.
            cbSuccess(_publisher.stream.hasAudio, _publisher.stream.hasVideo);
        });
    };

    /**
     * Creates publisher options for OpenTok publisher.
     *
     * @param {MediaStream} mediaStream - The media stream to be used for publishing.
     * @param {boolean} publishAudio - Indicates whether to publish audio.
     * @param {boolean} publishVideo - Indicates whether to publish video.
     * @param {Object} filteredCanvas - The filtered canvas object.
     * @returns {Object} The options object for the publisher.
     */
    const createPublisherOptions = (mediaStream, publishAudio, publishVideo, filteredCanvas) => ({
        insertMode: "append",
        width: "100%",
        height: "100%",
        name: VHL.Chat.CONFIG.session.user.first_name || '',
        publishAudio,
        publishVideo,
        videoSource: filteredCanvas.canvas.captureStream(30).getVideoTracks()[0],
        audioSource: mediaStream ? mediaStream.getAudioTracks()[0] : true,
        style: {
            buttonDisplayMode: "off",
            audioLevelDisplayMode: "off",
        }
    });

    /**
     * Initializes a publisher object with given media stream and publish options, and then publishes it.
     *
     * @param {MediaStream} mediaStream - The media stream to be used for publishing.
     * @param {boolean} publishAudio - Indicates whether to publish audio.
     * @param {boolean} publishVideo - Indicates whether to publish video.
     * @param {Function} cbSuccess - Callback function to execute upon successful initialization and publication.
     * @param {Function} cbFailure - Callback function to execute if there's an error.
     */
    const __initPublisher = (mediaStream, publishAudio, publishVideo, cbSuccess, cbFailure) => {
        const canvasFilter = new VHL.Msg.CanvasFilter(mediaStream);
        const filteredCanvas = canvasFilter.getFilteredCanvas();
        const publishOptions = createPublisherOptions(mediaStream, publishAudio, publishVideo, filteredCanvas);

        const publisher = OT.initPublisher(_myMediaElement, publishOptions, (error) => {
            if (error) {
                return cbFailure(error);
            }
            _publisher = publisher;
            __publishSession(publisher, cbSuccess, cbFailure);
            _registerPublisherEventHandler();
            publisher.on("destroyed", () => filteredCanvas.stop());
            publisher.on("streamCreated", () => {
                publisher.element.dataset.streamCreated = true;
            });
        });
        publisher.on('videoElementCreated', (event) => {
            event.element.setAttribute('aria-label', 'Your camera feed');
        });
    };

    /**
     * This function is used to publish my own stream. audio and video (if available),
     * is attached to the tokbox stream and published to tokbox for routing to the partner user.
     *
     * It also shows the stream on _myMediaElement.
     * @params {boolean} bShow - A flag to show / hide my media stream.
     * @params {object} options - width and height of my media stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the stream publish
                                      is started.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __publishMyMediaStream = function (bShow, options, cbSuccess, cbFailure) {
        var width = "100%",
            height = "100%",
            // default preference for audio, if not passed from custom js
            publishAudio = true,
            // default preference for video, if not passed from custom js
            publishVideo = true;
        if(options) {
            if(options.enable_audio !== undefined && options.enable_audio !== null) {
                publishAudio = options.enable_audio;
            }
            if(options.enable_video !== undefined && options.enable_video !== null) {
                publishVideo = options.enable_video;
            }
            if(options.audio_level_events !== undefined && options.audio_level_events !== null) {
                _audioLevelEvents = options.audio_level_events;
            }
            if(options.height) { height = options.height; }
            if(options.width) { width = options.width; }
        }

        if(bShow) {
            if(!_publisher) {
              OT.getUserMedia().then((studentMediaStream) => {
                __initPublisher(studentMediaStream, publishAudio, publishVideo, cbSuccess, cbFailure);
            }).catch(() => {
              if(VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(VHL.Chat.CONFIG.activityType)) {
                __initPublisher(null, publishAudio, publishVideo, cbSuccess, cbFailure);
              }
            });
            } else {
                _publisher.publishAudio(true);
                _publisher.publishVideo(true);
            }
        } else {
            // Hide my stream
            _publisher.publishAudio(false);
            _publisher.publishVideo(false);
        }
    };

    /**
     * This function is used to play / subscribe to partner's stream.
     *
     * It also shows the stream on _partnerMediaElement.
     * @params {object} options - width and height of the partner's media stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the stream publish
                                      is started.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __playPartnerMediaStream = function (options, cbSuccess, cbFailure) {
        var width = "100%",
            height = "100%";
        if(options) {
            width = options.width || width;
            height = options.height || height;
        }
        var subscriberOptions = {
            insertMode: "append",
            width: width,
            height: height,
            style: {
                buttonDisplayMode: "off",
                audioLevelDisplayMode: "off",
                videoDisabledDisplayMode: "off"
            }
        };
        if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
          for (let i = 1; i <= 5; ++i) {
            var partner_video_container = document.querySelector(`#${_partnerMediaElement}-${i}[data-available="true"]`);
            if (partner_video_container !== null) {
              partner_video_container.dataset.available = false;
              break; 
            }
          }
        } else {
          subscriberOptions.fitMode = "contain";
          var partner_video_container = _partnerMediaElement;
        }
        if(_partnerMediaStream.stream) {
            var subscriber = _session.subscribe(
                _partnerMediaStream.stream,
                partner_video_container,
                subscriberOptions,
                function (error) {
                    if (error) {
                        cbFailure(error);
                    } else {
                        _subscriber = subscriber;
                        subscriber.on('videoElementCreated', function (event) {
                            const participantName = (event.target && event.target.stream && event.target.stream.name) || 'Other Participant';
                            event.element.setAttribute('aria-label', `${participantName}'s camera feed`);
                        });
                        done();
                    }
                }
            );
        }

        function done() {
            cbSuccess(subscriber);
        }
    };

    /**
     * This function is used to start recording of a live stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the recording
                                      is started.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __startRecording = function (startRecordingOptions, cbSuccess, cbFailure) {
        var endPoint = _.template(VHL.Msg.WebRTC.Endpoints.START_RECORDING);
        endPoint = endPoint({
            "sessionId": _sessionId
        });
        _doAJAX(
            _mediaBaseUrl + endPoint,
            "POST", null, startRecordingOptions,
            function(response) {
               cbSuccess(response.id);
            }, cbFailure
        );
    };

    /**
     * This function is used to start recording of a live stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the recording
                                      is stopped.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __stopRecording = function (recordingId, cbSuccess, cbFailure) {
        var endPoint = _.template(VHL.Msg.WebRTC.Endpoints.STOP_RECORDING);
        endPoint = endPoint({
            "sessionId": _sessionId,
            "recordingId": recordingId
        });
        _doAJAX(
            _mediaBaseUrl + endPoint,
            "POST", null, null,
            cbSuccess, cbFailure
        );
    };

    /**
     * This function is used to start polling DynamoDB to fetch the url-paths of the recordings.
     */
    var __getRecordingStatus = function(userId, recordingId) {
        if (!_mapRecordings[recordingId]) {
            _mapRecordings[recordingId] = {};
            _mapRecordings[recordingId].polling_start_time = Date.now();
            _mapRecordings[recordingId].interval =
                setInterval(function () {
                    _getRecording(userId, recordingId);
                }, _recordingPollingInterval);
        }
    };

    /**
     * This function is used to end a tokbox session and disconnect all the published and
     * subscribed streams.
     */
    var __endSession = function () {
        if (_session) {
            _log.info("Disconnecting user from tokbox session");
            _session.disconnect();
            // clean up the maps and data stored for this session.
            _cleanup();
        }
    };

    /**
     * This method enables the submit button on chat activities for non-practice usecase.
     */
    const enableSubmit = () => {
        const practiceField = document.querySelector('#practice');
        if (practiceField && practiceField.value === 'yes') return;

        const submitBtn = document.querySelector('.js-activity-submit');
        if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.classList.remove('is-disabled');
        }
    };

    /**
     * This function is used to play a recorded stream.
     * @params {string} recordingId - A unique identifier for a recording.
     *
     * A "RECORDING_PLAYBACK_COMPLETE" event is emitted when playback is
     * completed and is not stopped by me.
     */
    var __startRecordingPlayback = function (recordingUrl, cbSuccess, cbFailure) {
        _initPlaybackUI(_playbackMediaElement);
        _showPlaybackDOM();
        _pauseLiveStreaming();
        _playbackVideo.onloadeddata = function () {
            _playbackVideo.play()
            .then(function() {
                cbSuccess();
            })
            .catch(function(error) {
                _resumeLiveStreaming();
                _hidePlaybackDOM();
                cbFailure(error);
            });
        };
        _playbackVideo.onended = function () {
            enableSubmit();
            _resumeLiveStreaming();
            _hidePlaybackDOM();
            var recordingPlaybackCompleteEvent = {
                "type": _getChatMediaStreamType(),
                "action": VHL.Msg.MediaStream.Events.Actions.RECORDING_PLAYBACK_COMPLETE,
                "mediaStreamData": {
                    "session_id": _sessionId
                }
            };
            _externalWebRTCEventHandler(recordingPlaybackCompleteEvent);
        };
        var errorHandler = function(err) {
            _resumeLiveStreaming();
            _hidePlaybackDOM();
            cbFailure(err);
        };
        _playbackVideo.addEventListener("error", errorHandler);
        _playbackVideo.setAttribute('playsinline', '');
        _playbackVideo.setAttribute('webkit-playsinline', '');
        _playbackVideo.autoplay = true;
        _playbackVideo.src = recordingUrl + '#t=0.001';
    };

    /**
     * This function is used to stop a recording stream playback and resume the live streaming.
     */
    var __stopRecordingPlayback = function () {
        if(_playbackVideo) {
            _playbackVideo.pause();
        }
        _resumeLiveStreaming();
        _hidePlaybackDOM();
    };

    /**
    * This function is used to mute / unmute the audio while live streaming.
    */
    var __enableAudio = function(enableAudio) {
        _publisher.publishAudio(enableAudio);
        _myMediaInputs.hasAudio = enableAudio;
    };

    /**
    * This function is used to pause / unpause the video while live streaming.
    */
    var __enableVideo = function(enableVideo) {
        _publisher.publishVideo(enableVideo);
        _myMediaInputs.hasVideo = enableVideo;
    };

    /** END OF PUBLIC FUNCTIONS */


    _deviceStatus(
        function deviceStatusSuccess() { // Audio devices found
            _createSession(
                function createSessionSuccess(session) { // Tokbox session instantiated.
                    _createToken(
                        function createTokenSuccess(token) { // Tokbox token created.
                            _setupSessionEventHandlers();
                            /**
                             * Connecting user to the tokbox session.
                             * Tokbox token is used to connect a user to a tokbox session
                             * for publishing / subscribing to audio and video streams.
                             */
                            session.connect(token, function (error) {
                                if (error) {
                                    // Calling VHL.Msg.WebRTC.SessionManager's failure callback
                                    cbFailure(error);
                                } else {
                                    // Calling VHL.Msg.WebRTC.SessionManager's success callback
                                    cbSuccess(_constructWebRTCAdapter());
                                }
                            });
                        },
                        cbFailure // VHL.Msg.WebRTC.SessionManager's failure callback
                    );
                },
                cbFailure // VHL.Msg.WebRTC.SessionManager's failure callback
            );
        },
        cbFailure // VHL.Msg.WebRTC.SessionManager's failure callback
    );
};

var VHL = VHL || {};
VHL.Msg = VHL.Msg || {};
VHL.Msg.MediaStream = VHL.Msg.MediaStream || {};
VHL.Msg.MediaStream.Mocks = VHL.Msg.MediaStream.Mocks || {};


/**
 * MediaStreamWrapper module.
 * Purpose -  Wrapper around the Media Stream Providers like TokBox - WebRTC. Abstracts the
 * provider/vendor (TokBox) specific implementation details.
 *
 * USAGE:
 * var myHandler = function(){
 *    ------
 *    ------
 * }
 * var mockMEDIASERVER = VHL.Msg.MediaStream.Mocks.MediaServer(config);
 * mockMEDIASERVER.playPartnerMediaStream(); *
 *
 */
VHL.Msg.MediaStream.Mocks.MediaServer = function (config) {
    "use strict";

    /** ====== DEPENDENCY CHECKS */
    if (typeof _ !== "function") {
        console.log("Underscore not available. Exiting");
        return;
    }

    /**
     * PRIVATE LOGGER
     *
     * A wrapper around VHL.Msg.Logger for inject additional
     * context (session data, module-source) into log strings.
     *
     */
    var _log = (function() {
        var _myLogger = VHL.Msg.Logger({
            "level": VHL.Msg.LogLevels.INFO, //GLOBAL LOGGING LEVEL for Media Server Mock
            "context": {
                "type": "MEDIASERVER_MOCK"
            }
        });

        /**
         * This function calls the VHL Logger instance that was created above.
         */
        function callMyLogger(level, message, sessionId, data) {
            var context = {};
            if(sessionId) { context.session_id = sessionId; }
            if(_myLogger[level]) {
                _myLogger[level]({ "context": context, "message": message, "data": data });
            }
        }

        return {
            "info": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.INFO, message, sessionId, data);
            },
            "warn": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.WARN, message, sessionId, data);
            },
            "error": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.ERROR, message, sessionId, data);
            }
        };
    }) ();

    /**
     * This function creates & return a media server sessionID.
     * e.g. "sessionID" = <base-16 random string>-<base-16 random string>
     */
    var _createSessionID = function() {
        var sessionID = Math.random().toString(16).substr(2) + "-" +
                         Math.random().toString(16).substr(2);
        return sessionID;
    };

    /**
     * This function creates & return "token" - A token to access the stream.
     * e.g. "token" = <base-16 random string>-<base-16 random string>
     */
    var _createToken = function() {
        var token = Math.random().toString(16).substr(2) + "-" +
                        Math.random().toString(16).substr(2);
        return token;
    };

    var _sessionId = config.session_id || _createSessionID(),
        _token = config.token || _createToken();

    /** ====== MediaServer Mock Member functions ==> Mapped to Public Methods */

    /**
     * This function returns the media server session_id
     */
    var __getSessionMediaData = function() {
        return {
            "session_id": _sessionId
        };
    };

    /**
     * This function is used to play / subscribe to partner's stream.
     *
     * @params {object} options - width and height of the partner's media stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the stream publish
                                      is started.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __playPartnerMediaStream = function(options, cbSuccess, cbFailure) {
        _log.info("Inside __pairChat function", _sessionId);
        cbSuccess();
    };

    /**
     * This function is used to publish my own stream. audio and video (if available),
     * @params {boolean} bShow - A flag to show / hide my media stream.
     * @params {object} options - width and height of my media stream.
     * @params {function} cbSuccess - (Optional) A function that is called when the stream publish
                                      is started.
     * @params {function} cbFailure - (Optional) A function that accepts a single argument,
                                      error object with statusCode and relavent message.
     */
    var __publishMyMediaStream = function(bShow, options, cbSuccess, cbFailure) {
        _log.info("Inside publishMyMediaStream function");
        cbSuccess();
    };

    /**
     * This function is used to terminate the on going partner chat session.
     */
    var __endSession = function() {
        _log.info("Inside endSession function");
        _log.info("Partner chat with sessionid - " + _sessionId + " is terminated.");
    };

    return { // Return MEDIA SERVER Mock public methods.
        "getSessionMediaData": __getSessionMediaData,
        "publishMyMediaStream": __publishMyMediaStream,
        "playPartnerMediaStream": __playPartnerMediaStream,
        "endSession": __endSession
    };
};

var VHL = VHL || {};
VHL.Msg = VHL.Msg || {};
// New MediaStream (sub-namespace) to avoid collision with existing version.
VHL.Msg.MediaStream = VHL.Msg.MediaStream || {};

/**
 * MediaStream Modes module.
 * Purpose - Serves as a pseudo enum (list) of modes in which the media stream manager works.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.MediaStream.Modes = (function () {
    "use strict";

    return {
        "MEDIASERVER": "MEDIASERVER",
        "MOCK_MEDIASERVER": "MOCK_MEDIASERVER"
    };
})();

/**
 * MediaStream Events.
 * 
 * Purpose - Serves as a pseudo enum (list) of event types and actions that are emitted by
 * the MediaStreamManager module (see next).
 *
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.MediaStream.Events = (function () {
    "use strict";

    return {
        "Types": {
            "PARTNER_CHAT_MEDIA_STREAM": "PARTNER_CHAT_MEDIA_STREAM",
            "GROUP_CHAT_MEDIA_STREAM": "GROUP_CHAT_MEDIA_STREAM",
            "PARTNER_CHAT_PAIRING": "PARTNER_CHAT_PAIRING",
            "GROUP_CHAT_PAIRING": "GROUP_CHAT_PAIRING",
            "ARCHIVE_STARTED": "ARCHIVE_STARTED",
            "ARCHIVE_STOPPED": "ARCHIVE_STOPPED"
        },
        "Actions": {
            "PARTNER_STREAM_CREATED": "PARTNER_STREAM_CREATED",
            "RECORDING_STARTED": "RECORDING_STARTED",
            "RECORDING_STOPPED": "RECORDING_STOPPED",
            "COMBINE_COMPLETED": "COMBINE_COMPLETED",
            "COMBINE_FAILED": "COMBINE_FAILED",
            "STREAM_TERMINATED": "STREAM_TERMINATED",
            "RECORDING_PLAYBACK_COMPLETE": "RECORDING_PLAYBACK_COMPLETE",
            "AUDIO_LEVEL_UPDATED": "AUDIO_LEVEL_UPDATED",
            "SESSION_RECONNECTING": "SESSION_RECONNECTING",
            "SESSION_RECONNECTED": "SESSION_RECONNECTED",
            "SESSION_DISCONNECTED": "SESSION_DISCONNECTED",
            "GENERIC_ERROR": "GENERIC_ERROR"
        }
    };
})();

/**
 * MediaStreamManager module.
 * Purpose -  Manages interface Media Stream Providers like WebRTC.
 * 
 * Core functions
 * (1) Create Video & Audio stream for sharing with partner
 * (2) Playback partner stream (alongwith my stream)
 * (3) Initiate Recording and related functions.
 * 
 * "ClientWrapper Partner Session" vs "MediaStream Manager"
 * 
 * ClientWrapper Partner Session - A clientwrapper Partner Session object, uses MediaStreamManager
 * for AUDIO/VIDEO collaboration features.
 * 
 * MediaStreamManager - Abstracts the provider/vendor (TokBox - WebRTC) specific
 * implementation details. It defers actual stream creation/playback/recording to TokBox or other
 * similar sub-systems. It support TWO modes
 * A: MEDIASERVER
 * B: MOCK_MEDIASERVER (DEFAULT)
 * 
 * ======================
 * MODE A | MEDIASERVER
 * ======================
 * In this case MediaStreamManager expects a WebRTC session manager with the standard
 * functions, for e.g.
 *  (1) publishMyMediaStream
 *  (2) startRecording
 *
 * For a complete list functions see -
 * {URL}
 * 
 * ======================
 * MODE B | MOCK_MEDIASERVER
 * ======================
 * In this case MediaStreamManager uses a MOCK Javascript module to simulate TokBox or similar
 * streaming sub-system. This is used for debugging and/or unit tests (TBD) 
 * 
 * 
 * USAGE:
 * var myMediaStreamEvents = function() {...};
 * var option = {...};
 * 
 * var myStreamMgr = VHL.Msg.MediaStream.MediaStreamManager(myMediaStreamEvents, options);
 * myStreamMgr.createMediaStream();
 * 
 * 
 */
VHL.Msg.MediaStream.MediaStreamManager = function(sessionID, eventHandler, mediaOptions) {
    "use strict";
    /** ====== DEPENDENCY CHECKS */
    if (typeof _ !== "function") {
        console.log("Underscore not available. Exiting");
        return;
    }

    /** ====== MODULE GLOBALS */
    /**
     * Current MODE 
     * Possible values - [MEDIASERVER, MOCK_MEDIASERVER]
     * Default value - MEDIASERVER
     */
    var _mode = VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER; //MEDIASERVER | MOCK_MEDIASERVER

    var _webRTCAdapter;

    /**
     * This is ONLY used when mode==MOCK_MEDIASERVER
     */
    var _mediaServerMock; // An object that contains functions simulating TokBox

    /**
     * Media Stream Manager event handler as received during
     * mediaStreamManager initialization.
     * 
     * Used to communicate back Media events to the caller (Partner Session Adapter)
     * See VHL.Msg.MediaStream.Events ...
     */
    var _externalMediaStreamEventHandler;


    /**
     * CALLBACK FOR receiving EVENTs "originating" from inside the media-client
     * javascript file (or the MOCK)
     */
    var _webRTCEventHandler = function(event) {
        switch(event.type) {
            case VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_MEDIA_STREAM:
            case VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_MEDIA_STREAM:
                switch(event.action) {
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_COMPLETED:
                    case VHL.Msg.MediaStream.Events.Actions.STREAM_TERMINATED:
                    case VHL.Msg.MediaStream.Events.Actions.RECORDING_PLAYBACK_COMPLETE:
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_FAILED:
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_POLLING_TIMEOUT:
                    case VHL.Msg.MediaStream.Events.Actions.AUDIO_LEVEL_UPDATED:
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTING:
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTED:
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_DISCONNECTED:
                    case VHL.Msg.MediaStream.Events.Actions.GENERIC_ERROR:
                        _externalMediaStreamEventHandler(sessionID, event);
                        break;
                }
                break;
            case VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_PAIRING:
            case VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_PAIRING:
                switch(event.action) {
                    case VHL.Msg.MediaStream.Events.Actions.PARTNER_STREAM_CREATED:
                        _externalMediaStreamEventHandler(sessionID, event);
                        break;
                }
                break;
        }
    };

    /**
     * PRIVATE LOGGER
     * 
     * A wrapper around VHL.Msg.Logger for inject additional 
     * context (session data, module-source) into log strings.
     *  
     */
    var _log = (function() {
        var _myLogger = VHL.Msg.Logger({
            "level": VHL.Msg.LogLevels.INFO, //GLOBAL LOGGING LEVEL for MediaStreamManager  
            "context": {
                "type": "MEDIASTREAM_MANAGER"
            }
        });

        /**
         * This function calls the VHL Logger instance that was created above.
         */
        function callMyLogger(level, message, sessionId, data) {
            var context = {};
            if(sessionId) { context.session_id = sessionId; }
            if(_myLogger[level]) {
                _myLogger[level]({ "context": context, "message": message, "data": data });
            }
        }

        return {
            "info": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.INFO, message, sessionId, data);
            },
            "warn": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.WARN, message, sessionId, data);
            },
            "error": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.ERROR, message, sessionId, data);
            }
        };
    }) ();

    /**
     * This function is used to call the Media server or MOCK Media Server depending on MODE.
     *
     * @param {String} action - A string representing the type of streaming function
     *                          (create, play etc).
     * @param arguments - Expects an undefined number of paramaters (depending the action).
     */
    var _callStreamingProvider = function(action) {
        /**
        * Steps followed
        * (1). Create an array of arguments.
        * (2). Slice the first argument which is the name of the streaming function.
        * (3). Call the streaming function with the remaining array of arguments.
        *
        */
        var params = Array.prototype.slice.call(arguments, 1); // Step 1 and 2

        if(_mode === VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER) {
            // Call MEDIASERVER MOCK
            if(_mediaServerMock && typeof _mediaServerMock[action] === "function") {
                _mediaServerMock[action].apply(null, params); // Step 3
            } else {
                _log.warn("MOCKED MEDIASERVER function : " + action + " does not exist.");
            }
        } else {
             // Call WebRTC js
            if(_webRTCAdapter && typeof _webRTCAdapter[action] === "function") {
                _webRTCAdapter[action].apply(null, params); // Step 3
            } else {
                _log.warn("WebRTC JS function : " + action + " does not exist.");
            }
        }
    };


    /** ====== Public Functions - Returned by VHL.Msg.MediaStream.MediaStreamManager */

    /**
     * Note these functions delegates the actual work to _callStreamingProvider which is designed
     * to agnostic of the actual streaming technology/provider (WebRTC or others)
     */

    /**
     * Creates a unique media stream for a "session-id & user role". This function
     * creates a stream for a particular user based on user role.
     *
     * @param {String} userRole - Inviting or Invited
     * 
     */
    var __createMediaStream = function(userRole, cbSuccess, cbFailure) {
        var config = {
            api_key: mediaOptions.api_key,
            session_id: mediaOptions.session_id,
            me_role: userRole,
            my_media_element: mediaOptions.my_media_element,
            partner_media_element: mediaOptions.partner_media_element,
            playback_media_element: mediaOptions.playback_media_element,
            media_base_url: mediaOptions.media_base_url,
            recording_polling_interval: mediaOptions.recording_polling_interval,
            recording_polling_timeout: mediaOptions.recording_polling_timeout
        };
        if(_mode  === VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER) {
            _mediaServerMock = VHL.Msg.MediaStream.Mocks.MediaServer(config);
            var streamData = _mediaServerMock.getSessionMediaData();
            delete streamData.recordings;
            cbSuccess(streamData);
        } else {
            VHL.Msg.WebRTC.SessionManager(
                config,
                _webRTCEventHandler,
                function success(webRTCAdapter) {
                    _webRTCAdapter = webRTCAdapter;
                    var streamData = _webRTCAdapter.getSessionMediaData();
                    delete streamData.recordings;
                    cbSuccess(streamData);
                },
                cbFailure
            );
        }
    };

    /**
     * Plays stream for a "session-id & user role". This function is used to
     * play partner user's media stream.
     *
     * @param {String} streamName - stream name (.flv) of partner.
     * @param {String} token - Secret for Authenticating with the Streaming Provider
     * 
     */
    var __playPartnerMediaStream = function(cbSuccess, cbFailure) {
        _log.info("playPartnerMediaStream function called", sessionID);
        _callStreamingProvider("playPartnerMediaStream", null, cbSuccess, cbFailure);
    };

    /**
     * Starts recording media streams for a partner chat session. This function
     * starts stream recording for this session
     *
     */
    var __startRecording = function(startRecordingOptions, cbSuccess, cbFailure) {
        _log.info("startRecording function called", sessionID);
        _callStreamingProvider("startRecording", startRecordingOptions, cbSuccess, cbFailure);
    };

    /**
     * Stops recording media streams for a partner chat session. This function
     * stops the recording of media stream.
     *
     */
    var __stopRecording = function(recordingId, cbSuccess, cbFailure) {
        _log.info("stopRecording function called", sessionID);
        _callStreamingProvider("stopRecording", recordingId, cbSuccess, cbFailure);
    };

    /**
     * Fetches recording status from Dynamo for url-path.
     */
    var __getRecordingStatus =  function(userId, recordingId) {
        _log.info("getRecordingStatus function called", sessionID);
        _callStreamingProvider("getRecordingStatus", userId, recordingId);
    };

    /**
     * This function is used to terminate the chat session.
     * It will delete / clean all the associated (invited and inviting) user's media streams.
     *
     * An event with type "MEDIA_STREAM" and action "STREAM_TERMINATED" will be emitted on
     * successfull media stream termination.
     */
    var __terminateMediaStream = function() {
        _log.info("terminateMediaStream function called", sessionID);
        _callStreamingProvider("endSession");
    };

    /**
     * This function is used to show own audio and vidio in the DOM.
     * This function doesn't guarantee that the media will start immediately.
     */
    var __publishMyMediaStream = function(bShow, options, cbSuccess, cbFailure) {
        _callStreamingProvider("publishMyMediaStream", bShow, options, cbSuccess, cbFailure);
    };

    /**
     * This function is used to start the recording playback.
     * This function doesn't guarantee that the media will start immediately.
     */
    var __startRecordingPlayback = function(recordingUrl, cbSuccess, cbFailure) {
        _log.info("startRecordingPlayback function called", sessionID);
        _callStreamingProvider("startRecordingPlayback", recordingUrl, cbSuccess, cbFailure);
    };

    /**
     * This function is used to stop the recording playback.
     * This function doesn't guarantee that the media will stop immediately.
     */
    var __stopRecordingPlayback = function() {
        _log.info("stopRecordingPlayback function called", sessionID);
        _callStreamingProvider("stopRecordingPlayback");
    };

    /**
    * This function is used to mute / unmute the audio while live streaming.
    */
    var __enableAudio = function(enableAudio) {
        _log.info("enableAudio function called", sessionID);
        _callStreamingProvider("enableAudio", enableAudio);
    };

    /**
    * This function is used to pause / unpause the video while live streaming.
    */
    var __enableVideo = function(enableVideo) {
        _log.info("enableVideo function called", sessionID);
        _callStreamingProvider("enableVideo", enableVideo);
    };

     /** ======  Module INITIALIZATION logic and Returning  public functions  */

    if(!_externalMediaStreamEventHandler) { //Register Handler for sending back media events
        _externalMediaStreamEventHandler = eventHandler;
    }

    if (mediaOptions.mode) { //Override default mode, if provide by caller
        _mode = mediaOptions.mode;
    }

    return {
        "createMediaStream": __createMediaStream,
        "playPartnerMediaStream": __playPartnerMediaStream,
        "publishMyMediaStream": __publishMyMediaStream,
        "terminateMediaStream": __terminateMediaStream,
        "startRecording": __startRecording,
        "stopRecording": __stopRecording,
        "getRecordingStatus": __getRecordingStatus,
        "startRecordingPlayback": __startRecordingPlayback,
        "stopRecordingPlayback": __stopRecordingPlayback,
        "enableAudio": __enableAudio,
        "enableVideo": __enableVideo
    };
}; //End of MediaStreamManager module

var VHL = VHL || {}; //Standard VHL namespace
VHL.Msg = VHL.Msg || {}; //New Msg (sub-namespace) to avoid collision with existing/previous version.
VHL.Msg.Session = VHL.Msg.Session || {};

/**
 * Updating underscore template settings
 */
if (typeof _ === "function") {
    _.templateSettings = {
        "interpolate": /\{\{(.+?)\}\}/g
    };
}

/**
 * Message Type enum.
 * Purpose - Serves as a pseudo enum (list) of message types which would be used to differentiate
 *           the messages.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.Types = (function () {
    "use strict";

    return {
        // Supported Actions - [INVITE, ACCEPT, REJECT, REVOKE]
        "GROUP_CHAT_INVITE": "GROUP_CHAT_INVITE",
        // Supported Actions - [INITIATE, CONFIRM]
        "GROUP_CHAT_PAIRING": "GROUP_CHAT_PAIRING",
        // Supported Actions - [TERMINATE, RECORDING_STOPPED, RECORDING_STARTED, COMBINE_COMPLETE, COMBINE_FAILED, COMBINE_POLLING_TIMEOUT, PARTNER_RECORDING_PLAYBACK_START, PARTNER_RECORDING_PLAYBACK_STOP, RECORDING_PLAYBACK_COMPLETE]
         "GROUP_CHAT_MEDIA_STREAM": "GROUP_CHAT_MEDIA_STREAM",
        // Supported Actions - [JOIN, LEAVE, TIMEOUT, STATE_CHANGE] 
        "PRESENCE": "PRESENCE",
        // Supported Actions - [PARTNER_CHAT_INVITE, PARTNER_CHAT_PAIRING]
        "TIMEOUT": "TIMEOUT",
        // Supported Actions - [NEW_MESSAGE, HISTORY_MESSAGE, HISTORY_RETRIEVAL_COMPLETE]
        "PRIVATE_CHAT": "PRIVATE_CHAT",
        // Supported Actions - [INVITE, ACCEPT, REJECT, REVOKE, HISTORY_INVITE_SEND, HISTORY_INVITE_RECEIVE]
        "PARTNER_CHAT_INVITE": "PARTNER_CHAT_INVITE",
        // Supported Actions - [INITIATE, CONFIRM]
        "PARTNER_CHAT_PAIRING": "PARTNER_CHAT_PAIRING",
        // Supported Actions - [TERMINATE, RECORDING_STOPPED, RECORDING_STARTED, COMBINE_COMPLETE, COMBINE_FAILED, COMBINE_POLLING_TIMEOUT, PARTNER_RECORDING_PLAYBACK_START, PARTNER_RECORDING_PLAYBACK_STOP, RECORDING_PLAYBACK_COMPLETE]
        "PARTNER_CHAT_MEDIA_STREAM": "PARTNER_CHAT_MEDIA_STREAM",
        // Supported Actions - [MESSAGE]
        "PARTNER_CHAT_CONTROL_MESSAGE": "PARTNER_CHAT_CONTROL_MESSAGE",
        "GROUP_CHAT_CONTROL_MESSAGE" : "GROUP_CHAT_CONTROL_MESSAGE",
        // Supported Actions - [SUBMITTED_POST_SESSION]
        "PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION": "PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION",

        // Supported Actions - [DOWN, UP]
        "NETWORK_STATUS": "NETWORK_STATUS"
    };
})();

/**
 * Message Action enum.
 * Purpose - Serves as a pseudo enum (list) of message actions which would be used to describe
 *           the action performed by the user.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.Actions = (function () {
    "use strict";

    return {
        // For type - PRESENCE
        "JOIN": "JOIN",
        "LEAVE": "LEAVE",
        "TIMEOUT": "TIMEOUT",
        "INTERVAL": "INTERVAL",
        "STATE_CHANGE": "STATE_CHANGE",
        // For type - PRIVATE_CHAT
        "NEW_MESSAGE": "NEW_MESSAGE",
        "HISTORY_MESSAGE": "HISTORY_MESSAGE",
        "HISTORY_RETRIEVAL_COMPLETE": "HISTORY_RETRIEVAL_COMPLETE",
        // For type - PARTNER_CHAT_INVITE
        "INVITE": "INVITE",
        "ACCEPT": "ACCEPT",
        "ACCEPT_LATER": "ACCEPT_LATER",
        "REJECT": "REJECT",
        "REVOKE": "REVOKE",
        "HISTORY_INVITE_SEND": "HISTORY_INVITE_SEND",
        "HISTORY_INVITE_RECEIVE": "HISTORY_INVITE_RECEIVE",
        "ACCEPTED_OTHER_DEVICE": "ACCEPTED_OTHER_DEVICE",
        "REJECTED_OTHER_DEVICE": "REJECTED_OTHER_DEVICE",
        // For type - TIMEOUT
        "GROUP_CHAT_INVITE": "GROUP_CHAT_INVITE",
        "GROUP_CHAT_PAIRING": "GROUP_CHAT_PAIRING",
        "PARTNER_CHAT_INVITE": "PARTNER_CHAT_INVITE",
        "PARTNER_CHAT_PAIRING": "PARTNER_CHAT_PAIRING",
        // For type - PARTNER_CHAT_PAIRING and GROUP_CHAT_PAIRING
        "INITIATE": "INITIATE",
        "CONFIRM": "CONFIRM",
        // For type - PARTNER_CHAT_MEDIA_STREAM
        "TERMINATE": "TERMINATE",
        "RECORDING_STOPPED": "RECORDING_STOPPED",
        "RECORDING_STARTED": "RECORDING_STARTED",
        "COMBINE_COMPLETE": "COMBINE_COMPLETE",
        "COMBINE_FAILED": "COMBINE_FAILED",
        "COMBINE_POLLING_TIMEOUT": "COMBINE_POLLING_TIMEOUT",
        "PARTNER_RECORDING_PLAYBACK_START": "PARTNER_RECORDING_PLAYBACK_START",
        "PARTNER_RECORDING_PLAYBACK_STOP": "PARTNER_RECORDING_PLAYBACK_STOP",
        "RECORDING_PLAYBACK_COMPLETE": "RECORDING_PLAYBACK_COMPLETE",
        "AUDIO_LEVEL_UPDATED": "AUDIO_LEVEL_UPDATED",
        "MEDIA_SESSION_RECONNECTING" : "MEDIA_SESSION_RECONNECTING",
        "MEDIA_SESSION_RECONNECTED": "MEDIA_SESSION_RECONNECTED",
        "MEDIA_SESSION_DISCONNECTED": "MEDIA_SESSION_DISCONNECTED",
        "MEDIA_GENERIC_ERROR": "MEDIA_GENERIC_ERROR",
        // For type - PARTNER_CHAT_CONTROL_MESSAGE
        "MESSAGE": "MESSAGE",

        // For type - PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION
        "SUBMITTED_POST_SESSION": "SUBMITTED_POST_SESSION",

        // For type - NETWORK_STATUS
        "DOWN": "DOWN",
        "UP": "UP"
    };
})();

VHL.Msg.Session.State = {
    "RECORDING_STARTED": VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM + "#" +
                         VHL.Msg.Actions.RECORDING_STARTED,
    "RECORDING_STOPPED": VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM + "#" +
                         VHL.Msg.Actions.RECORDING_STOPPED,
    "RECORDING_PLAYBACK_STARTED": VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM + "#" +
                                  VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_START,
    "RECORDING_PLAYBACK_STOPPED": VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM + "#" +
                                  VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_STOP
};

/**
 * User enum.
 * Purpose - Serves as a pseudo enum (list) of User specific data.
 * TODO : Consider moving to separate file in future
 */
VHL.Msg.User = (function () {
    "use strict";

    return {
        State: { // possible online state for a user in a roster group.
            "BUSY": "BUSY",
            "AVAILABLE": "AVAILABLE",
            "AWAY": "AWAY"
        }
    };
})();

/**
 * Performance Metric enum.
 * Purpose - Serves as a pseudo enum (list) of Performance Metric types.
 */
VHL.Msg.PerformanceMetric = {
    mark: {
        start: {
            "SUBSCRIBE": "mark.vhl.msg.subscribe.start",
            "VHL_GRANT_ENDPOINT": "mark.vhl.msg.grant.start",
            "GET_ONLINE_MEMBERS": "mark.vhl.msg.members.start",
            "SET_STATE": "mark.vhl.msg.setState.start",
            "CREATE_MEDIA_STREAM": "mark.vhl.media.createMediaStream.start",
            "SEND_INVITE": "mark.vhl.msg.sendInvite.start",
            "ACCEPT_INVITE": "mark.vhl.msg.acceptInvite.start",
            "REVOKE_INVITE": "mark.vhl.msg.revokeInvite.start",
            "REJECT_INVITE": "mark.vhl.msg.rejectInvite.start",
            "SEND_MESSAGE": "mark.vhl.msg.sendMessage.start",
            "SEND_CONTROL_MESSAGE": "mark.vhl.msg.sendControlMessage.start",
            "SEND_CONTROL_MESSAGE_POST_SESSION": "mark.vhl.msg.sendControlMessagePostSession.start",
            "START_RECORDING": "mark.vhl.media.startRecording.start",
            "STOP_RECORDING": "mark.vhl.media.stopRecording.start",
            "SETUP": "mark.vhl.msg.setup.start",
            "START_PAIRING": "mark.vhl.msg.startPairing.start",
            "CONFIRM_PAIRING": "mark.vhl.msg.confirmPairing.start",
            "START_RECORDING_PLAYBACK": "mark.vhl.cdn.playbackRecording.start",
            "GET_RECORDING_STATUS": "mark.vhl.db.recordingStatus.start",
            "RETRIEVE_MESSAGE_HISTORY": "mark.vhl.msg.retrieveMessageHistory.start"
        },
        end: {
            "SUBSCRIBE": "mark.vhl.msg.subscribe.end",
            "VHL_GRANT_ENDPOINT": "mark.vhl.msg.grant.end",
            "GET_ONLINE_MEMBERS": "mark.vhl.msg.members.end",
            "SET_STATE": "mark.vhl.msg.setState.end",
            "CREATE_MEDIA_STREAM": "mark.vhl.media.createMediaStream.end",
            "SEND_INVITE": "mark.vhl.msg.sendInvite.end",
            "ACCEPT_INVITE": "mark.vhl.msg.acceptInvite.end",
            "REVOKE_INVITE": "mark.vhl.msg.revokeInvite.end",
            "REJECT_INVITE": "mark.vhl.msg.rejectInvite.end",
            "SEND_MESSAGE": "mark.vhl.msg.sendMessage.end",
            "SEND_CONTROL_MESSAGE": "mark.vhl.msg.sendControlMessage.end",
            "SEND_CONTROL_MESSAGE_POST_SESSION": "mark.vhl.msg.sendControlMessagePostSession.end",
            "START_RECORDING": "mark.vhl.media.startRecording.end",
            "STOP_RECORDING": "mark.vhl.media.stopRecording.end",
            "SETUP": "mark.vhl.msg.setup.end",
            "START_PAIRING": "mark.vhl.msg.startPairing.end",
            "CONFIRM_PAIRING": "mark.vhl.msg.confirmPairing.end",
            "START_RECORDING_PLAYBACK": "mark.vhl.cdn.playbackRecording.end",
            "GET_RECORDING_STATUS": "mark.vhl.db.recordingStatus.end",
            "RETRIEVE_MESSAGE_HISTORY": "mark.vhl.msg.retrieveMessageHistory.end"
        }
    },
    measure: {
        "SUBSCRIBE": "measure.vhl.msg.subscribe",
        "VHL_GRANT_ENDPOINT": "measure.vhl.msg.grant",
        "GET_ONLINE_MEMBERS": "measure.vhl.msg.members",
        "SET_STATE": "measure.vhl.msg.setState",
        "CREATE_MEDIA_STREAM": "measure.vhl.media.createMediaStream",
        "SEND_INVITE": "measure.vhl.msg.sendInvite",
        "ACCEPT_INVITE": "measure.vhl.msg.acceptInvite",
        "REVOKE_INVITE": "measure.vhl.msg.revokeInvite",
        "REJECT_INVITE": "measure.vhl.msg.rejectInvite",
        "SEND_MESSAGE": "measure.vhl.msg.sendMessage",
        "SEND_CONTROL_MESSAGE": "measure.vhl.msg.sendControlMessage",
        "SEND_CONTROL_MESSAGE_POST_SESSION": "measure.vhl.msg.sendControlMessagePostSession",
        "START_RECORDING": "measure.vhl.media.startRecording",
        "STOP_RECORDING": "measure.vhl.media.stopRecording",
        "SETUP": "measure.vhl.msg.setup",
        "START_PAIRING": "measure.vhl.msg.startPairing",
        "CONFIRM_PAIRING": "measure.vhl.msg.confirmPairing",
        "START_RECORDING_PLAYBACK": "measure.vhl.cdn.playbackRecording",
        "GET_RECORDING_STATUS": "measure.vhl.db.recordingStatus",
        "RETRIEVE_MESSAGE_HISTORY": "measure.vhl.msg.retrieveMessageHistory"
    }
};

/**
 * Partner chat timeouts enums.
 * Purpose - Serves as a pseudo enum (list) of Partner chat timeouts default values.
 */
VHL.Msg.PartnerChatTimeouts = {
    "Duration": {
        "INVITE": 300000,     //in milliseconds
        "PAIRING": 30000      //in milliseconds
    }
};

/**
 * Group chat timeouts enums.
 * Purpose - Serves as a pseudo enum (list) of Group chat timeouts default values.
 */
VHL.Msg.GroupChatTimeouts = {
    "Duration": {
        "INVITE": 40000,     //in milliseconds
        "PAIRING": 300000      //in milliseconds
    }
};

/**
 * Private chat history retention interval enums in milliseconds (ms).
 * Purpose - Serves as a pseudo enum (list) of Private chat history retention interval.
 */
VHL.Msg.PrivateChatHistoryRetrieval = {
    "Duration": {
        "ONE_DAY": 86400000,
        "THREE_DAYS": 259200000,
        "SEVEN_DAYS": 604800000,
        "FIFTEEN_DAYS": 1296000000,
        "THIRTY_DAYS": 2592000000,
        "UNLIMITED": "UNLIMITED"
    }
};

/**
 * Errors enum.
 * Purpose - Serves as a pseudo enum (list) of Errors.
 */
VHL.Msg.Errors = {
    "Context": {
        "SETUP": "SETUP",
        "PARTNER_CHAT_INIT": "PARTNER_CHAT_INIT",
        "PARTNER_CHAT_RECORDING": "PARTNER_CHAT_RECORDING",
        "PARTNER_CHAT_PLAYBACK": "PARTNER_CHAT_PLAYBACK",
        "PARTNER_CHAT_CONTROL_MESSAGE": "PARTNER_CHAT_CONTROL_MESSAGE",
        "PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION": "PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION",
        "STATE": "STATE",
        "PRESENCE": "PRESENCE",
        "TEXT_CHAT": "TEXT_CHAT"
    },
    "Code": {
        "MANDATORY_PARAMETER_MISSING": "MANDATORY_PARAMETER_MISSING",
        "SESSION_STORAGE_NOT_SUPPORTED": "SESSION_STORAGE_NOT_SUPPORTED",
        "ALREADY_INITIALIZED": "ALREADY_INITIALIZED",
        "MESSAGE_SEND_FAILED": "MESSAGE_SEND_FAILED",
        "GET_ONLINE_MEMBERS_FAILED": "GET_ONLINE_MEMBERS_FAILED",
        "SUBSCRIPTION_FAILED": "SUBSCRIPTION_FAILED",
        "STATE_INITIALIZATION_FAILED": "STATE_INITIALIZATION_FAILED",
        "STREAM_CREATION_FAILED": "STREAM_CREATION_FAILED",
        "JOIN_PARTNER_CHAT_SESSION_FAILED": "JOIN_PARTNER_CHAT_SESSION_FAILED",
        "MEDIA_STREAM_RECORDING_START_FAILED": "MEDIA_STREAM_RECORDING_START_FAILED",
        "MEDIA_STREAM_RECORDING_STOP_FAILED": "MEDIA_STREAM_RECORDING_STOP_FAILED",
        "MEDIA_STREAM_RECORDING_COMBINE_FAILED": "MEDIA_STREAM_RECORDING_COMBINE_FAILED",
        "START_MEDIA_STREAM_PLAYBACK_FAILED": "START_MEDIA_STREAM_PLAYBACK_FAILED",
        "STOP_MEDIA_STREAM_PLAYBACK_FAILED": "STOP_MEDIA_STREAM_PLAYBACK_FAILED",
        "STATE_UPDATE_FAILED": "STATE_UPDATE_FAILED",
        "GRANT_API_FAILED": "GRANT_API_FAILED",
        "SEND_INVITE_FAILED": "SEND_INVITE_FAILED",
        "REJECT_INVITE_FAILED": "REJECT_INVITE_FAILED",
        "REVOKE_INVITE_FAILED": "REVOKE_INVITE_FAILED",
        "ACCEPT_INVITE_FAILED": "ACCEPT_INVITE_FAILED",
        "CONFIRM_PAIRING_FAILED": "CONFIRM_PAIRING_FAILED",
        "START_PAIRING_FAILED": "START_PAIRING_FAILED",
        "MESSAGE_HISTORY_RETRIEVAL_FAILED": "MESSAGE_HISTORY_RETRIEVAL_FAILED",
        "PLAY_PARTNER_MEDIA_STREAM_FAILED": "PLAY_PARTNER_MEDIA_STREAM_FAILED",
        "GET_STATE_FAILED": "GET_STATE_FAILED"
    },
    "Source": {
        "PUBNUB": "PUBNUB",
        "TOKBOX": "TOKBOX",
        "XHR": "XHR",
        "CLIENTWRAPPER": "CLIENTWRAPPER",
        "CLOUDFRONT": "CLOUDFRONT"
    }
};

/**
 * Clientwrapper module.
 * Purpose -  Wrapper around the Saas client SDK (PubNub). Abstracts the provider/vendor (PubNub) specific
 * implementation details - allowing future switch (to a different Saas provider).
 */
VHL.Msg.ClientWrapper = (function () {
    "use strict";

    //** ====== DEPENDENCY CHECKS */
    // TODO - Check for PubNub as well.
    // TODO - Consider waiting and try again, instead of exiting abrutly.
    if (typeof _ !== "function") {
        console.log("Underscore not available. Exiting");
        return;
    }

    /**
     * PRIVATE LOGGER
     *
     * A wrapper around VHL.Msg.Logger for inject additional
     * context (session data, module-source) into log strings.
     *
     */
    var _log = (function() {
        var _myLogger = VHL.Msg.Logger({
            "level": VHL.Msg.LogLevels.INFO, //GLOBAL LOGGING LEVEL for ClientWrapper
            "context": {
                "type": "CLIENTWRAPPER"
            }
        });

        /**
         * This function calls the VHL Logger instance that was created above.
         */
        function callMyLogger(level, message, sessionId, data) {
            var context = { "session_id": sessionId };
            if(_myLogger[level]) {
                _myLogger[level]({ "context": context, "message": message, "data": data });
            }
        }

        return {
            "info": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.INFO, message, sessionId, data);
            },
            "warn": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.WARN, message, sessionId, data);
            },
            "error": function(message, sessionId, data) {
                callMyLogger(VHL.Msg.LogLevels.ERROR, message, sessionId, data);
            }
        };
    }) ();

    /** ====== MODULE GLOBALS */
    var _pubnubClient; //SAAS provider client SDK (PubNub).
    // Timetoken at which _pubnubClient was initialized ().
    // This is Pubnub timetoken i.e. 17-digit precision unix time (UTC).
    var _setupTimetoken;
    // TTL in hours for messages published to user's control channel.
    var _pChatInviteTTL = 1;
    var _historyEndTimetoken; // Maximum timetoken before which message history is not available.
    // User or caller options (merged with default)
    // as provided during initialization, wrapper.setup().
    var _options;
    // A maps of media options as provided during initialization, wrapper.setup().
    var _externalMediaOptions;
    var _myGroupState = {}; // A map to represent current user's (me) state in each group.
    //Main event handler (for the connection) as provided during adapter.subscribeEvents().
    var _externalEventHandler;
    // Reference to activity URL as provided during initialization, wrapper.setup().
    var _activityUrl = "/";
    var _schoolId; // Reference to school Id as provided during initialization, wrapper.setup().
    var _activityId; // Reference to activity Id as provided during initialization, wrapper.setup().
    var _inviteMetadata; // Reference to invite metadata as provided during initialization, wrapper.setup().
    var _pubNubRestore = true; // Flag to restore the pubnub subscriptions and restore lost messages.
    var _bInitialized = false; // Flag to track when PubNub SDK and Client Adapter is initialized. By default FALSE.
    var _bNewDevice = false; // Flag to track, if this is a new device/tab or a refresh/navigation of an existing device/tab.

    // PubNub Channel Prefixes
    var pubNubChannelPrefixes = {
        GROUP_SESSION: "gs_", // Previously - group_session_
        GROUP_CONTROL: "gc_", // Previously - group_control_
        GROUP_TEXT: "gt_"     // Previously - group_text_
    };

    // Partner Chat related

    /**
     * A map of all partner chat sessions (data, information, keys). 
     * Session object is added to the map when an INVITE is recieved or sent. Updated
     * during PAIRING events. The session object is removed/cleaned from map when a 
     * corresponding INVITE_REJECTED or INVITE_REVOKED events. Also removed/cleaned
     * from the map when .endSession() is called on "partner chat session adapter""
     *  
     * @key {string} sessionid
     * @value {object} - information & data on the session.
     * See https://github.com/vhl/dirt-driver-chat/wiki/Partner-Chat-Sessions
     */
    var _mapPartnersSessionData = {}; 

    /**
     * A map to store the presence stats of all the users in my group (including me).
     *
     * @key {string} groupid - an identifier for unique group / sections.
     * @value {object} - information (userid, state, device_count) of occupants, occupancy.
     */
    var _mapGroupPresence = {};

    /**
     * A tracking hashmap to store the presence stats of all the users in my group (including me).
     * This hashmap only contains users and their device_counts. This hashmap does not remomves
     * the user, once device_count is reset to zero.
     *
     * @key {string} groupid - an identifier for unique group / sections.
     * @value {object} - information (userid, device_count) of occupants.
     */
    var _mapTrackingPresence = {};

    /**
     * A map to store the last timetoken for my private text chat with a user in a group
     *
     * @key {string} groupid - an identifier for unique group / sections.
     * @value {object} - user info object
     *
     * User info object
     * @key {string} in_process
     * @value {boolean} history message retrieval is in-process.
     * @key {string} last_timetoken
     * @value {string} pubnub timetoken that should be used to retrive the next set
     *                 of message history.
     */
    var _mapPrivateChatHistory = {};
    var _externalPChatEventHandler; //Partner chat Session event handler as provided during pChatSession.acceptInvite().
    var _mediaStreamMgr; // VHL.Msg.MediaStream.MediaStreamManager().

    /** ###### END OF MODULE GLOBALS */

    /** ====== UTILITY FUNCTIONS */

    /**
     * Safely decode and split UUID, handling null/undefined values and malformed encoding
     * @private
     * @param {string} uuid - The UUID to decode and split
     * @returns {array} Array with [userid, device_id] or [null, null] if invalid
     */
    var _safeDecodeUuidSplit = function(uuid) {
        if (!uuid) {
            return [null, null];
        }
        try {
            return decodeURIComponent(uuid).split(':');
        } catch (e) {
            console.warn('Failed to decode UUID:', uuid, e);
            // Fallback to direct split if decoding fails
            return uuid.split(':');
        }
    };

    /**
     * This function returns the chat invite type based on the activity type.
     * @returns {string} chat invite type
     */
    let _getChatInviteType = function() {
        if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            return VHL.Msg.Types.GROUP_CHAT_INVITE;
        } else {
            return VHL.Msg.Types.PARTNER_CHAT_INVITE;
        }
    };

    /**
     * This function returns the chat timeout type.
     * @param {string} action - [INVITE, PAIRING].
     * @returns {string} chat timeout type
     */
    let _getChatTimeoutType = function(action) {
        if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            return VHL.Msg.Actions[`GROUP_CHAT_${action}`];
        } else {
            return VHL.Msg.Actions[`PARTNER_CHAT_${action}`];
        }
    };

    /**
     * This function returns the chat invite timeout duration.
     * @returns {number} duration
     */
    let _getChatInviteTimeout = function() {
        if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            return VHL.Msg.GroupChatTimeouts.Duration.INVITE;
        } else {
            return VHL.Msg.PartnerChatTimeouts.Duration.INVITE;
        }
    };

    /**
     * This function override default chat timeouts if timeouts
     * provided during setup.
     */
    let _overrideChatTimeouts = function(timeoutType, configTimeouts) {
        const inviteTimeOut = configTimeouts.invite_timeout_duration;
        const pairingTimeOut = configTimeouts.pairing_timeout_duration;

        if(inviteTimeOut && !isNaN(inviteTimeOut)) {
           VHL.Msg[timeoutType].Duration.INVITE = parseInt(inviteTimeOut) * 1000;
        }

        if(pairingTimeOut && !isNaN(pairingTimeOut)) {
            VHL.Msg[timeoutType].Duration.PAIRING = parseInt(pairingTimeOut) * 1000;
        }
    };

    /**
     * This function is used to create error object
     * @private
     * @param   {string} source  In which sub component/system did this error originate.
     * @param   {string} context Which CW function throws/returns this error.
     * @param   {string} code    Error type.
     * @param   {string} reason  Brief description of error.
     * @param   {object} err     Actual error object.
     * @returns {object} Translated error object
     */
    var _processError = function(source, context, code, reason, err) {
        var errObj = {
            "source": source,
            "context": context,
            "code": code
        };
        if(reason) { errObj.reason = reason; }
        if(err) {
            switch(source) {
                case VHL.Msg.Errors.Source.XHR:
                    errObj.xhr_data = err;
                    break;
                case VHL.Msg.Errors.Source.PUBNUB:
                    errObj.pubnub_data = err;
                    break;
                case VHL.Msg.Errors.Source.TOKBOX:
                    errObj.tokbox_data = err;
                    break;
                case VHL.Msg.Errors.Source.CLOUDFRONT:
                    errObj.cloudfront_data = err;
                    break;
                default:
                    //Nothing to do.
            }
        }
        return errObj;
    };

    //PERFORMANCE-API Utility Functions Starts
    /**
     * This function is used check Performance Api support in browser.
     * @private
     * @returns {boolean} Returns true if supported else returns false.
     */
    var _isPerformanceApiSupported = function() {
        return (
          (typeof(Performance) !== "undefined") &&
          (performance.mark !== undefined) &&
          (performance.measure !== undefined)
        );
    };

    /**
     * This function is used to mark(record) current time for an event or action.
     * @private
     * @param {string} name Name of the mark.(Dot (.) & Underscore (_) notations are supported).
     */
    var _mark = function(name) {
        if(_isPerformanceApiSupported() && name) {
            performance.mark(name);
        }
    };

    /**
     * This function is used to get time duration between two marks.
     * @private
     * @param {string} name      Name of measure.
     * @param {string} markStart Name of the start mark.
     * @param {string} markEnd   Name of the end mark.
     */
    var _measure = function(name, markStart, markEnd) {
        if(
          _isPerformanceApiSupported() && 
          name && 
          markStart && 
          markEnd && 
          (performance.getEntriesByName(markStart).length > 0)
        ) {
            performance.measure(name, markStart, markEnd);
        }
    };

    /**
     * This function is used to clear marks.
     * If name is provided, it will clear particular mark with given name.
     * If no name provided, it will clear all marks.
     * @private
     * @param {Array} name (Optional) Name of mark to be cleared.
     */
    var _clearMarks = function(markNames) {
        if(_isPerformanceApiSupported()) {
            if(markNames && markNames.length) {
                for(var i in markNames) {
                    performance.clearMarks(markNames[i]);
                }
            } else { //Clear all marks.
                performance.clearMarks();
            }
        }
    };

    /**
     * This function is used to clear measure.
     * If array of names is provided, it will clear all measures present in array.
     * If no name provided, it will clear all measures.
     * @private
     * @param {string} measureNames (Optional) Array of Names of measure to be cleared.
     */
    var _clearMeasures = function(measureNames) {
        if(_isPerformanceApiSupported()) {
            if(measureNames && measureNames.length) {
                for(var i in measureNames) {
                    performance.clearMeasures(measureNames[i]);
                }
            } else { //Clear all marks.
                performance.clearMeasures();
            }
        }
    };

    /**
     * This function is used to mark end of the metric, measure the metric and clear
     * the start and end marks.
     * @private
     * @param {string} metricName Name of metric to be ended.
     */
    var _endPerformanceMetric = function(metricName) {
        _mark(VHL.Msg.PerformanceMetric.mark.end[metricName]);
        _measure(
            VHL.Msg.PerformanceMetric.measure[metricName],
            VHL.Msg.PerformanceMetric.mark.start[metricName],
            VHL.Msg.PerformanceMetric.mark.end[metricName]
        );
        _clearMarks([
            VHL.Msg.PerformanceMetric.mark.start[metricName],
            VHL.Msg.PerformanceMetric.mark.end[metricName]
        ]);
    };
    //PERFORMANCE-API Utility Functions Ends

    /**
     * This function performs a deep cloning of a JSON object.
     *
     * @param data (JSON) : A json object that needs to be deep cloned.
     */
    var _deepClone = function(data) {
        return JSON.parse(JSON.stringify(data));
    };

    /**
    * Call (ajax) the AUTH STUB Endpoint
    */
    var _callAuthAPI = function (url, cbSuccess, cbFailure) {
        $.ajax({
            "type": "POST",
            "url": url,
            "dataType": "json",
            "contentType": "application/json",
            "success": function (data) { cbSuccess(data); },
            "error": function(data) { cbFailure(data); } //TODO - handler response error codes
        });
    };

    /**
     * This function is used to get device id.
     *
     * @param config (object) : This object contains the config passed at the time of setup.
     *                          config.join_partner_chat_session is true only for an INVITED
     *                          user's newly spawned tab - to join an existing partner chat
     *                          session from another tab.
     * @returns device id {integer} - device id for the current tab / device.
     */
    var _getDeviceId = function(config) {
        var bJoinPChatSessionFromSetup = config.join_partner_chat_session || false;
        var deviceId = _options.user.device_id;
        var userUUID = _options.user.uuid;
        if(!deviceId) {
            var sessionStorageData = VHL.Msg.SessionStorage.Manager.getData();
            /**
             * Scenarios covered :
             * (1) First time login.
             * (2) Spawned Tab did not inherit session storage from parent window.
             */
            if(sessionStorageData.error) {
                _bNewDevice = true;
                deviceId = Math.floor(100000 + Math.random() * 900000); // create new device id.
                sessionStorageData = {
                    user: {
                        uuid: userUUID,
                        pubnub_uuid: userUUID + ":" + deviceId
                    },
                    config: {
                        joinPartnerChatSession: bJoinPChatSessionFromSetup
                    }
                };
                VHL.Msg.SessionStorage.Manager.setData(sessionStorageData);
            }
            /**
             * Scenarios covered :
             * (1) Refresh Tab.
             * (2) Spawned Tab inherits session storage from parent window.
             */
            else {
                sessionStorageData = sessionStorageData.data;
                var oldDeviceId = _safeDecodeUuidSplit(sessionStorageData.user.pubnub_uuid)[1];
                var bJoinPChatSessionFromStorage = sessionStorageData.config.joinPartnerChatSession;
                deviceId = oldDeviceId;
                /**
                 * Spawned Tab inherits session storage from parent window - so we need to create
                 * a new device id.
                 */
                if(bJoinPChatSessionFromSetup && !bJoinPChatSessionFromStorage) {
                    _bNewDevice = true;
                    deviceId = Math.floor(100000 + Math.random() * 900000);
                    sessionStorageData.user.pubnub_uuid = userUUID + ":" + deviceId;
                    sessionStorageData.config.joinPartnerChatSession = true;
                    VHL.Msg.SessionStorage.Manager.setData(sessionStorageData);
                }
            }
            deviceId = parseInt(deviceId);
            _options.user.device_id = deviceId;
        }
        return deviceId;
    };

    /**
     * This function is used to detect change in old state and new state of a user
     * in a particular group.
     *
     * @params userid {string} - userid of the user whose state needs to be compared.
     * @params group {string} - User roster group.
     * @params newState {simple key/value pair object} - User roster group.
     * @returns {boolean} - True: State updated | False: State is not updated.
     */
    var _isStateUpdated = function(userid, group, newState) {
        var oldState = _mapGroupPresence[group].occupants[userid] ?
                           _mapGroupPresence[group].occupants[userid].state : {};
        var newStateKeys = Object.keys(newState);
        var oldStateKeys = Object.keys(oldState);
        var bStateUpdated = false;
        if(newStateKeys.length === oldStateKeys.length) {
            for(var i in newStateKeys) {
                var newValue = JSON.stringify(newState[newStateKeys[i]]);
                var oldValue = JSON.stringify(oldState[newStateKeys[i]]);
                if(newValue !== oldValue) {
                    bStateUpdated = true;
                    break; // No need to check further keys
                }
            }
        } else {
           /**
            * Number of keys have changed (i.e. the caller introduced extra / custom
            * keys in the updateMyState function).
            */
           bStateUpdated = true;
        }
        return bStateUpdated;
    };

    /**
    * Translates a PubNub event into a "generic" event.
    * @param {object} pubNubEventData - Native PubNub event object.
    * @param {string} event_type - "PRESENSE" or "MESSAGE"
    * @returns {object} - Translated Event
    */
    var _translatePubNubEvents = function(pubNubEventData, event_type) {
        var translatedEvent = { "bPropagate": false }; //Return this object at the end.

        /** ====== PRESENSE EVENTS */
        if (event_type === "PRESENCE") {
            translatedEvent.type = VHL.Msg.Types.PRESENCE;
            var channelName = pubNubEventData.channel;
            let decodedUuidSplit = _safeDecodeUuidSplit(pubNubEventData.uuid);
            var userid = pubNubEventData.uuid ? decodedUuidSplit[0] : undefined;
            var device_id = pubNubEventData.uuid ? decodedUuidSplit[1] : undefined;
            console.log(pubNubEventData.action + " : " + pubNubEventData.uuid);
            var userInfo;

            translatedEvent.uuid = userid;
            translatedEvent.timestamp = pubNubEventData.timestamp;
            translatedEvent.state = pubNubEventData.state; //TODO - PubNub state schema may have more information (break it down)
            translatedEvent.group = channelName;
            switch (pubNubEventData.action) {
                case "join":
                    /**
                     * Increment the device_count for existing user and create a new entry for
                     * first time user login.
                     */
                    if(parseInt(device_id) !== _options.user.device_id) {
                        _updateGroupPresenceMap(VHL.Msg.Actions.JOIN, channelName, userid,
                                                pubNubEventData);
                        userInfo = _mapGroupPresence[channelName].occupants[userid];
                        if(userInfo.device_count === 1 && !_.isEmpty(userInfo.state)) {
                            /**
                             * First time user login. Propagate JOIN event to reference app.
                             *
                             * Necessary conditions for sending join event:
                             * (1). User's device count must be 1.
                             * (2). State changed from null to defined.
                             */
                            translatedEvent.action = VHL.Msg.Actions.JOIN;
                            translatedEvent.bPropagate = true;
                            translatedEvent.state = userInfo.state;
                        }
                    } else {
                        // Presence event received for own device - IGNORING
                    }
                    break;
                case "leave":
                    /**
                     * Decrement the device_count for the user.
                     */
                    if(parseInt(device_id) !== _options.user.device_id) {
                        _updateGroupPresenceMap(VHL.Msg.Actions.LEAVE, channelName, userid,
                                                pubNubEventData);
                        /**
                         * If the user does not exists in the _mapGroupPresence, then log
                         * additional information from the _mapTrackingPresence.
                         */
                        if (!_mapGroupPresence[channelName].occupants[userid]) {
                            var errorDetails = _getPresenceErrorDetails(pubNubEventData);
                            console.log(JSON.stringify(errorDetails, null, 4));
                        }
                        if(_mapGroupPresence[channelName].occupants[userid].device_count === 0) {
                            /**
                             * User left from all the devices. Propagate LEAVE event to reference app.
                             * Cleaning _mapGroupPresence for this user.
                             */
                            delete _mapGroupPresence[channelName].occupants[userid];
                            translatedEvent.action = VHL.Msg.Actions.LEAVE;
                            translatedEvent.bPropagate = true;
                        }
                    } else {
                        // Presence event received for own device - IGNORING
                    }
                    break;
                case "timeout":
                    /**
                     * Decrement the device_count for the user.
                     */
                    if(parseInt(device_id) !== _options.user.device_id) {
                        _updateGroupPresenceMap(VHL.Msg.Actions.TIMEOUT, channelName, userid,
                                                pubNubEventData);
                        /**
                         * If the user does not exists in the _mapGroupPresence, then log
                         * additional information from the _mapTrackingPresence.
                         */
                        if (!_mapGroupPresence[channelName].occupants[userid]) {
                            var errorDetails = _getPresenceErrorDetails(pubNubEventData);
                            console.log(JSON.stringify(errorDetails, null, 4));
                        }
                        if(_mapGroupPresence[channelName].occupants[userid].device_count === 0) {
                            /**
                             * User left / timed-out from all the devices. Propagate LEAVE event to
                             * reference app. There is no difference between leave / timeout for
                             * reference application.
                             *
                             * Cleaning _mapGroupPresence for this user.
                             */
                            delete _mapGroupPresence[channelName].occupants[userid];
                            translatedEvent.action = VHL.Msg.Actions.LEAVE;
                            translatedEvent.bPropagate = true;
                        }
                    } else {
                        // Presence event received for own device - IGNORING
                    }
                    break;
                case "interval":
                    /**
                     * An interval message is received from pubnub on reaching the ANNOUNCE-MAX
                     * setting. If the number of occupants in a group is greater than or equal to
                     * ANNOUNCE-MAX, then pubnub stops sending presence messages for actions JOIN,
                     * LEAVE, TIMEOUT.
                     *
                     * The interval message has array of users (userids) that joined, left and
                     * timed-out in a predefined interval.
                     */
                    _splitPresenceIntervalEvent(pubNubEventData);
                    break;
                case "state-change":
                    /**
                     * Process state change if the state has updated since last change.
                     */
                    if(_isStateUpdated(userid, channelName, pubNubEventData.state)) {
                        if(_options.user.uuid === userid &&
                           _options.user.device_id.toString() !== device_id.toString())
                        {
                            /**
                             * State changed by me from another device. SYNC state on this device.
                             */
                            _updateUserState(
                                [channelName],
                                pubNubEventData.state,
                                function success() {
                                    if(typeof(Performance) !== "undefined") {
                                        _clearMeasures([ "measure.vhl.msg.setState" ]);
                                    }
                                }
                            );
                        }
                        userInfo = _mapGroupPresence[channelName].occupants[userid];
                        var oldState = userInfo ? userInfo.state : {};
                        var bStateInit = _.isEmpty(oldState);

                        // updating user state info in presence map.
                        _updateStateInPresenceMap(channelName, userid, pubNubEventData.state);

                        // Getting updated userinfo.
                        userInfo = _mapGroupPresence[channelName].occupants[userid];

                        if(userInfo.device_count > 0) {
                            /**
                             * Necessary conditions for sending join event:
                             * (1). User's device count must be 1.
                             * (2). State changed from null to defined.
                             */
                            if(userInfo.device_count === 1 && bStateInit) {
                                translatedEvent.action = VHL.Msg.Actions.JOIN;
                            } else {
                                translatedEvent.action = VHL.Msg.Actions.STATE_CHANGE;
                            }
                            translatedEvent.bPropagate = true;
                        }
                    }
                    break;
                //TODO - default?
            }
        }
        /** ###### END OF PRESENSE EVENTS */
        else if (event_type === "MESSAGE" && pubNubEventData.message.context) {
            var msg = pubNubEventData.message;
            var msgType = msg.context.type;
            var msgAction = msg[msgType].action;
            translatedEvent.action = msgAction;
            translatedEvent.type = msgType;
            /** ====== ONE-to-ONE CHAT EVENTS */
            if(msgType === VHL.Msg.Types.PRIVATE_CHAT) {
                /**
                * Extracting group name from user's private channel name
                * ("gt_<group_name>.<user_uuid>")
                * As an example "course1" is to be extracted from "gt_course1.1011010101"
                  (where "course1" is group name & 1011010101 is the user's uuid.)
                * pubNubEventData.channel contains the user's private channel name
                */
                if(msgAction === VHL.Msg.Actions.NEW_MESSAGE) {
                    /* "timetoken": Pubnub's timetoken, which is a 17-digit precision unix time (UTC).
                     * For reference:
                     * https://support.pubnub.com/support/solutions/articles/14000043784-how-do-i-convert-the-pubnub-timetoken-
                     *
                     * The first message of the array is typically the main one
                     * (and only one in the array) used for text chatting.
                     * i.e. in new text messages there is a single message in the array.
                     */
                    var group = pubNubEventData.channel.split(".")[0]
                                                       .split(pubNubChannelPrefixes.GROUP_TEXT)[1];
                    translatedEvent.group = group;
                    // Transforming to and from of the received messages.
                    for(var index in msg[msgType].messages) {
                        var to = msg[msgType].messages[index].to;
                        msg[msgType].messages[index].to = _transformShortFormToLongForm(to);
                        var from = msg[msgType].messages[index].from;
                        msg[msgType].messages[index].from = _transformShortFormToLongForm(from);
                    }
                    translatedEvent.messages = msg[msgType].messages;
                    translatedEvent.messages[0].timetoken = pubNubEventData.timetoken;
                    translatedEvent.bPropagate = true;
                } else if(msgAction === VHL.Msg.Actions.HISTORY_MESSAGE) {
                    /*
                     * For the case of historical/previous text messages,
                     * there could be multiple messages in array, based on the limit.
                     */
                    translatedEvent.partner_uuid = msg[msgType].partner_uuid;
                    translatedEvent.group = msg[msgType].group;
                     // Transforming to and from of the received messages.
                    for(var index in msg[msgType].messages) {
                        var to = msg[msgType].messages[index].to;
                        msg[msgType].messages[index].to = _transformShortFormToLongForm(to);
                        var from = msg[msgType].messages[index].from;
                        msg[msgType].messages[index].from = _transformShortFormToLongForm(from);
                    }
                    translatedEvent.messages = msg[VHL.Msg.Types.PRIVATE_CHAT].messages;
                    translatedEvent.bPropagate = true;
                } else if(msgAction === VHL.Msg.Actions.HISTORY_RETRIEVAL_COMPLETE) {
                    var partnerUuid = msg[msgType].partner_uuid;
                    var group = msg[msgType].group;
                    // cannot call _endPerformanceMetric, as this metric has more data.
                    _mark(VHL.Msg.PerformanceMetric.mark.end.RETRIEVE_MESSAGE_HISTORY  + "." +
                          group + "." + partnerUuid);
                    _measure(
                        VHL.Msg.PerformanceMetric.measure.RETRIEVE_MESSAGE_HISTORY,
                        VHL.Msg.PerformanceMetric.mark.start.RETRIEVE_MESSAGE_HISTORY + "." +
                            group + "." + partnerUuid,
                        VHL.Msg.PerformanceMetric.mark.end.RETRIEVE_MESSAGE_HISTORY + "." +
                            group + "." + partnerUuid
                    );
                    _clearMarks([
                        VHL.Msg.PerformanceMetric.mark.start.RETRIEVE_MESSAGE_HISTORY + "." +
                            group + "." + partnerUuid,
                        VHL.Msg.PerformanceMetric.mark.end.RETRIEVE_MESSAGE_HISTORY + "." +
                            group + "." + partnerUuid
                    ]);

                    translatedEvent.partner_uuid = partnerUuid;
                    translatedEvent.group = group;
                    translatedEvent.status = msg[msgType].status;
                    translatedEvent.bPropagate = true;
                }
            }
            /** ###### END OF ONE-to-ONE CHAT EVENTS */
            
            /** ====== TIMEOUT EVENTS */
            else if(msgType === VHL.Msg.Types.TIMEOUT) {
                sessionData = msg[msgType].session;
                translatedEvent.sessionData = sessionData;
                if(msgAction === VHL.Msg.Actions.PARTNER_CHAT_INVITE || msgAction === VHL.Msg.Actions.GROUP_CHAT_INVITE) { // invite has timed-out.
                    if(_mapPartnersSessionData[sessionData.id]) {
                        translatedEvent.bPropagate = true;
                        delete _mapPartnersSessionData[sessionData.id];
                    } else {
                        _log.error("Invite timeout received for a session that does not exist" +
                                   ". Stopping propagation to reference app");
                    }
                } else if(msgAction === VHL.Msg.Actions.PARTNER_CHAT_PAIRING || msgAction === VHL.Msg.Actions.GROUP_CHAT_PAIRING) { // pairing has timed-out.
                    if(_mapPartnersSessionData[sessionData.id]) {
                        if(_mediaStreamMgr) {
                            var sessionAdapter = __constructSessionAdapter(sessionData.id);
                            sessionAdapter.endSession();
                        }
                        translatedEvent.bPropagate = true;
                        delete _mapPartnersSessionData[sessionData.id];
                    } else {
                        _log.error("Pairing timeout received for a session that does not exist" +
                                   ". Stopping propagation to reference app");
                    }
                }
            }
            /** ###### END OF TIMEOUT EVENTS */

            /** ====== PARTNER CHAT EVENTS FOR - INVITE, PARING, MEDIA_STREAM & CONTROL_MESSAGE */

            //INVITE EVENT recieved for Partner chat
            else if(msgType === VHL.Msg.Types.PARTNER_CHAT_INVITE || msgType === VHL.Msg.Types.GROUP_CHAT_INVITE) {
                // Consolidate session data, and finally update _mapPartnersSessionData
                var sessionData;
                var newTimeout;
                if(msgAction === VHL.Msg.Actions.INVITE) {
                    sessionData = msg[msgType].session;
                    translatedEvent.from = msg.context.from;
                    translatedEvent.sessionData = sessionData;
                    translatedEvent.sessionAdapter = __constructSessionAdapter(sessionData.id);
                    if(msg.context.from.uuid !== _options.user.uuid) {
                        if(!_mapPartnersSessionData[sessionData.id]) {
                            _mapPartnersSessionData[sessionData.id] = {
                                "id": sessionData.id,
                                "channel": sessionData.channel,
                                "invited": _transformShortFormToLongForm(sessionData.invited),
                                "inviting": _transformShortFormToLongForm(sessionData.inviting),
                                "group_id": sessionData.group_id,
                                "state": msgType + "#" + msgAction,
                                "me_role": "invited",
                                "activity_url": sessionData.activity_url,
                                "activity_id": sessionData.activity_id ? sessionData.activity_id : null,
                                "invite_metadata": sessionData.invite_metadata,
                                "enrollment": {
                                    "course_id": sessionData.enrollment.course_id,
                                    "school_id": sessionData.enrollment.school_id
                                },
                                "callbacks": {}, //Stores callbacks provided by Reference App for this session
                                "timeouts": {},
                                "recordings": {}
                            };
                            _setChatTimeouts(sessionData.id, msgType);
                            translatedEvent.inviteMetadata = sessionData.invite_metadata;
                            translatedEvent.bPropagate = true;
                        } else {
                            _log.error("Session data exist for this invite."+
                                       " Stopping propagation to reference app");
                        }
                    }
                    else {
                        /**
                         * This message is for tracking invite history. A user sends an
                         * invite, acceptance, rejection and revoke messages to his/her own control
                         * channel. Ignore it and stop propagation to reference application.
                         */
                    }
                }
                else if(msgAction === VHL.Msg.Actions.REJECT) { //INVITE was REJECTED
                    if(_options.user.device_id === msg.context.to.device_id) {
                        sessionData = msg[msgType].session;
                        if(_mapPartnersSessionData[sessionData.id]) {
                            if(!_mapPartnersSessionData[sessionData.id].invited.device_id) {
                                translatedEvent.from = msg.context.from;
                                _clearChatTimeouts(sessionData.id, msgType);
                                delete _mapPartnersSessionData[sessionData.id];
                                translatedEvent.bPropagate = true;
                            } else {
                                if(_mapPartnersSessionData[sessionData.id].invited.device_id ===
                                   msg.context.from.device_id)
                                {
                                    _log.error("Invite reject recieved from same device."+
                                                " Stopping propagation to reference app");
                                } else {
                                    _log.error("Invite reject already recieved from another "+
                                                "device. Stopping propagation to reference app");
                                }
                            }
                        } else {
                            _log.error("Invite reject received for a session that does not exist."+
                                       " Stopping propagation to reference app");
                        }
                    } else {
                        /**
                         * This message is for tracking invite history. A user sends an
                         * acceptance, rejection and revoke messages to his/her own control
                         * channel.
                         * ** Reject received from my other device. **
                         * Change the action of the translated event, as it is different from
                         * reject message received from the device, which rejected the invite.
                         * Propagate this message to Caller to update its UI.
                         * And, clear the timer for other devices.
                         */
                        if(_options.user.uuid === msg.context.from.uuid &&
                            _options.user.device_id !== msg.context.from.device_id) {
                            sessionData = msg[msgType].session;
                            _clearChatTimeouts(sessionData.id, msgType);
                            delete _mapPartnersSessionData[sessionData.id];
                            translatedEvent.sessionData = sessionData;
                            translatedEvent.from = msg.context.from;
                            translatedEvent.bPropagate = true;
                            translatedEvent.action = VHL.Msg.Actions.REJECTED_OTHER_DEVICE;
                        }
                        else {
                            /**
                             * Ignore it and do not propgate this event,
                             * for the device which sent this reject.
                             */
                        }
                    }
                }
                else if(msgAction === VHL.Msg.Actions.ACCEPT) { //INVITE was ACCEPTED
                    if(_options.user.device_id === msg.context.to.device_id) {
                        sessionData = msg[msgType].session;
                        if(_mapPartnersSessionData[sessionData.id]) {
                            if(!_mapPartnersSessionData[sessionData.id].invited.device_id) {
                                translatedEvent.sessionData = sessionData;
                                translatedEvent.from = msg.context.from;
                                translatedEvent.bPropagate = true;
                                _mapPartnersSessionData[sessionData.id].invited.device_id =
                                    msg.context.from.device_id;
                                _mapPartnersSessionData[sessionData.id].state =
                                    msgType + "#" + msgAction;
                                _clearChatTimeouts(
                                    sessionData.id, _getChatTimeoutType('INVITE')
                                );
                                _setChatTimeouts(
                                    sessionData.id, _getChatTimeoutType('PAIRING')
                                );
                            } else {
                                /**
                                 * This is for group chat usecase when its a call acceptance
                                 * other than first call acceptance.
                                 */
                                if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
                                    translatedEvent.action = VHL.Msg.Actions.ACCEPT_LATER;
                                    translatedEvent.sessionData = sessionData;
                                    translatedEvent.from = msg.context.from;
                                    translatedEvent.bPropagate = true;
                                } else {
                                    if (_mapPartnersSessionData[sessionData.id].invited.device_id ===
                                        msg.context.from.device_id) {
                                        _log.error("Invite accept recieved from same device."+
                                                    " Stopping propagation to reference app");
                                    } else {
                                        _log.error("Invite accept already recieved from another "+
                                                    "device. Stopping propagation to reference app");
                                    }
                                }
                            }
                        } else {
                            _log.error("Invite accept recieved for a session that does not exist."+
                                        " Stopping propagation to reference app");
                        } // Stop propagation to reference app
                    } else {
                        /**
                         * This message is for tracking invite history. A user sends an
                         * acceptance, rejection and revoke messages to his/her own control
                         * channel.
                         * ** Accept received from my other device **
                         * Change the action of the translated event, as it is different from
                         * accept message received from the device, which accepted the invite.
                         * Propagate this message to Caller to update its UI.
                         * And, clear the timer for other devices.
                         */
                        if(_options.user.uuid === msg.context.from.uuid &&
                            _options.user.device_id !== msg.context.from.device_id) {
                            sessionData = msg[msgType].session;
                            _clearChatTimeouts(sessionData.id, msgType);
                            delete _mapPartnersSessionData[sessionData.id];
                            translatedEvent.sessionData = sessionData;
                            translatedEvent.from = msg.context.from;
                            translatedEvent.bPropagate = true;
                            translatedEvent.action = VHL.Msg.Actions.ACCEPTED_OTHER_DEVICE;
                        }
                        else {
                            /**
                             * Ignore it and do not propgate this event,
                             * for the device which sent this accept.
                             */
                        }
                    }
                }
                else if(msgAction === VHL.Msg.Actions.REVOKE) { //INVITE was REVOKED
                    sessionData = msg[msgType].session;

                    /**
                     * This function is used to check whether current user is an invited user.
                     * @return {boolean}
                     */
                    const _currentUserInvited = () => {
                        const invitedUuid = _mapPartnersSessionData[sessionData.id].invited.uuid;
                        const currentUserId =  _options.user.uuid.toString();
                        if(Array.isArray(invitedUuid)) {
                            return invitedUuid.includes(currentUserId);
                        } else {
                            return invitedUuid.toString() === currentUserId;
                        }
                    }
                    if(_mapPartnersSessionData[sessionData.id]) {
                        if(_mapPartnersSessionData[sessionData.id].inviting.uuid.toString() ===
                           _options.user.uuid.toString()) {
                            /**
                             * I am the inviting user. I have revoked the invite.
                             */
                            if(!_mapPartnersSessionData[sessionData.id].invited.device_id) {
                                /**
                                 * Invited user has not responded to this invite from any
                                 * of the device.
                                 */
                                if(_mapPartnersSessionData[sessionData.id].inviting.device_id !==
                                   _options.user.device_id)
                                {
                                    /**
                                     * I am the inviting user but this is not the device from
                                     * which I sent the invite.
                                     */
                                    translatedEvent.sessionData = sessionData;
                                    translatedEvent.from = msg.context.from;
                                    translatedEvent.bPropagate = true;
                                    _clearChatTimeouts(sessionData.id, msgType);
                                    delete _mapPartnersSessionData[sessionData.id];
                                }
                            } else {
                                _log.error("Invite response already recieved from another "+
                                       "device. Stopping propagation to reference app");
                            }
                        }
                        else if(_currentUserInvited())
                        {
                            /**
                             * I am the invited user. One of my earlier invite is revoked by
                             * the user who send the invite.
                             */
                            translatedEvent.sessionData = sessionData;
                            translatedEvent.from = msg.context.from;
                            translatedEvent.bPropagate = true;
                            _clearChatTimeouts(sessionData.id, msgType);
                            delete _mapPartnersSessionData[sessionData.id];
                        } else {
                            _log.error("Invite revoke received for a user that is not part of" +
                                       " this session. Stopping propagation to reference app");
                        }
                    } else {
                        /**
                         * Log commented, as it was creating confusion.
                         * For the user who revokes invite, his/her session gets cleaned up
                         * in the success calback. So, when the user receives REVOKE event
                         * from PubNub, the if condition fails. And, this error is logged.
                         */
                        /*
                        _log.error("Invite revoke received for a user that is not part of" +
                                   " this session. Stopping propagation to reference app");
                        */
                    }
                }
                else if(msgAction === VHL.Msg.Actions.HISTORY_INVITE_SEND) {
                    // I sent an invite.
                    sessionData = msg[msgType].session;
                    translatedEvent.from = msg.context.from;
                    translatedEvent.to = msg.context.to;
                    translatedEvent.sessionData = sessionData;
                    translatedEvent.sessionAdapter = __constructSessionAdapter(sessionData.id);
                    if(!_mapPartnersSessionData[sessionData.id]) {
                        var invitingUser = msg.context.from;
                        invitingUser.section_id = sessionData.inviting.section_id;
                        _mapPartnersSessionData[sessionData.id] = {
                            "id": sessionData.id,
                            "channel": sessionData.channel,
                            "invited": {
                                "uuid": msg.context.to.uuid,
                                "section_id": sessionData.invited.section_id
                            },
                            "inviting": invitingUser,
                            "group_id": sessionData.group_id,
                            "state": "initiated",
                            "me_role": "inviting",
                            "activity_url": sessionData.activity_url,
                            "activity_id": sessionData.activity_id,
                            "invite_metadata": sessionData.invite_metadata,
                            "enrollment": {
                                "course_id": sessionData.enrollment.course_id,
                                "school_id": sessionData.enrollment.school_id
                            },
                            "callbacks": {},
                            "timeouts": {}
                        };
                        /**
                         * An invite is valid till INVITE_DURATION (specified by reference app).
                         * new_timeout is actual_timeout - time_elapsed. Example:
                         *
                         * actual_timeout = 5 mins
                         * time_elapsed = 3 mins
                         * new_timeout = 2 mins
                         */
                        newTimeout = _getChatInviteTimeout() -
                                     (Date.now() - msg[msgType].timestamp);
                        _setChatTimeouts(
                            sessionData.id, msgType, newTimeout
                        );
                        translatedEvent.bPropagate = true;
                    } else {
                        _log.error("Session data exist for this invite."+
                                   " Stopping propagation to reference app");
                    }
                }
                else if(msgAction === VHL.Msg.Actions.HISTORY_INVITE_RECEIVE) {
                    // I received an invite.
                    sessionData = msg[msgType].session;
                    translatedEvent.from = msg.context.from;
                    translatedEvent.to = msg.context.to;
                    translatedEvent.sessionData = sessionData;
                    translatedEvent.sessionAdapter = __constructSessionAdapter(sessionData.id);
                    if(!_mapPartnersSessionData[sessionData.id]) {
                        invitingUser =  msg.context.from;
                        invitingUser.section_id = sessionData.inviting.section_id;
                        var invitedUser = _deepClone(_options.user);
                        invitedUser.section_id = sessionData.invited.section_id;
                        _mapPartnersSessionData[sessionData.id] = {
                            "id": sessionData.id,
                            "channel": sessionData.channel,
                            "invited": invitedUser,
                            "inviting": invitingUser,
                            "group_id": sessionData.group_id,
                            "state": msgType + "#" + VHL.Msg.Actions.INVITE,
                            "me_role": "invited",
                            "activity_url": sessionData.activity_url,
                            "activity_id": sessionData.activity_id,
                            "invite_metadata": sessionData.invite_metadata,
                            "enrollment": {
                                "course_id": sessionData.enrollment.course_id,
                                "school_id": sessionData.enrollment.school_id
                            },
                            "callbacks": {},
                            "timeouts": {}
                        };
                        /**
                         * An invite is valid till INVITE_DURATION (specified by reference app).
                         * new_timeout is actual_timeout - time_elapsed. Example:
                         *
                         * actual_timeout = 5 mins
                         * time_elapsed = 3 mins
                         * new_timeout = 2 mins
                         */
                        newTimeout = _getChatInviteTimeout() -
                                     (Date.now() - msg[msgType].timestamp);
                        _setChatTimeouts(
                            sessionData.id, msgType, newTimeout
                        );
                        translatedEvent.inviteMetadata = sessionData.invite_metadata;
                        translatedEvent.bPropagate = true;
                    } else {
                        _log.error("Session data exist for this invite."+
                                   " Stopping propagation to reference app");
                    }
                }
            }
            //PAIRING recieved for Partner chat
            else if(msgType === VHL.Msg.Types.PARTNER_CHAT_PAIRING || msgType === VHL.Msg.Types.GROUP_CHAT_PAIRING) {
                if(msg.context.from.uuid !== _options.user.uuid) {
                    if(msg.context.to.device_id === _options.user.device_id || 
                      msgType === VHL.Msg.Types.GROUP_CHAT_PAIRING) {
                        /**
                        * Logic Check - (msg.context.from.uuid !== _options.user.uuid)
                        * In case of partner chat session channels, the sender also receives his message.
                        * This check is used to skip processing messages that were sent by the same user.
                        */
                        var mediaData;
                        if(msgAction === VHL.Msg.Actions.INITIATE) { //PAIRING was initiated
                            // I am invited user.
                            sessionData = msg[msgType].session;
                            if(msg.context.from.device_id ===
                               _mapPartnersSessionData[sessionData.id].inviting.device_id)
                            {
                                /**
                                 * Because in earlier code PAIRING INITIATE event was triggered only once in response of
                                 * first acceptance of call invitation. So late joiner could not complete pairing
                                 * if they accepted call later.
                                 * So now PAIRING INITIATE is triggered for every acceptance
                                 * and is ignored or handled accordingly.
                                 */
                                if (_externalPChatEventHandler) {
                                    if (!_mapPartnersSessionData[sessionData.id].pairingInitiated) {
                                        _mapPartnersSessionData[sessionData.id].pairingInitiated = true;
                                        mediaData = msg[msgType].media;
                                        _mapPartnersSessionData[sessionData.id].inviting.media = {
                                            "session_id": mediaData.session_id
                                        };
                                        _mapPartnersSessionData[sessionData.id].state = msgType + "#" + msgAction;
                                        translatedEvent.from = msg.context.from;
                                        translatedEvent.sessionData = sessionData;
                                        translatedEvent.mediaData = mediaData;
                                        translatedEvent.bPropagate = true;
                                    } else {
                                        _log.info('Ignored PAIRING INITIATE event as call invitation is not accepted yet.');
                                    }
                                } else {
                                    _log.info('Ignored PAIRING INITIATE event as its already handled.');
                                }
                            } else {
                                _log.error("Another user / device initiated pairing for the partner"+
                                           " chat session. Stopping propagation to reference app");
                            }
                        }
                        else if(msgAction === VHL.Msg.Actions.CONFIRM) { //PAIRING was confirmed
                            // I am the inviting user
                            if(_externalMediaOptions.mode === VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER) {
                                sessionData = msg[msgType].session;
                                if(msg.context.from.device_id ===
                                   _mapPartnersSessionData[sessionData.id].invited.device_id) {
                                    mediaData = msg[msgType].media;
                                    _mapPartnersSessionData[sessionData.id].invited.media = {
                                        "token": mediaData.token,
                                        "session_id": mediaData.session_id
                                    };
                                    _mapPartnersSessionData[sessionData.id].state = msgType + "#" + msgAction;
                                    translatedEvent.from = msg.context.from;
                                    translatedEvent.sessionData = sessionData;
                                    translatedEvent.mediaData = mediaData;
                                    translatedEvent.bPropagate = true;
                                } else {
                                    _log.error("Another user / device confirmed pairing for the partner"+
                                               " chat session. Stopping propagation to reference app");
                                }
                            }
                        }
                   } else {
                       _log.error("Pairing message received for another device / user."+
                                   " Stopping propagation to reference app");
                   }
                }
            }
            //MEDIA_STREAM EVENTS received for Partner chat
            else if(msgType === VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM ||
                    msgType === VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM) {
                if(msg.context.from.uuid !== _options.user.uuid &&
                   (VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM === msgType || msg.context.to.device_id === _options.user.device_id)) {
                    translatedEvent.from = msg.context.from;
                    sessionData = msg[msgType].session;
                    mediaData = msg[msgType].media;
                    translatedEvent.sessionData = sessionData;
                    if(msgAction === VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_START) {
                        //Partner started playing recorded MEDIA_STREAM.
                        translatedEvent.bPropagate = true;
                        translatedEvent.mediaData = msg[msgType].media;
                    } else if(msgAction === VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_STOP) {
                        translatedEvent.bPropagate = true;
                    }
                    else if(msgAction === VHL.Msg.Actions.RECORDING_STARTED) {
                        /**
                         * I am the user who did 'not' invoke the startRecording function.
                         * In this case I get an event from PubNub that the media
                         * stream's recording has started.
                         *
                         * Since media stream recording is successfully started, a PubNub message
                         * is sent by the user, who started the recording.
                         */
                        translatedEvent.bPropagate = true;
                        if(sessionData) {
                            _mapPartnersSessionData[sessionData.id].state =
                                                        VHL.Msg.Session.State.RECORDING_STARTED;
                            _mapPartnersSessionData[sessionData.id].current_rec_id =
                                                                        mediaData.recording_id;
                        }
                    }
                    else if(msgAction === VHL.Msg.Actions.RECORDING_STOPPED) {
                        /**
                         * I am the user who did 'not' invoke the stopRecording function.
                         * In this case I get an event from PubNub that the media
                         * stream's recording has stopped.
                         *
                         * Since media stream recording is successfully stopped, a PubNub message
                         * is sent by the user, who stopped the recording.
                         * And now I have to call getRecordingStatus function to start polling
                         * my recording.
                         */
                        translatedEvent.bPropagate = true;
                        _mark(VHL.Msg.PerformanceMetric.mark.start.GET_RECORDING_STATUS);
                        _mediaStreamMgr.getRecordingStatus(_options.user.uuid,
                                                                        mediaData.recording_id);
                        if(sessionData) {
                            _mapPartnersSessionData[sessionData.id].state =
                                                        VHL.Msg.Session.State.RECORDING_STOPPED;
                            if(_mapPartnersSessionData[sessionData.id].current_rec_id ===
                                                                    mediaData.recording_id)
                            {
                                delete _mapPartnersSessionData[sessionData.id].current_rec_id;
                            }
                        }
                    }
                }
            }
            //CONTROL_MESSAGE EVENT received for Partner chat
            else if(msgType === VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE || VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE) {
                if(msg.context.from.uuid !== _options.user.uuid &&
                   (msg.context.to.device_id === _options.user.device_id || msgType === VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE)) {
                    translatedEvent.from = msg.context.from;
                    translatedEvent.sessionData = msg[msgType].session;
                    if(msgAction === VHL.Msg.Actions.MESSAGE) {
                        /**
                         * A control message is being sent to the partner user.
                         */
                        translatedEvent.bPropagate = true;
                        translatedEvent.data = msg[msgType].data;
                    }
                }
            }

            //PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION event recieved for Partner chat
            else if (msgType === VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION) {
              if (msg.context.from.uuid !== _options.user.uuid &&
                msg.context.to.uuid === _options.user.uuid) {
                translatedEvent.from = msg.context.from;
                if (msgAction === VHL.Msg.Actions.SUBMITTED_POST_SESSION) {
                    
                  // A control message is being sent to the partner user.
                  translatedEvent.bPropagate = true;
                  translatedEvent.data = msg[msgType].data;
                }
              }
            }

            /** ###### END OF PARTNER CHAT EVENTS FOR - INVITE, PARING, MEDIA_STREAM & CONTROL_MESSAGE */
        }
        else if(event_type === "STATUS") {
            translatedEvent.type = VHL.Msg.Types.NETWORK_STATUS;
            switch(pubNubEventData.category) {
                case "PNNetworkDownCategory":
                    translatedEvent.action = VHL.Msg.Actions.DOWN;
                    break;
                case "PNNetworkUpCategory":
                    translatedEvent.action = VHL.Msg.Actions.UP;
                    break;
                // Default case to be handled.
            }
            translatedEvent.bPropagate = true;
        }
        else { //TODO - Handle this scenario (error?)
        }

        return translatedEvent;
    }; //End of _translatePubNubEvents()

    /**
    * Fires an event (after translation) to the external system (caller) eventHandler. The eventHandler
    * must have been registered previouly via adapter.subscribeEvents().
    * @param {object} pubNubEventData - Native PubNub event object.
    * @param {string} event_type - "PRESENSE" or "MESSAGE"
    */
    var _fireEvent = function(pubNubEventData, type) {
        var genericEvent = _translatePubNubEvents(pubNubEventData, type);
        if(genericEvent.bPropagate) {
            if(genericEvent.type === VHL.Msg.Types.PARTNER_CHAT_PAIRING ||
               genericEvent.type === VHL.Msg.Types.GROUP_CHAT_PAIRING ||
               genericEvent.type === VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM ||
               genericEvent.type === VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM ||
               genericEvent.type === VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE ||
               genericEvent.type === VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE) {
                if (_externalPChatEventHandler) {
                    _externalPChatEventHandler(genericEvent.sessionData.id, genericEvent);
                }
                //TODO - Else (event handler not found) do we want log an error?
            } else {
                if (_externalEventHandler) { _externalEventHandler(genericEvent); }
                //TODO - Else (event handler not found) do we want log an error?
            }
        }
    };

    var _translateMediaServerEvents = function(type, action, sessionData, mediaData) {
        var translatedEvent = {
            "to": {
                "uuid": sessionData.inviting.uuid,
                "device_id": sessionData.inviting.device_id
            },
            "from": {
                "uuid": sessionData.invited.uuid,
                "device_id": sessionData.invited.device_id
            },
            "type": type,
            "action": action,
            "mediaData": mediaData,
            "sessionData": {
                "id": sessionData.id,
                "channel": sessionData.channel,
                "group_id": sessionData.group_id
            }
        };
        if(sessionData.me_role === "invited") {
            translatedEvent.from = {
                "uuid": sessionData.inviting.uuid,
                "device_id": sessionData.inviting.device_id
            };
            translatedEvent.to = {
                "uuid": sessionData.invited.uuid,
                "device_id": sessionData.invited.device_id
            };
        }
        if (_externalPChatEventHandler) {
            _externalPChatEventHandler(sessionData.id, translatedEvent);
        }
    };

    /**
     * This function creates a presence event.
     * The structure of this event is similar to pubnub's presence event.
     *
     * If any Presence event (JOIN, LEAVE, TIMEOUT) has come from the splitting of INTERVAL
     * event, bPresenceInterval flag will be set to true.
     *
     * Note: bPresenceInterval has been added for DEBUGGING purpose only, and must be removed
     * for Production Server.
     */
    var _constructPresenceEvent = function(event, userid, action) {
        return {
            "channel": event.channel, "subscription": event.subscription,
            "actualChannel": event.actualChannel,
            "subscribedChannel": event.subscribedChannel,
            "timetoken": event.timetoken,
            "occupancy": event.occupancy,
            "timestamp": event.timestamp,
            "action": action,
            "uuid": userid,
            "bPresenceInterval": true
        };
    };

    /**
     * This function is used to update the _mapGroupPresence for presence events.
     *
     * @param action - Presence action - [KOIN, LEAVE, TIMEOUT, INTERVAL].
     * @param channel - groupid of the group for which the presence event occured.
     * @param userid - (optional) userid of user for whom the event occured.
     * @param event - event data.
     */
    var _updateGroupPresenceMap = function(action, channel, userid, event) {
        switch(action) {
            case VHL.Msg.Actions.JOIN:
                if(_mapGroupPresence[channel].occupants[userid]) {
                    // User already logged-in from other device.
                    if(_mapTrackingPresence[channel].occupants[userid]) {
                        _mapTrackingPresence[channel].occupants[userid].device_count += 1;
                    } else {
                        console.log("Error: User NOT PRESENT in _mapTrackingPresence, " +
                                    "but PRESENT in _mapGroupPresence");
                    }
                    _mapGroupPresence[channel].occupants[userid].device_count += 1;
                } else { // First time log-in.
                    _mapGroupPresence[channel].occupants[userid] = {
                        "state" : event.state || {},
                        "device_count": 1
                    };
                    _mapTrackingPresence[channel].occupants[userid] = {
                        "device_count": 1
                    };
                }
                if(_mapGroupPresence[channel].occupants[userid].device_count === 1) {
                    _mapGroupPresence[channel].occupancy += 1;
                }
                break;
            case VHL.Msg.Actions.LEAVE:
            case VHL.Msg.Actions.TIMEOUT:
                if(_mapGroupPresence[channel].occupants[userid]) {
                    if(_mapTrackingPresence[channel].occupants[userid]) {
                        _mapTrackingPresence[channel].occupants[userid].device_count -= 1;
                    } else {
                        console.log("Error: User NOT PRESENT in _mapTrackingPresence, " +
                                    "but PRESENT in _mapGroupPresence");
                    }
                    _mapGroupPresence[channel].occupants[userid].device_count -= 1;
                    if(_mapGroupPresence[channel].occupants[userid].device_count === 0) {
                        _mapGroupPresence[channel].occupancy -= 1;
                    }
                }
                break;
        }
    };

    /**
     * This function translates the interval event for each user into individual
     * JOIN or LEAVE or TIMEOUT event as received from pubnub.
     *
     * For the reference application there are only four presence actions
     * [JOIN, LEAVE, TIMEOUT, STATE-CHANGE].
     */
    var _splitPresenceIntervalEvent = function(eventData) {
        var joinedUsers = eventData.join;
        var leftUsers = eventData.leave;
        var timeoutUsers = eventData.timeout;
        var channel = eventData.channel;
        var userid;
        if(joinedUsers) {
            for(var i in joinedUsers) {
                var joinEvent = _constructPresenceEvent(eventData, joinedUsers[i], "join");

                userid = _safeDecodeUuidSplit(joinedUsers[i])[0];
                if(_mapGroupPresence[channel].occupants[userid]) {
                    joinEvent.state =
                        _mapGroupPresence[channel].occupants[userid].state;
                }
                _fireEvent(joinEvent, "PRESENCE");
            }
        }
        if(leftUsers) {
            for(var j in leftUsers) {
                var leftEvent = _constructPresenceEvent(eventData, leftUsers[j], "leave");
                _fireEvent(leftEvent, "PRESENCE");
            }
        }
        if(timeoutUsers) {
            for(var k in timeoutUsers) {
                var timeoutEvent = _constructPresenceEvent(eventData, timeoutUsers[k],
                                                           "timeout");
                _fireEvent(timeoutEvent, "PRESENCE");
            }
        }
    };

    /**
    * Sets up necessary subscriptions (Pub/Sub) to PUSH channels. To a large extent, subscriptions are
    * driven the student's (instructor's) roster.
    * @param {object} groups - Roster information, provided during initialization, wrapper.setup().
    */
    var _subscribeToPubNubChannels = function(groups) {
        if(_.isArray(groups)) {
            _pubnubClient.subscribe({ // Calling Pubnub SDK
                "channels": groups,
                "withPresence": true
            });

            var privateChatChannels = []; // Array of logged in user's private channel for chat. One channel per group.
            for(var i in groups) {
                /**
                * Private channel naming convention
                * gc_<group_name>.<user-uuid> - Control messages channel
                * gt_<group_name>.<user-uuid> - Text messages channel
                * For example: "gc_course1.1011010101"
                *              "gt_course1.1011010101"
                * where "course1" is the group name & 1011010101 is user uuid.
                */
                privateChatChannels.push(pubNubChannelPrefixes.GROUP_CONTROL + groups[i] + "." + _options.user.uuid);
                privateChatChannels.push(pubNubChannelPrefixes.GROUP_TEXT + groups[i] + "." + _options.user.uuid);
            }
            _pubnubClient.subscribe({ // Calling Pubnub SDK
                channels: privateChatChannels
            });
        } else {
            //TODO
        }
    };

    /**
    * TODO - Subscribes to partner chat session channel. This is a dynamically created channel used
    * for exchanging handshake information.
    * For group chat case, it subscribes to session, control and text channels.
    * @param {string} sessionChannel
    */
     const _subscribeToChatChannel = function(sessionChannel) {
        let channels;
        if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            const channelID = sessionChannel.replace('gs_', '');
            channels = [
                `gc_${channelID}`,
                `gt_${channelID}`,
                `gs_${channelID}`
            ];
        } else {
            channels = [sessionChannel];
        }
        _pubnubClient.subscribe({ channels }); // Calling Pubnub SDK
    };

    /*
     * Registers an Event Handler for recieving Presense & Message events.
     * @param {function} eventHandler - Callback event handler.
     */
    var _registerEventHandler = function(eventHandler) {
        if(eventHandler) { // external event handler provided by the initializer.
            _externalEventHandler = eventHandler; //store the event handler
        } else { //TODO - Handle this situation. Do we want throw an error?.
        }
    };

    /*
     * Registers an Event Handler for recieving Partner Chat events.
     * @param {function} eventHandler - Callback event handler.
     */
    var _registerPChatEventHandler = function(eventHandler) {
        if(eventHandler) { // external event handler provided by the initializer.
            _externalPChatEventHandler = eventHandler; //store the event handler
        } else { //TODO - Handle this situation. Do we want throw an error?.
        }
    };

    /**
    * Subscribes to all the groups of the logged in user's for recieving Presense & Message events.
    * @params groups {Array} - Array of groups to which the user wish to subscribe.
    *
    */
    var _subscribeEvents = function (groups) {
        if(_externalEventHandler) { // check if external event handler has been registered.
            _mark(VHL.Msg.PerformanceMetric.mark.start.SUBSCRIBE);
            _subscribeToPubNubChannels(groups);
        } else { //TODO - Handle this situation. Do we want throw an error?.
        }
    };

    /**
     * This function takes the delta state-change and merge it with
     * previous state from presence map to return the latest state.
     *
     * @params {string} group: groupid of group for which state needs to be synced.
     * @params {object} newState: Delta state update.
     * @returns {object} Synced state.
     */
    var _getMySyncedStateFromMap = function(group, newState) {
        var myUserid = _options.user.uuid;
        var oldState = _deepClone(_mapGroupPresence[group].occupants[myUserid].state);
        //Update previous state (or empty) with passed state information.
        newState = _.extend(oldState, newState);
        //Overriding name as this should NEVER change
        newState.first_name = _options.user.first_name;
        newState.last_name = _options.user.last_name;

        return newState;
    };

    /**
     * This function updates the user's new state in the presence map.
     *
     * @params {string} groupid: User groupid.
     * @params {string} userid: user's unique uuid.
     * @params {object} newState: user's updated state.
     */
    var _updateStateInPresenceMap = function(groupid, userid, newState) {
        if(!_mapGroupPresence[groupid].occupants[userid]) {
            _mapGroupPresence[groupid].occupants[userid] = {
                "state": {}, "device_count": 0
            };
            _mapTrackingPresence[groupid].occupants[userid] = {
                "device_count": 0
            };
        }

        _.extend(_mapGroupPresence[groupid].occupants[userid].state, newState);
    };

    /**
    * Set state (key/value pairs) for current user for ONE group.  Call this function
    * multiple times for multiple groups
    *
    * @param {String} group - Roster groupid, provided during initialization, wrapper.setup().
    * @param {newState} new state - user information as a key/value pair.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                        which is a map of the user state.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                        with statusCode and relavent message.
    */
    /*var _updateUserState = function (group, newState, cbSuccess, cbFailure) {
        var err;
        var myUserid = _options.user.uuid;

        // Saving old state to revert in case of failure.
        var oldState = _deepClone(_mapGroupPresence[group].occupants[myUserid].state);

        newState = _getMySyncedStateFromMap(group, newState);
        _updateStateInPresenceMap(group, myUserid, newState);

        // This will be used to make unique start & end mark.
        var currentTimeStamp = Date.now();
        _mark(VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + group + "." + currentTimeStamp);
        _pubnubClient.setState({ //Call the PubNub SDK
            "state": newState,
            "channels": [group]
        }, function(status, response) {
            if(status.error) { //Failure to update state in PubNub
                // Reverting to old state.
                _updateStateInPresenceMap(group, myUserid, oldState);
                _clearMarks([
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + group + "." + currentTimeStamp
                ]);
                if(cbFailure && typeof cbFailure === "function") {
                    err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.STATE,
                        VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    cbFailure(err);
                }
            } else {
                // cannot call _endPerformanceMetric, as this metric has more data.
                _mark(VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + group +
                      "." + currentTimeStamp);
                _measure(
                    VHL.Msg.PerformanceMetric.measure.SET_STATE,
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + group + "." + currentTimeStamp,
                    VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + group + "." + currentTimeStamp
                );
                _clearMarks([
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + group + "." + currentTimeStamp,
                    VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + group + "." + currentTimeStamp
                ]);

                if(cbSuccess && typeof cbSuccess === "function") {
                    cbSuccess(response.state); //return the updated state
                }
            }
        });

    };*/

    var _updateUserState = function (groups, newState, cbSuccess, cbFailure) {
        var err;
        var myUserid = _options.user.uuid;

        var oldState = {}, newStateForAGroup, channels = [];
        // This will be used to make unique start & end mark.
        var currentTimeStamp = Date.now();
        var randomNumberForMetric = Math.floor(1000 + Math.random() * 9000);
        // Saving old state to revert in case of failure.
        for(var i in groups) {
            oldState[groups[i]] = _deepClone(_mapGroupPresence[groups[i]].occupants[myUserid].state);
            newStateForAGroup = _getMySyncedStateFromMap(groups[i], newState);
            _updateStateInPresenceMap(groups[i], myUserid, newStateForAGroup);
        }
        _mark(VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp);
        newState = _transformLongFormToShortForm(newState);
        _pubnubClient.setState({ //Call the PubNub SDK
            "state": newState,
            "channels": groups
        }, function(status, response) {
            if(status.error) { //Failure to update state in PubNub
                // Reverting to old state.
                for(var i in groups) {
                    _updateStateInPresenceMap(groups[i], myUserid, oldState[groups[i]]);
                }
                _clearMarks([
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp
                ]);
                if(cbFailure && typeof cbFailure === "function") {
                    err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.STATE,
                        VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    cbFailure(err);
                }
            } else {
                _mark(VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + randomNumberForMetric +
                      "." + currentTimeStamp);
                _measure(
                    VHL.Msg.PerformanceMetric.measure.SET_STATE,
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp,
                    VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp
                );
                _clearMarks([
                    VHL.Msg.PerformanceMetric.mark.start.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp,
                    VHL.Msg.PerformanceMetric.mark.end.SET_STATE + "." + randomNumberForMetric + "." + currentTimeStamp
                ]);

                if(cbSuccess && typeof cbSuccess === "function") {
                    response.state = _transformShortFormToLongForm(response.state);
                    cbSuccess(response.state); //return the updated state
                }
            }
        });

    };

    /**
    * Call this function for a FIRST INITIALIZATION (post login / or to recover from error / etc.). This
    * updates the logged in user state to AVAILABLE & IDLE across all groups.
    * state - AVAILABLE - user online state
    */
    var _initializeMyStateAcrossAllGroups = function(cbSuccess, cbFailure) {
        /** Update username of the connected user. */
        var defaultState = {
            "first_name": _options.user.first_name,
            "last_name": _options.user.last_name,
            "state": VHL.Msg.User.State.AVAILABLE
//            "isTyping": false
        };

        /*
         * We're going update the state for 'set of groups' having same state at a time.
         * These calls will be sent in parallel. Success and Failure for each will need
         * to be tracked and merged into an overall SUCCESS or FAILURE.
         */

        var errorObj;
        var groupArray = Object.keys(_mapGroupPresence); // Fetching all the groupid
        var myUUID = _options.user.uuid;
        /**
         * PubNub's SDK allows you to set a single/same state across multiple groups in one go.
         *
         * A hashmap is used to gather PubNub channels that have same state (AVAILABLE, BUSY, etc).
         *
         * For future requirements this approach also supports a user to be AVAILABLE in group_1
         * and BUSY in group_2.
         *
         * myStatesAcrossGroups = {
         *      <unique_state>: {
         *          state: { first_name: "", last_name: "", state: <unique_state> },
         *          groups: ["group_1", "group_2"]
         *      }
         * };
         *
         * Example:
         * myStatesAcrossGroups = {
         *      "AVAILABLE": {
         *          state: { first_name: "..", last_name: "..", state: "AVAILABLE" },
         *          groups: ["group-1", "group-2", "group-5"]
         *      },
         *      "BUSY": {
         *          state: { first_name: "..", last_name: "..", state: "BUSY" },
         *          groups: ["group-3", "group-4"]
         *      }
         * };
         */
        var myStatesAcrossGroups = {};
        for(var k in groupArray) {
            var currentState = _mapGroupPresence[groupArray[k]].occupants[myUUID].state;
            if(_.isEmpty(currentState)) { currentState = defaultState; }
            // first group, with new state
            if(!myStatesAcrossGroups[currentState.state]) {
                myStatesAcrossGroups[currentState.state] = {
                    state: currentState,
                    groups: [groupArray[k]]
                };
            }
            // other groups, having same state
            else {
                myStatesAcrossGroups[currentState.state].groups.push(groupArray[k]);
            }
        }
        /**
        * _updateUserState : This function makes an async call to the pubnub SDK for updating
        * state of a user in an array of groups. (Each array of groups, will have a different state)
        * A counter "uniqueStatesCount" is used to determine the number of unique states for which
        * the state update is pending (have not received a response from PubNub yet).
        */
        var uniqueStatesCount = Object.keys(myStatesAcrossGroups).length; // Number of async requests to pubnub SDK.
        for(var key in myStatesAcrossGroups) {
            _updateUserState(
                myStatesAcrossGroups[key].groups,
                myStatesAcrossGroups[key].state,
                function success() {
                    uniqueStatesCount = uniqueStatesCount - 1;
                    if(uniqueStatesCount === 0) {
                        if(errorObj) { cbFailure(errorObj); }
                        else { cbSuccess(); }
                    }
                },
                function error(err) {
                    uniqueStatesCount = uniqueStatesCount - 1;
                    errorObj = err;
                    if(uniqueStatesCount === 0) { cbFailure(errorObj); }
                }
            );
        }
    };

    /**
    * Call this function to make a new client adaptor.
      This adapter exposes functions to send message, update user state etc.
    * @return (object) : client adapter.
    */
    var _constructClientAdaptor = function() {
        //Returning the adaptor (Plain Javascript object)
        return {
            "authorizePubnubChannel": __authorizePubnubChannel,
            "getRoster": __getRoster,
            "getPubnubUUID": __getPubnubUUID,
            "getUserInformation": __getUserInformation,
            "getOnlineMembers": __getOnlineMembers,
            "sendMessage": __sendMessage,
            "sendGroupMessage": __sendGroupMessage,
            "sendSubmittedMessagePostSession": __sendSubmittedMessagePostSession,
            "updateMyState": __updateMyState,
            "initiateGroupChat": __initiateGroupChat,
            "initiatePartnerChat": __initiatePartnerChat,
            "constructSessionAdapter": __constructSessionAdapter,
            "joinPartnerChatSession": __joinPartnerChatSession,
            "retrieveMessageHistory": __retrieveMessageHistory,
            "getUserState": __getUserState,
            "updateMyStateMultiGroups": __updateMyStateMultiGroups,
            "getPubNubClient": __getPubNubClient,
            "setPubNubClient": __setPubNubClient
        };
    };

    /**
    * Function to return a handler that listens to events specific to
    * partner chat media stream.
    */
    var _mediaStreamManagerEventHandler = function(sessionId, event) {
        var sessionData = _mapPartnersSessionData[sessionId];
        var payload, mediaData;
        switch(event.type) {
            case VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_MEDIA_STREAM:
            case VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_MEDIA_STREAM:
                switch(event.action) {
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_COMPLETED:
                        _endPerformanceMetric("GET_RECORDING_STATUS");
                        var recordingId = event.mediaStreamData.recording_id;
                        var urlPaths = event.mediaStreamData.url;
                        if(_mapPartnersSessionData[sessionId]) {
                            _mapPartnersSessionData[sessionId].recordings[recordingId] = {
                                url: urlPaths
                            };
                            mediaData = {
                                "recording_id": recordingId,
                                "url": urlPaths
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.COMBINE_COMPLETE, sessionData, mediaData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_FAILED:
                        _endPerformanceMetric("GET_RECORDING_STATUS");
                        if(_mapPartnersSessionData[sessionId]) {
                            var mediaData = {
                                "recording_id": event.mediaStreamData.recording_id
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.COMBINE_FAILED, sessionData, mediaData
                            );
                            delete _mapPartnersSessionData[sessionId].recordings[recordingId];
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.COMBINE_POLLING_TIMEOUT:
                        // recording status call timed-out, no need to calculate metric.
                        _clearMarks([VHL.Msg.PerformanceMetric.mark.start.GET_RECORDING_STATUS])
                        if(_mapPartnersSessionData[sessionId]) {
                            var mediaData = {
                                "recording_id": event.mediaStreamData.recording_id
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.COMBINE_POLLING_TIMEOUT, sessionData, mediaData
                            );
                            delete _mapPartnersSessionData[sessionId].recordings[recordingId];
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.STREAM_TERMINATED:
                        /**
                         * Partner chat session was terminated.
                         */
                        if(sessionData) {
                            /**
                             * I am the user who did 'not' invoke the endSession function.
                             * In this case I get an event from TokBox that my
                             * partner's stream is termintaed.
                             *
                             * Since media stream session is successfully terminated, an
                             * event is emitted.
                             */
                          var mediaData = {
                            "student_id_stream_terminated": event.mediaStreamData.user_id
                          };
                          if (event.type === VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_MEDIA_STREAM){
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.TERMINATE, sessionData
                            );
                          } else {
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.STREAM_TERMINATED, sessionData, mediaData
                            );
                          }
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.RECORDING_PLAYBACK_COMPLETE:
                        /**
                         * Recording Playback completed.
                         */
                        if(sessionData) {
                            _mapPartnersSessionData[sessionData.id].state =
                                VHL.Msg.Session.State.RECORDING_PLAYBACK_STOPPED;
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.RECORDING_PLAYBACK_COMPLETE,
                                sessionData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.AUDIO_LEVEL_UPDATED:
                        if(_mapPartnersSessionData[sessionId]) {
                            mediaData = {
                                "audio_level": event.mediaStreamData.audio_level
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.AUDIO_LEVEL_UPDATED, sessionData, mediaData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTING:
                        if(_mapPartnersSessionData[sessionId]) {
                            mediaData = {
                                "event_data": event.mediaStreamData.event_data
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.MEDIA_SESSION_RECONNECTING, sessionData, mediaData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_RECONNECTED:
                        if(_mapPartnersSessionData[sessionId]) {
                            mediaData = {
                                "event_data": event.mediaStreamData.event_data
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.MEDIA_SESSION_RECONNECTED, sessionData, mediaData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.SESSION_DISCONNECTED:
                        if(_mapPartnersSessionData[sessionId]) {
                            mediaData = {
                                "event_data": event.mediaStreamData.event_data
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.MEDIA_SESSION_DISCONNECTED, sessionData, mediaData
                            );
                        }
                        break;
                    case VHL.Msg.MediaStream.Events.Actions.GENERIC_ERROR:
                        if(_mapPartnersSessionData[sessionId]) {
                            mediaData = {
                                "event_data": event.mediaStreamData.event_data
                            };
                            _translateMediaServerEvents(
                                event.type,
                                VHL.Msg.Actions.MEDIA_GENERIC_ERROR, sessionData, mediaData
                            );
                        }
                        break;
                }
                break;
            case VHL.Msg.MediaStream.Events.Types.PARTNER_CHAT_PAIRING:
            case VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_PAIRING:
                switch(event.action) {
                    case VHL.Msg.MediaStream.Events.Actions.PARTNER_STREAM_CREATED:
                        _mapPartnersSessionData[sessionData.id].bPartnerStreamCreated = true;
                        mediaData = {
                            "session_id": event.session_id
                        };
                        if(_mapPartnersSessionData[sessionData.id].me_role === "inviting") {
                            _translateMediaServerEvents(
                                VHL.Msg.Types.PARTNER_CHAT_PAIRING, VHL.Msg.Actions.CONFIRM,
                                sessionData, mediaData
                            );
                        } else {
                            if(_mapPartnersSessionData[sessionData.id].bPartnerStreamCreated &&
                              _mapPartnersSessionData[sessionData.id].bMediaServerConnection) {
                              if (_mapPartnersSessionData[sessionData.id].callbacks.createMediaStream) {
                                _mapPartnersSessionData[sessionData.id].callbacks.createMediaStream.cbSuccess(mediaData);
                                delete _mapPartnersSessionData[sessionData.id].callbacks.createMediaStream;
                              }
                              /** For GroupChat the playPartnerMediaStream is commented inside the call of:
                               *  _mapPartnersSessionData[sessionData.id].callbacks.createMediaStream.cbSuccess(mediaData)
                               *  The reason is that we will have more than a partner stream to a maximum of 6.
                               *  So we handle the playing of those here.
                               */
                              if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
                                let group_chat_view = new GroupChatView();
                                group_chat_view.chat_controller.get_pChatAdapter().playPartnerMediaStream(function() {
                                  console.log('Recipient playing media stream.');
                                }, function(err) {
                                  console.log('Error playing recipient media stream', err);
                                });
                              } 
                            }
                        }
                        break;
                }
                break;
        }
    };

    /**
     * This function is used to clear timeouts.
     *
     * @params sessionId {string} - A unique id assigned to a partner chat session.
     * @params action {string} - A unique string to identify the timeout.
     */
    var _clearChatTimeouts = function (sessionId, action) {
        var timerIdKey;
        switch(action) {
            case VHL.Msg.Actions.PARTNER_CHAT_INVITE:
            case VHL.Msg.Actions.GROUP_CHAT_INVITE:
                timerIdKey = "invite_timeout_id";
                break;
            case VHL.Msg.Actions.PARTNER_CHAT_PAIRING:
            case VHL.Msg.Actions.GROUP_CHAT_PAIRING:
                timerIdKey = "pairing_timeout_id";
                break;
        }
        if(timerIdKey && _mapPartnersSessionData[sessionId]) {
            clearTimeout(_mapPartnersSessionData[sessionId].timeouts[timerIdKey]);
            delete _mapPartnersSessionData[sessionId].timeouts[timerIdKey];
        }
    }

    /**
     * This function is used to set timeouts. We have two timers.
     * (1). Invite timer - Time within which a user should accept / reject an invite.
     * (2). Pairing Timer - Time within which media-streams should get paired.
     *
     * @params sessionId {string} - A unique id assigned to a partner chat session.
     * @params action {string} - A unique string to identify the timeout.
     * @params duration {integer} - unix epoch timestamp in ms.
     */
    var _setChatTimeouts = function (sessionId, action, duration) {
        var duration, timerIdKey;
        switch(action) {
            case VHL.Msg.Actions.PARTNER_CHAT_INVITE:
                duration = duration || VHL.Msg.PartnerChatTimeouts.Duration.INVITE;
                timerIdKey = "invite_timeout_id";
                break;
            case VHL.Msg.Actions.PARTNER_CHAT_PAIRING:
                duration = duration || VHL.Msg.PartnerChatTimeouts.Duration.PAIRING;
                timerIdKey = "pairing_timeout_id";
                break;
            case VHL.Msg.Actions.GROUP_CHAT_INVITE:
                duration = duration || VHL.Msg.GroupChatTimeouts.Duration.INVITE;
                timerIdKey = "invite_timeout_id";
                break;
            case VHL.Msg.Actions.GROUP_CHAT_PAIRING:
                duration = duration || VHL.Msg.GroupChatTimeouts.Duration.PAIRING;
                timerIdKey = "pairing_timeout_id";
                break;
        }
        if(timerIdKey) {
            let timerIdValue = _mapPartnersSessionData[sessionId].timeouts[timerIdKey];

            // Set timeout if its not already set.
            if (timerIdValue === undefined) {
                timerIdValue = setTimeout(function() {
                    //send event to customjs
                    var payload = _constructTimeoutEvent(sessionId, action);
                    _fireEvent(payload, "MESSAGE");
                }, duration);
                _mapPartnersSessionData[sessionId].timeouts[timerIdKey] = timerIdValue;
            }
        }
    }

    /**
     * This function creates the payload for the timeout events.
     *
     * @params sessionId {string} - A unique id assigned to a partner chat session.
     * @params action {string} - A unique string to identify the timeout.
     * @returns {object} - Payload for the timeout event.
     */
    var _constructTimeoutEvent = function(sessionId, action) {
        var sessionData = _mapPartnersSessionData[sessionId];
        /**
         * Since this is an internal event both to & from context are for the
         * same devices.
         */
        var payload = {
            "message": {
                "context": {
                    "type": "TIMEOUT"
                },
                "TIMEOUT": {
                    "action": action,
                    "session": {
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id
                    }
                }
            }
        };
        return payload;
    };

    /**
     * This function is used to update the private chat map.
     * @param {string} targetUserId - target user's uuid
     * @param {string} group - group's unique id
     * @param {string} timetoken - pubnub's timetoken used to reference last message's publish time.
     */
    var _updatePrivateChatMap = function(targetUserId, group, timetoken) {
        timetoken = timetoken || _getPrivateChatLastTimetoken(targetUserId, group);
        _mapPrivateChatHistory[group][targetUserId].last_timetoken = timetoken;
    };

    /**
     * This function is used to update the private chat map.
     *
     * @param {string} targetUserId - target user's uuid
     * @param {string} group - group's unique id
     *
     * @returns {string} pubnub's timetoken used to reference last message's publish time.
     */
    var _getPrivateChatLastTimetoken = function(targetUserId, group) {
        if(!_mapPrivateChatHistory[group]) {
            _mapPrivateChatHistory[group] = {};
        }
        if(!_mapPrivateChatHistory[group][targetUserId]) {
            _mapPrivateChatHistory[group][targetUserId] = {
                "in_process": false,
                "last_timetoken": _setupTimetoken
            };
        }
        return _mapPrivateChatHistory[group][targetUserId].last_timetoken;
    }

    /**
     * This function tell if a text-message history retrieval is in process.
     *
     * @param {string} targetUserIdentifier - UUID of target user.
     * @param {string} group - unique group identifier.
     *
     * @returns {boolean} - check result.
     */
    var _isHistoryRetrievalInProcess = function(targetUserId, group) {
        if(!_mapPrivateChatHistory[group]) { _mapPrivateChatHistory[group] = {}; }
        if(!_mapPrivateChatHistory[group][targetUserId]) {
            _mapPrivateChatHistory[group][targetUserId] = {
                "in_process": false, "last_timetoken": _setupTimetoken
            }
        }
        return _mapPrivateChatHistory[group][targetUserId].in_process;
    };

    /**
     * This function converts unix epoch timestamp (ms) to pubnub's timetoken.
     *
     * @params {integer} timestamp - unix epoch timestamp (ms)
     *
     * @returns {string} - Pubnub's timetoken (timestamp = timetoken / 10000).
     */
    var _getPubnubTimeToken = function(timestamp) {
        return (timestamp * 10000).toString();
    };

    /**
     * This function converts pubnub's timetoken to unix epoch timestamp (ms).
     *
     * @params {string} timetoken - Pubnub's timetoken (timestamp = timetoken / 10000).
     *
     * @returns {integer} - unix epoch timestamp (ms).
     */
    var _getEpochTimestamp = function(timetoken) {
        return Math.round(parseInt(timetoken) / 10000);
    };

    /**
     * This function returns the history of messages of a targetuser.
     *
     * @param {string} group - unique group identifier.
     * @param {string} targetUserIdentifier - UUID of target user.
     * @param {integer} limit - Number of messages to be retrieved.
     * @param {boolean} bWaitForAll - TRUE: Send all the messages at once.
     *                                FALSE: Send multiple batches of messages until limit reached.
     * @param {array} msgArray - Array to store messages
     * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                      which is an array of target user's message history.
     * @param {function} cbFailure - (Optional) A function that accepts an error object
                                      with statusCode and relavent message.
     */
    var _getMessageHistory = function(group, targetUserIdentifier, limit, bWaitForAll, msgArray,
         cbSuccess, cbFailure)
    {
        var textChatChannel = pubNubChannelPrefixes.GROUP_TEXT + group + "." + _options.user.uuid;
        var startTime = _getPrivateChatLastTimetoken(targetUserIdentifier, group);
        if(!_mapPrivateChatHistory[group][targetUserIdentifier].bEndReached) {
            _pubnubClient.history(
                {
                    channel: textChatChannel,
                    stringifiedTimeToken: true,
                    start: startTime,
                    end: _historyEndTimetoken
                },
                function (status, response) {
                    if(status.error) {
                        // handle error
                        if(cbFailure && typeof cbFailure === "function") { cbFailure(response); }
                    } else {
                        var messageSet = response.messages.reverse();
                        if(messageSet.length === 0) {
                            // End of history storage reached.
                           _mapPrivateChatHistory[group][targetUserIdentifier].bEndReached = true;
                            if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(msgArray); }
                            return;
                        }
                        var lastTimetoken = messageSet[messageSet.length - 1].timetoken;
                        // Filtering messages of target user.
                        var targetUserMessages = messageSet.filter(isTargetUserInMessage);
                        // Getting messages upto user defined limit from filtered messages.
                        targetUserMessages = targetUserMessages.slice(0, limit);
                        limit -= targetUserMessages.length;
                        // Pushing messages to last array.
                        msgArray = msgArray.concat(targetUserMessages);

                        /**
                         * PubNub can paginate results from 1 to 100 page size.
                         * However, ClientWrapper always paginates historical messages
                         * in page sizes of 100, for maximum performance.
                         */
                        if(messageSet.length < 100) {
                            if(limit === 0) {
                                // limit set by caller reached.
                                lastTimetoken = targetUserMessages[targetUserMessages.length - 1].timetoken;
                                if(messageSet[messageSet.length - 1].timetoken === lastTimetoken) {

                                    // End of history storage reached.
                                    _mapPrivateChatHistory[group][targetUserIdentifier].bEndReached = true;
                                }
                                _updatePrivateChatMap(targetUserIdentifier, group, lastTimetoken);
                                if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(msgArray); }
                            } else {
                                // End of history storage reached.
                                _mapPrivateChatHistory[group][targetUserIdentifier].bEndReached = true;
                                _updatePrivateChatMap(targetUserIdentifier, group, lastTimetoken);
                                if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(msgArray); }
                            }
                        } else {
                            // More messages available in history storage.
                            if(bWaitForAll) {
                                // Wait for all the messages (upto limit set by caller), or end of history storage.
                                if(limit === 0) {
                                    // limit set by caller reached.
                                    lastTimetoken = targetUserMessages[targetUserMessages.length - 1].timetoken;
                                    _updatePrivateChatMap(targetUserIdentifier, group, lastTimetoken);
                                    if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(msgArray); }
                                } else {
                                    /**
                                     * limit set by caller not reached. Getting next set of
                                     * messages from history storage.
                                     */
                                    _updatePrivateChatMap(targetUserIdentifier, group, lastTimetoken);
                                    _getMessageHistory(group, targetUserIdentifier, limit, bWaitForAll,
                                                       msgArray, cbSuccess, cbFailure);
                                }
                            } else {
                                /**
                                 * Do not wait for all the messages, or end of history storage.
                                 * Send the current batch.
                                 */
                                if(targetUserMessages.length === 0) {
                                    /**
                                     * The current batch doesn't have any messages of the
                                     * target user.
                                     */
                                    _updatePrivateChatMap(targetUserIdentifier, group, lastTimetoken);
                                    _getMessageHistory(group, targetUserIdentifier, limit, bWaitForAll,
                                                       msgArray, cbSuccess, cbFailure);
                                } else {
                                    if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(messages); }
                                }
                            }
                        }
                    }
                }
            );
        } else {
            if(cbSuccess && typeof cbSuccess === "function") { cbSuccess([]); }
        }

        /**
         * Filter function to return all the text-chat messages that are send or receive by
         * target user
         */
        function isTargetUserInMessage(textMsg) {
            textMsg = textMsg.entry[VHL.Msg.Types.PRIVATE_CHAT];
            return (textMsg.messages[0].to.uuid.toString() === targetUserIdentifier.toString() ||
                    textMsg.messages[0].from.uuid.toString() === targetUserIdentifier.toString());
        }
    };

    /**
     * This function returns the history of my partner chat invites.
     *
     * @param {array} invitesSendReceiveArray - Array of invites that I sent or received.
     * @param {array} inviteResponseArray - Array of invite responses that I sent or received.
     * @param {string} group - unique group identifier.
     * @param {string} startTime - Pubnub timetoken from which the history should be retrieved.
     * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                      which is an array of unresponded invites sent or received by me.
     * @param {function} cbFailure - (Optional) A function that accepts an error object
                                      with statusCode and relavent message.
     */
    var _getInviteHistory = function(invitesSendReceiveArray, inviteResponseArray, group,
         startTime, cbSuccess, cbFailure)
    {
        var controlChannel = pubNubChannelPrefixes.GROUP_CONTROL + group + "." + _options.user.uuid;
        var endTime = _setupTimetoken;
        let inviteTimeout = _getChatInviteTimeout();
        startTime = startTime || _setupTimetoken - _getPubnubTimeToken(inviteTimeout);
        _pubnubClient.history(
            {
                channel: controlChannel,
                stringifiedTimeToken: true,
                start: startTime,
                reverse:true,
                end: endTime
            },
            function (status, response) {
                if (status.error) {
                    // handle error
                    if(cbFailure && typeof cbFailure === "function") { cbFailure(response); }
                } else {
                    var invitesSendReceive, inviteResponse, message, sessionId, index;
                    var messageSet = response.messages;
                    if(messageSet.length === 0) {
                        // End of history storage reached. Compile unresponded invites.
                        for(var i in inviteResponseArray) {
                            const inviteType = inviteResponseArray[i].entry.context.type;
                            message = inviteResponseArray[i].entry[inviteType];
                            sessionId = message.session.id;
                            index = invitesSendReceiveArray.findIndex(getMsgIndexBySessionId(sessionId));
                            if (index > -1) { invitesSendReceiveArray.splice(index, 1); }
                        }
                        if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(invitesSendReceiveArray); }
                        return;
                    }

                    // Filtering invites that were sent or received by me.
                    invitesSendReceive = messageSet.filter(getAllInvitesSentOrReceived);
                    // Pushing messages to last invites array.
                    invitesSendReceiveArray = invitesSendReceiveArray.concat(invitesSendReceive);
                    // Filtering invite responses that were sent or received by me.
                    inviteResponse = messageSet.filter(getAllInviteResponsesSentOrReceived);
                    // Pushing messages to last invite responses array.
                    inviteResponseArray = inviteResponseArray.concat(inviteResponse);

                    /**
                     * PubNub can paginate results from 1 to 100 page size.
                     * However, ClientWrapper always paginates historical messages
                     * in page sizes of 100, for maximum performance.
                     */
                    if(messageSet.length < 100) {
                        // End of history storage reached. Compile unresponded invites.
                        for(var j in inviteResponseArray) {
                            const inviteType = inviteResponseArray[j].entry.context.type;
                            message = inviteResponseArray[j].entry[inviteType];
                            sessionId = message.session.id;
                            index = invitesSendReceiveArray.findIndex(getMsgIndexBySessionId(sessionId));
                            if (index > -1) { invitesSendReceiveArray.splice(index, 1); }
                        }
                        if(cbSuccess && typeof cbSuccess === "function") { cbSuccess(invitesSendReceiveArray); }
                    } else {
                        // More messages available in history storage.
                        startTime = messageSet[messageSet.length - 1].timetoken;
                        // Getting next set of messages from history storage.
                        _getInviteHistory(invitesSendReceiveArray, inviteResponseArray, group,
                                             startTime, cbSuucess, cbFailure);
                    }
                }
            }
        );

        /**
         * Filter function to return all the invites send or receive by me.
         */
        function getAllInvitesSentOrReceived(inviteMsg) {
            const inviteType = inviteMsg.entry.context.type;
            const msg = inviteMsg.entry[inviteType];
            return msg.action === VHL.Msg.Actions.INVITE;
        };

        /**
         * Filter function to return all the invite responses (accept, reject, revoke)
         * send or receive by me.
         */
        function getAllInviteResponsesSentOrReceived(inviteMsg) {
            const inviteType = inviteMsg.entry.context.type;
            const msg = inviteMsg.entry[inviteType];
            return msg.action !== VHL.Msg.Actions.INVITE;
        };

        /**
         * Filter function to return the index of invite if a particular session.
         */
        function getMsgIndexBySessionId(sessionId) {
            return function(element) {
                const inviteType = element.entry.context.type;
                element = element.entry[inviteType];
                return element.session.id === sessionId;
            }
        }
    };

    /**
     * This function retrive invite history and sends invite history events to reference app.
     *
     * @param {string} group - unique group identifier.
     */
    var _processInviteHistory = function(group) {
        _getInviteHistory(
            [], [], group, null,
            function success(pChatInviteMessages) {
                _fireInviteHistoryEvents(pChatInviteMessages);
            },
            function failure(err) {
                _log.error( "Error while fetching invite message history.", null, err);
            }
        );
    };

    /**
     * This function creates payload for invite history events and sends them to reference app.
     *
     * @param {array} msgArray - array of unresponded invites sent or received by me.
     */
    var _fireInviteHistoryEvents = function(msgArray) {
        var msgType = _getChatInviteType();
        var payload = {
            "message": {
                "context": { "type": msgType },
                [msgType]: {}
            }
        };
        for(var i in msgArray) {
            payload.message.context.to = _transformShortFormToLongForm(msgArray[i].entry.context.to);
            payload.message.context.from = _transformShortFormToLongForm(msgArray[i].entry.context.from);
            payload.message[msgType].session = msgArray[i].entry[msgType].session;
            payload.message[msgType].timestamp = _getEpochTimestamp(msgArray[i].timetoken);
            if(msgArray[i].entry.context.from.uuid.toString() === _options.user.uuid.toString()) {
                payload.message[msgType].action = VHL.Msg.Actions.HISTORY_INVITE_SEND
            } else {
                payload.message[msgType].action = VHL.Msg.Actions.HISTORY_INVITE_RECEIVE
            }
            _fireEvent(payload, "MESSAGE");
        }
    };

    /**
     * This function creates a private chat history event.
     *
     * @param {array} messageArray - array of messages retrieved from history.
     * @param {string} targetUserIdentifier - UUID of target user.
     * @param {string} group - unique groupid.
     *
     * @returns {object} - History message event.
     */
    var _constructHistoryMessageEvent = function(messageArray, targetUserIdentifier, group) {
        var msgType = VHL.Msg.Types.PRIVATE_CHAT;
        var payload = {
            "message": {
                "context": { "type": msgType },
                "PRIVATE_CHAT": {
                    "partner_uuid": targetUserIdentifier,
                    "action": VHL.Msg.Actions.HISTORY_MESSAGE,
                    "messages": [],
                    "group": group
                }
            }
        };

        for(var i in messageArray) {
            var chatMessage = messageArray[i].entry[msgType].messages[0];
            var message = {
                "to": chatMessage.to,
                "from": chatMessage.from,
                "text": chatMessage.text,
                "timetoken": messageArray[i].timetoken
            };
            payload.message[msgType].messages.push(message);
        }
        return payload;
    };

    /**
     * This function creates a private chat history complete event.
     *
     * @param {string} targetUserIdentifier - UUID of target user.
     * @param {boolean} bEndReached - TRUE: No more message in storage
     *                                FALSE: More messages availbale in storage.
     * @param {string} group - unique groupid.
     * @param {integer} lastTimestamp - The timestamp till which the history retrieval
     *                                  traversed to fetch the messages.
     *
     * @returns {object} - History retrieval complete event.
     */
    var _constructHistoryRetrievalCompleteEvent = function(targetUserIdentifier, group, bEndReached, lastTimestamp) {
        var payload = {
            "message": {
                "context": { "type": VHL.Msg.Types.PRIVATE_CHAT },
                "PRIVATE_CHAT": {
                    "partner_uuid": targetUserIdentifier,
                    "action": VHL.Msg.Actions.HISTORY_RETRIEVAL_COMPLETE,
                    "status": {
                        // Reached end of history retrieval time duration/period, based on config.message_history_retrieval (e.g. 3 days)
                        "storage_end_reached": bEndReached,
                        // The number of messages requested by the caller (e.g. 10)
                        "limit": _mapPrivateChatHistory[group][targetUserIdentifier].limit,
                        // Total number of messages found (e.g. 10 or 1 or 0)
                        "messages_sent": _mapPrivateChatHistory[group][targetUserIdentifier].messages_sent,
                        // PubNub timetoken upto which history was retrieved/searched
                        "history_retrieved_upto": lastTimestamp
                    },
                    "group": group
                }
            }
        };

        delete _mapPrivateChatHistory[group][targetUserIdentifier].limit;
        delete _mapPrivateChatHistory[group][targetUserIdentifier].messages_sent;

        return payload;
    };

    /**
     * This function is used to transform the short form to the full forms.
     * @private
     * @param   {object} jsonObj The json object to be transformed from.
     * @returns {object} newObj  The transformed object to be returned.
     */
    var _transformShortFormToLongForm = function _transformShortFormToLongForm(jsonObj) {
      if (Array.isArray(jsonObj)) {
        return jsonObj.map( (inner_obj) => _transformShortFormToLongForm(inner_obj) );
      } else {
        var newObj = {};
        if(jsonObj.fn) {
            newObj.first_name = jsonObj.fn;
        }
        if(jsonObj.ln) {
            newObj.last_name = jsonObj.ln;
        }
        if(jsonObj.uuid) {
            newObj.uuid = jsonObj.uuid;
        }
        if(jsonObj.device_id) {
            newObj.device_id = jsonObj.device_id;
        }
        if(jsonObj.state) {
            newObj.state = jsonObj.state;
        }
        if(jsonObj.section_id) {
            newObj.section_id = jsonObj.section_id
        }
        if(jsonObj.media) {
            newObj.media = jsonObj.media;
        }
        return newObj;
      }
    };

    /**
     * This function is used to transform the long form to the short form.
     * @private
     * @param   {object} jsonObj The json object to be transformed from.
     * @returns {object} newObj  The transformed object to be returned.
     */
    var _transformLongFormToShortForm = function _transformLongFormToShortForm(jsonObj) {
      if (Array.isArray(jsonObj)) {
        return jsonObj.map( (inner_obj) => _transformLongFormToShortForm(inner_obj) );
      } else {
        var newObj = {};
        if(jsonObj.first_name) {
            newObj.fn = jsonObj.first_name;
        }
        if(jsonObj.last_name) {
            newObj.ln = jsonObj.last_name;
        }
        if(jsonObj.uuid) {
            newObj.uuid = jsonObj.uuid;
        }
        if(jsonObj.device_id) {
            newObj.device_id = jsonObj.device_id;
        }
        if(jsonObj.state) {
            newObj.state = jsonObj.state;
        }
        if(jsonObj.section_id) {
            newObj.section_id = jsonObj.section_id
        }
        if(jsonObj.media) {
            newObj.media = jsonObj.media;
        }
        return newObj;
      }
    };

    /**
     * This function gathers the error information and returns an error json object.
     * @private
     * @param {object} eventData event data as received from PubNub.
     */
    var _getPresenceErrorDetails = function(eventData) {
        var channelName = eventData.channel;
        var userid = eventData.uuid ? _safeDecodeUuidSplit(eventData.uuid)[0] : undefined;
        var errorDetails = {
            "my_user_id": _options.user.uuid + ":" + _options.user.device_id,
            "error_description": "device_count of undefined or null",
            "presence_event": eventData.action,
            "is_cw_setup": _bInitialized,
            "is_presence_interval": eventData.bPresenceInterval || false,
            "event_for_user_id": eventData.uuid,
            "channel_name": channelName,
            "is_user_in_tracking_map": false
        };
        if (_mapTrackingPresence[channelName] &&
            _mapTrackingPresence[channelName].occupants[userid]) {
            errorDetails.is_user_in_tracking_map = true;
            errorDetails.user_device_count =
                _mapTrackingPresence[channelName].occupants[userid].device_count;
        }

        return errorDetails;
    };
    /** ###### END OF UTILITY FUNCTIONS ############ */

    /** ====== Main Adapter Member functions ==> Mapped to Public Methods */

    /**
    * Gets Presence information (and state) for student's (instructor's) roster. Offline users are
      not support/included in this version.
    * @param {Array} groups - Roster information, provided during initialization, wrapper.setup().
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having group level logged-in
                                               user's presence information.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __getOnlineMembers = function (groups, cbSuccess, cbFailure) {
        var responseObj = {};
        if(_.isEmpty(_mapGroupPresence)) {
            /**
             * _mapGroupPresence is undefined, call pubnub for initialization.
             */
            _mapGroupPresence = {}; // Reset _mapGroupPresence.
            _mapTrackingPresence = {};
            for(var i in groups) {
                _mapGroupPresence[groups[i]] = {
                    "occupants": {}, "name": groups[i], "occupancy": 1
                };
                _mapGroupPresence[groups[i]].occupants[_options.user.uuid] = {
                    "state": {}, "device_count": 1
                };
                // Populating Tracking Map with minimal information
                _mapTrackingPresence[groups[i]] = {
                    "occupants": {}
                };
                _mapTrackingPresence[groups[i]].occupants[_options.user.uuid] = {
                    "device_count": 1
                };
            }
            _mark(VHL.Msg.PerformanceMetric.mark.start.GET_ONLINE_MEMBERS);
            _pubnubClient.hereNow({
                "channels": groups,
                "includeUUIDs": true,
                "includeState": true
            }, function(status, response) {
                if(status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.GET_ONLINE_MEMBERS]);
                    if(cbFailure && typeof cbFailure === "function") {
                        var err = _processError(
                            VHL.Msg.Errors.Source.PUBNUB,
                            VHL.Msg.Errors.Context.PRESENCE,
                            VHL.Msg.Errors.Code.GET_ONLINE_MEMBERS_FAILED,
                            "Pubnub internal error (hereNow). See pubnub_data for more details.",
                            status
                        );
                        cbFailure(err);
                    }
                } else {
                    _endPerformanceMetric("GET_ONLINE_MEMBERS");
                    if(cbSuccess && typeof cbSuccess === "function") {
                        /**
                        * Success callback parameter "response.channels" contains
                        * information on the 'online' users in a group.
                        * For Example:
                        * {
                        *   "course_3": { // group name.
                        *       "occupants": [{ // user info array (array of objects).
                        *           "state": { // state of a user.
                        *               "state": "AVAILABLE",    // User online status
                        *               "fn": "Albert",
                        *               "ln": "Smith"
                        *           },
                        *           "uuid": "102-<device id>"   // Pubnub user uuid
                        *       }],
                        *       "name": "course_3", //group name
                        *       "occupancy": 1      //Total number of logged-in users in this group.
                        *   }
                        * }
                        */
                        for(var channel in response.channels) {
                            var users = response.channels[channel].occupants;
                            for(var j in users) {
                                let decodedUuidSplit = _safeDecodeUuidSplit(users[j].uuid);
                                var userid = decodedUuidSplit[0];
                                var device_id = decodedUuidSplit[1];
                                if(!_mapGroupPresence[channel].occupants[userid]) {
                                    _mapGroupPresence[channel].occupancy += 1;
                                    _mapGroupPresence[channel].occupants[userid] = {
                                        "state": users[j].state || {},
                                        "device_count": 1
                                    };
                                    _mapTrackingPresence[channel].occupants[userid] = {
                                        "device_count": 1
                                    };
                                } else {
                                    if(parseInt(device_id) !== _options.user.device_id) {
                                        if(_mapTrackingPresence[channel].occupants[userid]) {
                                            _mapTrackingPresence[channel].occupants[userid].device_count += 1;
                                        } else {
                                            console.log("Error: User NOT PRESENT in _mapTrackingPresence, " +
                                                        "but PRESENT in _mapGroupPresence");
                                        }
                                        _mapGroupPresence[channel].occupants[userid].device_count += 1;
                                    }
                                    _mapGroupPresence[channel].occupants[userid].state =
                                     _.extend(_mapGroupPresence[channel].occupants[userid].state,
                                              users[j].state);
                                }
                            }
                        }

                        /**
                        * Translated _mapGroupPresence structure
                        * {
                        *   "course_3": { // group name.
                        *       "occupants": { // user info array (array of objects).
                        *           "102": {
                        *               "state": { // state of a user.
                        *                   "state": "AVAILABLE",   //User online status
                        *                   "first_name": "Albert",
                        *                   "first_name": "Smith"
                        *               },
                        *               "device_count": 2
                        *           }
                        *       },
                        *       "name": "course_3", //group name
                        *       "occupancy": 1      //Total number of logged-in users in this group.
                        *   }
                        * }
                        */

                        // Returning a copy of _mapGroupPresence
                        for(var index in groups) {
                            for(var keyUser in _mapGroupPresence[groups[index]].occupants) {
                                var userState = _mapGroupPresence[groups[index]].occupants[keyUser].state;
                                _mapGroupPresence[groups[index]].occupants[keyUser].state =
                                    _transformShortFormToLongForm(userState);
                            }
                            responseObj[groups[index]] = _mapGroupPresence[groups[index]];
                        }
                        cbSuccess(_deepClone(responseObj));

                    }
                }
            });
        } else {
            // Returning a copy of _mapGroupPresence
            for(var index in groups) {
                responseObj[groups[index]] = _mapGroupPresence[groups[index]];
            }
            cbSuccess(_deepClone(responseObj));
        }
    };

    /**
    * Sends a private chat message to the target user in a specific group.
    * @param {string} targetUserIdentifier - UUID of target user.
    * @param {string} group - Group id of the group to which the target user belongs.
    * @param {string} message - Alpha-numeric text message.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    const __sendMessage = function (targetUserIdentifier, group, message, cbSuccess, cbFailure) {
        const channel = pubNubChannelPrefixes.GROUP_TEXT + group + "." + targetUserIdentifier;
        const payload = __getChatMessagePayload(targetUserIdentifier, channel, message);
        var err;
        _mark(VHL.Msg.PerformanceMetric.mark.start.SEND_MESSAGE);
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SEND_MESSAGE]);
                    // handle error
                    err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.TEXT_CHAT,
                        VHL.Msg.Errors.Code.MESSAGE_SEND_FAILED,
                        "Error while sending text-chat message.",
                        status
                    );
                    cbFailure(err);
                } else {
                    _endPerformanceMetric("SEND_MESSAGE");
                    payload.channel = pubNubChannelPrefixes.GROUP_TEXT + group + "." + _options.user.uuid;
                    _pubnubClient.publish( // pubnub SDK called
                        payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.TEXT_CHAT,
                                    VHL.Msg.Errors.Code.MESSAGE_SEND_FAILED,
                                    "Error while sending text-chat message.",
                                    status
                                );
                                cbFailure(err);
                            } else {
                                cbSuccess(response);
                            }
                        }
                    );
                }
            }
        );
    };

    /**
     * Sends a group chat message to other users in a specific group.
     * @param {Array<string>} targetUserIdentifiers - UUIDs of other users.
     * @param {string} group - Group id of the group to which the target users belong.
     * @param {string} message - Alpha-numeric text message.
     * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the message was sent.
     * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
     */
    const __sendGroupMessage = function (targetUserIdentifiers, group, message, cbSuccess, cbFailure) {
        const channel = pubNubChannelPrefixes.GROUP_TEXT + group;
        const payload = __getChatMessagePayload(targetUserIdentifiers, channel, message);
        let err;
        _mark(VHL.Msg.PerformanceMetric.mark.start.SEND_MESSAGE);
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SEND_MESSAGE]);
                    // handle error
                    err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.TEXT_CHAT,
                        VHL.Msg.Errors.Code.MESSAGE_SEND_FAILED,
                        "Error while sending text-chat message.",
                        status
                    );
                    cbFailure(err);
                } else {
                    _endPerformanceMetric("SEND_MESSAGE");
                    cbSuccess(response);
                }
            }
        );
    };

    /**
     * Gets payload for the publishing chat message.
     * @param {string|Array<string>} targetUserIdentifiers - UUID(s) of other users.
     * @param {string} channel - Pubnub channel to publish the message.
     * @param {string} message - Alpha-numeric text message.
     * @return {Object.<string, object>} - message payload
     */
    const __getChatMessagePayload = function (targetUserIdentifier, channel, message) {
        return {
            "message": {
                "context": { "type": VHL.Msg.Types.PRIVATE_CHAT },
                "PRIVATE_CHAT": {
                    "action": VHL.Msg.Actions.NEW_MESSAGE,
                    "messages": [{
                        "text": message,
                        "from": _transformLongFormToShortForm(_options.user),
                        "to": { "uuid": targetUserIdentifier }
                    }]
                }
            },
            "channel": channel,
        };
    };                                     

    /**
    * __sendSubmittedMessagePostSession - This function sends submission message via
    * PubNub Command/Signalling messages to the Partner User.
    * @param {string} targetUserIdentifier - UUID of target user.
    * @param  {String} recipientSectionId   Id of the section shared by the participants.
    * @param {function} cbSuccess - (Optional) A function for send message success.
    * @param {function} cbFailure - (Optional) A function that accepts an error object.
    * with statusCode and relavent message.
    */
    var __sendSubmittedMessagePostSession = function(targetUserIdentifier, recipientSectionId,
      cbSuccess, cbFailure) {
      _log.info("Calling sendSubmittedMessagePostSession, targetUserId:" + targetUserIdentifier);

      // We assume that groupId === sectionId, referring assumption from function startCall
      var groupIdWithPrefix = "section_" + recipientSectionId;
      var msgType = VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION;
      var msgAction = VHL.Msg.Actions.SUBMITTED_POST_SESSION;
      var payload = {
        "message": {
          "context": {
            "type": msgType,
            "from": _transformLongFormToShortForm(_options.user),
            "to": { "uuid": targetUserIdentifier },
          },
          "PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION": {
            "action": msgAction,
            "data": {sectionId: recipientSectionId},
          }
        },
        "channel": pubNubChannelPrefixes.GROUP_CONTROL + groupIdWithPrefix + "." + targetUserIdentifier,
        "storeInHistory": false,
      };
      _mark(VHL.Msg.PerformanceMetric.mark.start.SEND_SUBMITTED_MESSAGE_POST_SESSION);
      _pubnubClient.publish(
        payload,
        function(status, response) {
          if (status.error) {
            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SEND_SUBMITTED_MESSAGE_POST_SESSION]);
            var pchatControlMessageFailedErr = _processError(
              VHL.Msg.Errors.Source.PUBNUB,
              VHL.Msg.Errors.Context.PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION,
              VHL.Msg.Errors.Code.MESSAGE_SEND_FAILED,
              "Pubnub internal error. See pubnub_data for more details.",
              status
            );
            if (cbFailure && typeof cbFailure === "function") {
              cbFailure(pchatControlMessageFailedErr);
            }
          } else {
            _endPerformanceMetric("SEND_SUBMITTED_MESSAGE_POST_SESSION");
            if (cbSuccess && typeof cbSuccess === "function") {
              cbSuccess();
            }
          }
        }
      );
    };

    /**
    * Set state (key/value pairs) for current user for ONE group.
    *
    * @param {String} group - Roster groupid, provided during initialization, wrapper.setup().
    * @param {newState} new state - user information as a key/value pair.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                        which is a map of the user state.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                        with statusCode and relavent message.
    */
    var __updateMyState = function (group, newState, cbSuccess, cbFailure) {
        var err;
        if(newState.state && !VHL.Msg.User.State[newState.state]) {
            err = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.STATE,
                VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                "Unsupported value for state (available, busy, idle)"
            );
            if(cbFailure && typeof cbFailure === "function") {
                cbFailure(err);
            }

        } else {
            if(_mapGroupPresence[group]) {
                var myUserid = _options.user.uuid;
                newState = _getMySyncedStateFromMap(group, newState);
                if(_isStateUpdated(myUserid, group, newState)) {
                    _updateUserState([group], newState, cbSuccess, cbFailure);
                } else {
                    if(cbSuccess && typeof cbSuccess === "function") {
                        cbSuccess(newState);
                    }
                }
            }
            else {
                err = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.STATE,
                    VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                    "User is not enrolled in the group: " + group
                );
                cbFailure(err);
            }
        }
    };

    /**
    * Set state (key/value pairs) for current user for multiple groups.
    *
    * @param {array} groups - Roster groupids, provided during initialization, wrapper.setup().
    * @param {newState} new state - user information as a key/value pair.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                        which is a map of the user state.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                        with statusCode and relavent message.
    */
    var __updateMyStateMultiGroups = function(groups, newState, cbSuccess, cbFailure) {
        var err;
        if(newState.state && !VHL.Msg.User.State[newState.state]) {
            err = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.STATE,
                VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                "Unsupported value for state (available, busy, idle)"
            );
            if(cbFailure && typeof cbFailure === "function") {
                cbFailure(err);
            }

        } else {
            var myUserid = _options.user.uuid;
            if(_.isArray(groups) && groups.length > 0) {
                for(var i in groups) {
                    if(!_mapGroupPresence[groups[i]]) {
                        err = _processError(
                            VHL.Msg.Errors.Source.CLIENTWRAPPER,
                            VHL.Msg.Errors.Context.STATE,
                            VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                            "User is not enrolled in one or more groups: " +
                            JSON.stringify(groups)
                        );
                        cbFailure(err);
                        return;
                    }
                    newState = _getMySyncedStateFromMap(groups[i], newState);
                    if(!_isStateUpdated(myUserid, groups[i], newState)) {
                        groups.pop(groups[i]);
                    }
                }
                if(groups.length > 0){
                    _updateUserState(groups, newState, cbSuccess, cbFailure);
                } else {
                    cbSuccess(newState);
                }
            }
            else {
                err = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.STATE,
                    VHL.Msg.Errors.Code.STATE_UPDATE_FAILED,
                    "Parameter 'groups' is not an array or is an empty array."
                );
                cbFailure(err);
            }
        }
    }

    /**
    * Get state (key/value pairs) for current user for a particular groups.
    *
    * @param {string} user - user's uuid.
    * @param {string} group - Roster groupid, provided during initialization, wrapper.setup().
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                        which is a map of the user state.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                        with statusCode and relavent message.
    * @returns {object} user state.
    */
    var __getUserState = function(user, group, cbSuccess, cbFailure) {
        _log.info("Calling getUserState");
        var groupObj = _mapGroupPresence[group];
        if(groupObj) {
            var userId = _mapGroupPresence[group].occupants[user] ? user : undefined;
            if(userId) {
                var state = _mapGroupPresence[group].occupants[userId].state;
                cbSuccess(state);
            }
            else {
                var errMsg = "User: " + user + " in Group: " + group + " is not present in " +
                    "my roster (my uuid is: " + _options.user.uuid + "). " + "Users present in " +
                    "the Group are: ";
                errMsg += JSON.stringify(Object.keys(_mapGroupPresence[group].occupants));
                var error = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.STATE,
                    VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                    errMsg
                );
                cbFailure(error);
            }
        }
        else {
            var errMsg = "Group: " + group + " is not present in my roster (my uuid is: " +
                _options.user.uuid + "). Groups present in my roster are: ";
            errMsg += JSON.stringify(Object.keys(_mapGroupPresence));
            var error = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.STATE,
                VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                errMsg
            );
            cbFailure(error);
        }
    };

    /**
     * Function to return user roster data.
     * @returns {object} Roster data.
     */
    var __getRoster = function () {
        // Create a copy of _options object to avoid passing of reference.
        return _deepClone(_options.roster);
    };

    /**
     * Function to return user information data.
     * @returns {object} User information
     */
    var __getUserInformation = function () {
        // Create a copy of _options object to avoid passing of reference.
        var objCopy = _deepClone(_options);
        return {
            "auth_token": objCopy.auth_token,
            "user": {
              "uuid": objCopy.user.uuid,
              "first_name": objCopy.user.first_name,
              "last_name": objCopy.user.last_name,
            },
            "pubnub": objCopy.pubnub,
            "tokbox": objCopy.tokbox
        };
    };

    /**
     * Every user has a device_id is used to identify the device from which he
     * log-in / log-out.
     *
     * We use <user_uuid>-<device_id> as the pubnub uuid for identifying each pubnub instance.
     * This function is used to return the pubnub_uuid.
     */
    var __getPubnubUUID = function() {
        return _options.user.uuid + ":" + _options.user.device_id;
    };

    /**
     * This function is used to join an existing session using session data
     * received from getJoinPartnerSessionData function of session adapter.
     *
     * @param joinPChatSessionData {object} - session data
     * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
     *                                          which is the session adapter.
     * @param {function} cbFailure - (Optional) A function that accepts an error object
     *                                          with statusCode and relavent message.
     */
    var __joinPartnerChatSession = function(joinPChatSessionData, cbSuccess, cbFailure) {
        var err;
        if(joinPChatSessionData && joinPChatSessionData.channel &&
           joinPChatSessionData.group_id && joinPChatSessionData.id &&
           joinPChatSessionData.inviting_device_id && joinPChatSessionData.inviting_uuid) {
            var sessionStorageData = VHL.Msg.SessionStorage.Manager.getData();
            sessionStorageData = sessionStorageData.data;
            if(sessionStorageData && sessionStorageData.config.joinPartnerChatSession) {
                var invitingUserUUID = joinPChatSessionData.inviting_uuid;
                var groupId = joinPChatSessionData.group_id;
                var sessionId = joinPChatSessionData.id;
                const invitees = joinPChatSessionData.invited_uuid;
                const sectionId = joinPChatSessionData.invited_section_id;
                _mapPartnersSessionData[sessionId] = {
                    "id": sessionId,
                    "channel": joinPChatSessionData.channel,
                    "invited": {
                        "uuid": invitees,
                        "section_id": sectionId,
                    },
                    "inviting": {
                        "uuid": invitingUserUUID,
                        "device_id": joinPChatSessionData.inviting_device_id,
                        "first_name": joinPChatSessionData.inviting_first_name,
                        "last_name": joinPChatSessionData.inviting_last_name,
                        "section_id": joinPChatSessionData.inviting_section_id
                    },
                    "group_id": groupId,
                    "state": "invite-received",
                    "me_role": "invited",
                    "activity_url": joinPChatSessionData.activity_url,
                    "activity_id": joinPChatSessionData.activity_id,
                    "invite_metadata": joinPChatSessionData.invite_metadata,
                    "enrollment": {
                        "course_id": joinPChatSessionData.enrollment.course_id,
                        "school_id": joinPChatSessionData.enrollment.school_id
                    },
                    "callbacks": {}, //Stores callbacks provided by Reference App for this session
                    "timeouts": {},
                    "recordings": {}
                };
                cbSuccess(__constructSessionAdapter(sessionId));
            } else {
                if(typeof cbFailure === "function") {
                    err = _processError(
                        VHL.Msg.Errors.Source.CLIENTWRAPPER,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.JOIN_PARTNER_CHAT_SESSION_FAILED,
                        "config.join_partner_chat_session should Be set to true."
                    );
                    cbFailure(err);
                }
            }
        } else {
            if(typeof cbFailure === "function") {
                err = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                    VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                    "One or more mandatory parameters missing ['channel', 'group_id', 'id'," +
                    " 'inviting_device_id', 'inviting_uuid']"
                );
                cbFailure(err);
            }
        }
    };

    /**
    * Retrieves private chat message history for a target user in a specific group.
    * The function emits the following events
    * (1). TYPE - PRIVATE_CHAT | ACTION - HISTORY_MESSAGE
    * (2). TYPE - PRIVATE_CHAT | ACTION - HISTORY_RETRIEVAL_COMPLETE.
    *
    * @param {string} targetUserIdentifier - UUID of target user.
    * @param {string} group - Group id of the group to which the target user belongs.
    * @param {integer} limit - Number of messages to be retrieved.
    * @param {boolean} bWaitForAll - TRUE: Send all the messages at once.
    *                                FALSE: Send multiple batches of messages until limit reached.
    * @param {object} options - Configuration options.
    */
    var __retrieveMessageHistory = function(targetUserIdentifier, group, limit, bWaitForAll,
     options, cbSuccess, cbFailure)
    {
        if(!_isHistoryRetrievalInProcess(targetUserIdentifier, group)) {
            _mapPrivateChatHistory[group][targetUserIdentifier].in_process = true;
            if(limit === undefined || limit === null) { limit = 10; }
            var limitInMap = _mapPrivateChatHistory[group][targetUserIdentifier].limit;
            _mapPrivateChatHistory[group][targetUserIdentifier].limit = limitInMap || limit;
            // History retrieval is not in process.
            _mark(VHL.Msg.PerformanceMetric.mark.start.RETRIEVE_MESSAGE_HISTORY + "." + group +
                  "." + targetUserIdentifier);
            _getMessageHistory(
                group, targetUserIdentifier,
                limit, bWaitForAll, [],
                function success(messages) {
                    var payload, lastTimestamp;
                    var bEndReached = _mapPrivateChatHistory[group][targetUserIdentifier].bEndReached;
                    if(bWaitForAll) {
                        if(messages.length > 0) {
                            payload = _constructHistoryMessageEvent(messages, targetUserIdentifier, group);
                            _fireEvent(payload, "MESSAGE");
                            lastTimestamp = messages[messages.length -1].timetoken;
                        } else {
                            lastTimestamp = _historyEndTimetoken;
                        }
                        _mapPrivateChatHistory[group][targetUserIdentifier].messages_sent = messages.length;
                        payload = _constructHistoryRetrievalCompleteEvent(targetUserIdentifier, group,
                                   bEndReached, lastTimestamp);
                        _mapPrivateChatHistory[group][targetUserIdentifier].in_process = false;
                        _fireEvent(payload, "MESSAGE");
                    } else {
                        if(messages.length > 0) {
                            payload = _constructHistoryMessageEvent(messages, targetUserIdentifier, group);
                            _fireEvent(payload, "MESSAGE");
                            lastTimestamp = messages[messages.length -1].timetoken;
                        } else {
                            lastTimestamp = _historyEndTimetoken;
                        }
                        _mapPrivateChatHistory[group][targetUserIdentifier].in_process = false;
                        limit -= messages.length;
                        if(limit > 0 && !bEndReached) {
                            __retrieveMessageHistory(targetUserIdentifier, group, limit, bWaitForAll,
                            options);
                        } else {
                            _mapPrivateChatHistory[group][targetUserIdentifier].messages_sent =
                                _mapPrivateChatHistory[group][targetUserIdentifier].limit - limit;
                            payload = _constructHistoryRetrievalCompleteEvent(targetUserIdentifier,
                                       group, bEndReached, lastTimestamp);
                            _fireEvent(payload, "MESSAGE");
                        }
                    }
                },
                function failure(error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.RETRIEVE_MESSAGE_HISTORY +
                                 "." + group + "." +  targetUserIdentifier]);
                    var err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.TEXT_CHAT,
                        VHL.Msg.Errors.Code.MESSAGE_HISTORY_RETRIEVAL_FAILED,
                        "Pubnub internal error. See pubnub-data for more details.",
                        error
                    );
                    if(cbFailure && typeof cbFailure === "function") { cbFailure(err); }
                }
            )
            if(cbSuccess && typeof cbSuccess === "function") {
                cbSuccess({status: "History message retrieval is in-process."});
            }
        } else {
            // A previous history retrieval is in process.
            var err = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.TEXT_CHAT,
                VHL.Msg.Errors.Code.MESSAGE_HISTORY_RETRIEVAL_FAILED,
                "A previous history retrieval is in process."
            );
            if(cbFailure && typeof cbFailure === "function") {
                cbFailure(err);
            }
        }
    }

    /**
    * Initiates partner chat. Creates a session_id and creates an entry corresponding
    * to the session_id in _mapPartnersSessionData.
    *
    * @param {String}   targetUserId - Target user id.
    * @param {String}   groupId - Roster groupid.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                        which is an adapter specific to the session created.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                        with statusCode and relavent message.
    */
    var __initiatePartnerChat = function(targetUserId, sectionId, courseId, groupId, cbSuccess, cbFailure) {
        var sessionId = _options.user.uuid + "_" + targetUserId + "_" + Date.now() +
                        Math.floor(1000 + Math.random() * 9000);
        var sessionChannel = pubNubChannelPrefixes.GROUP_SESSION + groupId + "." + sessionId;
        if(_mapPartnersSessionData[sessionId]) {
            // Error - session already exists.
        } else {
            var invitingUser = _deepClone(_options.user);
            invitingUser.section_id = sectionId;
            // Add session to _mapPartnersSessionData
            _mapPartnersSessionData[sessionId] = {
                "id": sessionId,
                "channel": sessionChannel,
                "invited": {
                    "uuid": targetUserId,
                    "section_id": sectionId
                },
                "inviting": invitingUser,
                "group_id": groupId,
                "activity_url": _activityUrl,
                "activity_id": _activityId,
                "invite_metadata": _inviteMetadata,
                "enrollment": {
                    "course_id": courseId,
                    "school_id": _schoolId
                },
                "state": "initiated",
                "me_role": "inviting",
                "callbacks": {},    //Stores callbacks provided by Reference App for this session
                "timeouts": {},      //stores timer ids for invite & pairing timers
                "recordings": {}
            };
        }

        // getting session adapter for the session id
        var sessionAdapter = __constructSessionAdapter(sessionId);

        cbSuccess(sessionAdapter);
        // TODO - Handle error with cbFailure
    };

    var __initiateGroupChat = function(groupChannelId, invitees,  sectionId, courseId, groupId, cbSuccess, cbFailure) {
        var sessionId = groupChannelId + "_" + Date.now() + Math.floor(1000 + Math.random() * 9000);
        var sessionChannel = pubNubChannelPrefixes.GROUP_SESSION + groupChannelId;
        if(_mapPartnersSessionData[sessionId]) {
            // Error - session already exists.
        } else {
            var invitingUser = _deepClone(_options.user);
            invitingUser.section_id = sectionId;
            // Add session to _mapPartnersSessionData
            _mapPartnersSessionData[sessionId] = {
                "id": sessionId,
                "channel": sessionChannel,
                "invited": {
                    "uuid": invitees,
                    "section_id": sectionId
                },
                "inviting": invitingUser,
                "group_id": groupId,
                "activity_url": _activityUrl,
                "activity_id": _activityId,
                "invite_metadata": _inviteMetadata,
                "enrollment": {
                    "course_id": courseId,
                    "school_id": _schoolId
                },
                "state": "initiated",
                "me_role": "inviting",
                "callbacks": {},    //Stores callbacks provided by Reference App for this session
                "timeouts": {},      //stores timer ids for invite & pairing timers
                "recordings": {}
            };
        }

        // getting session adapter for the session id
        var sessionAdapter = __constructSessionAdapter(sessionId);

        cbSuccess(sessionAdapter);
    };

    /**
     * Expose the PubNub client so it could be used by a different activity
     * other that Partner chat
     */
    const __getPubNubClient = function() {
        if(_pubnubClient === undefined || _pubnubClient === null) {
            console.log('Error: pubnubClient not initialized yet');
        } else {
            return _pubnubClient;
        }
    }

    /**
     * Set the updated Pubnub client so that this will uses the latest updated
     * pubnub client.
     */
    const __setPubNubClient = function(pnubClient) {
        _pubnubClient = pnubClient;
    }

    /**
     * Authorize the pubnub client to access the given channel.
     * @param {string} channelId - pubnub channel Id.
     */
    const __authorizePubnubChannel = function(channelId) {
        console.log('Call authorize pubnub channel');
        if(!VHL.Chat.GroupChatChannelIds.includes(channelId)) {
          VHL.Chat.GroupChatChannelIds.push(channelId);
        }

        // Pubnub subscribe api subscribes all the previously subscribed channels
        // along with new channel. Therefore sending all the previously subscribed
        // channel Ids along with the new channel Id to the authorize api so that
        // that the auth token contains permission for all channel and 403 error does
        // not come in pubnub subscribe api.
        $.ajax({
            "type": "POST",
            "url": '/group_chat_channel/authorize',
            "data": {
                group_chat_channel: VHL.Chat.GroupChatChannelIds,
                program_id: parseInt(VHL.Common.metaTagContent('VHL.program_id')),
                section_id: parseInt(VHL.Common.metaTagContent('VHL.section_id')),
            },
            "dataType": "json",
            "success": (data) => {
                console.log('group chat success:', data);
                VHL.Chat.CONFIG.session = data.pubnub_token_info;
                _pubnubClient.setAuthKey(data.pubnub_token_info.auth_token);
                _pubnubClient.subscribe({
                    channels: [
                        `gc_${channelId}`,
                        `gt_${channelId}`,
                        `gs_${channelId}`
                    ]
                });
            },
            "error": function(data) {
                console.log('group chat channel authorization failed:', data);
            }
        });
    }

    /**
    * Call this function to make a new session adaptor.
      This adapter exposes functions to send message, update user state etc.
    * @return (object) : client adapter.
    */
    var __constructSessionAdapter = function(sessionId) {
        return {
            "getSessionId": function() { return sessionId; }, //Method to get instance specific session id
            "getSessionData": __getSessionData,
            "getJoinPartnerSessionData": __getJoinPartnerSessionData,
            "sendInvite": __sendInvite,
            "rejectInvite":  __rejectInvite,
            "acceptInvite": __acceptInvite,
            "createMediaStream": __createMediaStream,
            "showMyMediaStream": __showMyMediaStream,
            "playPartnerMediaStream": __playPartnerMediaStream,
            "startPairing": __startPairing,
            "confirmPairing": __confirmPairing,
            "revokeInvite": __revokeInvite,
            "endSession": __endSession,
            "startRecording": __startRecording,
            "stopRecording": __stopRecording,
            "startRecordingPlayback": __startRecordingPlayback,
            "startRecordingPlaybackWithPartnerSync": __startRecordingPlaybackWithPartnerSync,
            "stopRecordingPlayback": __stopRecordingPlayback,
            "stopRecordingPlaybackWithPartnerSync": __stopRecordingPlaybackWithPartnerSync,
            "enableAudio": __enableAudio,
            "enableVideo": __enableVideo,
            "sendControlMessage": __sendControlMessage
        };
    };

    /** ###### End Of Main Adapter Member functions ############ */

    /** ====== Partner Chat Adapter Member functions ==> Mapped to Public Methods */

    /**
    * @returns {object} - Session data of the session for which the session adapter was
                          initialized.
    */
    var __getSessionData = function() {
        var sessionId = this.getSessionId();
        if(_mapPartnersSessionData[sessionId]) {
            return {
                "id": _mapPartnersSessionData[sessionId].id,
                "channel": _mapPartnersSessionData[sessionId].channel,
                "invited": _mapPartnersSessionData[sessionId].invited,
                "inviting": _mapPartnersSessionData[sessionId].inviting,
                "group_id": _mapPartnersSessionData[sessionId].group_id,
                "state": _mapPartnersSessionData[sessionId].state,
                "bMediaServerConnection": _mapPartnersSessionData[sessionId].bMediaServerConnection,
                "pairingInitiated": _mapPartnersSessionData[sessionId].pairingInitiated,
                "me_role": _mapPartnersSessionData[sessionId].me_role,
                "activity_url": _mapPartnersSessionData[sessionId].activity_url,
                "activity_id": _mapPartnersSessionData[sessionId].activity_id,
                "invite_metadata": _mapPartnersSessionData[sessionId].invite_metadata,
                "enrollment": {
                    "school_id": _mapPartnersSessionData[sessionId].enrollment.school_id,
                    "course_id": _mapPartnersSessionData[sessionId].enrollment.course_id
                }
            };
        } else {
            return;
        }

    };

    /**
     * @returns {object} - Minimum session data that is required to create a partner
     * chat session.
     */
    var __getJoinPartnerSessionData = function() {
        var sessionData = this.getSessionData();
        return {
            "id": sessionData.id,
            "channel": sessionData.channel,
            "inviting_uuid": sessionData.inviting.uuid,
            "inviting_device_id": sessionData.inviting.device_id,
            "inviting_first_name": sessionData.inviting.first_name,
            "inviting_last_name": sessionData.inviting.last_name,
            "inviting_section_id": sessionData.inviting.section_id,
            "invited_section_id": sessionData.invited.section_id,
            "invited_uuid": sessionData.invited.uuid,
            "group_id": sessionData.group_id,
            "activity_url": sessionData.activity_url,
            "activity_id": sessionData.activity_id,
            "invite_metadata": sessionData.invite_metadata,
            "enrollment": {
                "school_id": sessionData.enrollment.school_id,
                "course_id": sessionData.enrollment.course_id
            }
        };
    };

    /**
    * Sends a partner chat invite to the invited user of the session.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the invite was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __sendInvite = function (chatInviteType, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        var msgType = chatInviteType;
        var msgAction = VHL.Msg.Actions.INVITE;
        var constructPayload = function constructPayload(user_uuid, chat_channel_id) {
          return {
            "message": {
                "context": {
                    "type": msgType,
                    "from": _transformLongFormToShortForm(_options.user),
                    "to": { "uuid": user_uuid }
                },
                [msgType]: {
                    "action": msgAction,
                    "session": {
                        "inviting": _transformLongFormToShortForm(sessionData.inviting),
                        "invited": _transformLongFormToShortForm(sessionData.invited),
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id,
                        "activity_url": sessionData.activity_url,
                        "activity_id": sessionData.activity_id,
                        "invite_metadata": sessionData.invite_metadata,
                        "enrollment": {
                            "school_id": sessionData.enrollment.school_id,
                            "course_id": sessionData.enrollment.course_id
                        }
                    }
                }
            },
            "channel": chat_channel_id,
            "ttl": _pChatInviteTTL
          };
        }; // Payload for the publishing invite message.
        var sendInvidualInvite = function sendInvidualInvite(invite_payload) {
        _mark(VHL.Msg.PerformanceMetric.mark.start.SEND_INVITE);
        _pubnubClient.publish( // pubnub SDK called
            invite_payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SEND_INVITE]);
                    // handle error
                    var err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.SEND_INVITE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    if(cbFailure && typeof cbFailure === "function") {
                        cbFailure(err);
                    }
                } else {
                    _endPerformanceMetric("SEND_INVITE");
                    invite_payload.channel = pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + _options.user.uuid;
                    _pubnubClient.publish( // pubnub SDK called
                        invite_payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                var err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                                    VHL.Msg.Errors.Code.SEND_INVITE_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                if(cbFailure && typeof cbFailure === "function") {
                                    cbFailure(err);
                                }
                            } else {
                                if(_mapPartnersSessionData[sessionData.id]) {
                                    _setChatTimeouts(
                                        sessionData.id, _getChatTimeoutType('INVITE')
                                    );
                                    _mapPartnersSessionData[sessionData.id].state = msgType + "#" +
                                     msgAction;
                                }
                                if(cbSuccess && typeof cbSuccess === "function") {
                                    cbSuccess(response);
                                }
                            }
                        }
                    );
                }
            }
        );
        };
        if (msgType === VHL.Msg.Types.PARTNER_CHAT_INVITE) {
          var payload = constructPayload(sessionData.invited.uuid, 
            pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + sessionData.invited.uuid
          );
          sendInvidualInvite(payload);
        } else if (msgType === VHL.Msg.Types.GROUP_CHAT_INVITE) {
          sessionData.invited.uuid.forEach( (user_uuid) => {
            // TODO: group_id is the section_id, so at the moment we can only group chat with students of the same section.
            var payload = constructPayload(user_uuid, 
              pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + user_uuid);
            sendInvidualInvite(payload);
          } );
        }
    };

    /**
    * Sends a message for rejecting the partner chat invite received from the invited
      user of the session.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the invite reject message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __rejectInvite = function(chatInviteType, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        var msgType = chatInviteType;
        var msgAction = VHL.Msg.Actions.REJECT;
        var payload = {
            "message": {
                "context": {
                    "type": msgType,
                    "from": _transformLongFormToShortForm(_options.user),
                    "to": {
                        "uuid": sessionData.inviting.uuid,
                        "device_id": sessionData.inviting.device_id
                    }
                },
                [msgType]: {
                    "action": msgAction,
                    "session": {
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id
                    }
                }
            },
            "channel": pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + sessionData.inviting.uuid,
            "ttl": _pChatInviteTTL
        }; // Payload for the publishing invite reject message.
        _mark(VHL.Msg.PerformanceMetric.mark.start.REJECT_INVITE);
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.REJECT_INVITE]);
                    // handle error
                    var err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.REJECT_INVITE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    if(cbFailure && typeof cbFailure === "function") {
                        cbFailure(err);
                    }
                } else {
                    _endPerformanceMetric("REJECT_INVITE");
                    payload.channel = pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + _options.user.uuid;
                    _pubnubClient.publish( // pubnub SDK called
                        payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                var err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                                    VHL.Msg.Errors.Code.REJECT_INVITE_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                if(cbFailure && typeof cbFailure === "function") {
                                    cbFailure(err);
                                }
                            } else {
                                if(_mapPartnersSessionData[sessionData.id]) {
                                    _clearChatTimeouts(sessionData.id, msgType);
                                    delete _mapPartnersSessionData[sessionData.id]; // deleting session data for this session from _mapPartnersSessionData.
                                }
                                if(cbSuccess && typeof cbSuccess === "function") {
                                    cbSuccess(response);
                                }
                            }
                        }
                    );
                }
            }
        );
    };

    /**
    * Sends a message for accepting the partner chat invite received from the invited
      user of the session.
    * @param {function} pChatEventHandler - Callback event handler.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the invite accept message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __acceptInvite = function(chatInviteType, pChatEventHandler, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        var msgType = chatInviteType;
        var msgAction = VHL.Msg.Actions.ACCEPT;
        var payload = {
            "message": {
                "context": {
                    "type": msgType,
                    "from": _transformLongFormToShortForm(_options.user),
                    "to": {
                        "uuid": sessionData.inviting.uuid,
                        "device_id": sessionData.inviting.device_id
                    }
                },
                [msgType]: {
                    "action": msgAction,
                    "session": {
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id
                    }
                }
            },
            "channel": pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + sessionData.inviting.uuid,
            "ttl": _pChatInviteTTL
        }; // Payload for the publishing invite accept message.
        _mark(VHL.Msg.PerformanceMetric.mark.start.ACCEPT_INVITE);
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.ACCEPT_INVITE]);
                    // handle error
                    var err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.ACCEPT_INVITE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    if(cbFailure && typeof cbFailure === "function") {
                        cbFailure(err);
                    }
                } else {
                    _endPerformanceMetric("ACCEPT_INVITE");
                    payload.channel = pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + _options.user.uuid;
                    _pubnubClient.publish( // pubnub SDK called
                        payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                var err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                                    VHL.Msg.Errors.Code.ACCEPT_INVITE_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                if(cbFailure && typeof cbFailure === "function") {
                                    cbFailure(err);
                                }
                            } else {
                                if(_mapPartnersSessionData[sessionData.id]) {
                                    _mapPartnersSessionData[sessionData.id].state = msgType + "#" +
                                     msgAction;
                                    _registerPChatEventHandler(pChatEventHandler);
                                    _subscribeToChatChannel(sessionData.channel);
                                    _clearChatTimeouts(sessionData.id, _getChatTimeoutType('INVITE'));
                                    _setChatTimeouts(sessionData.id, _getChatTimeoutType('PAIRING'));
                                }
                                if(cbSuccess && typeof cbSuccess === "function") {
                                    cbSuccess(response);
                                }
                            }
                        }
                    );
                }
            }
        );
    };

    /**
    * Sends a message for revoking the partner chat invite received from the invited
      user of the session.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the invite revoke message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    const __revokeInvite = function(chatInviteType, cbSuccess, cbFailure) {
        const sessionData = this.getSessionData();
        const msgType = chatInviteType;
        const msgAction = VHL.Msg.Actions.REVOKE;

        /**
        * This function returns payload for revoke Invite.
        * @return {Object.<string, Object>}
        */
        const constructPayload = (userUuId) => {
            const channelId = `${pubNubChannelPrefixes.GROUP_CONTROL}${sessionData.group_id}.${userUuId}`;
            return {
                "message": {
                    "context": {
                        "type": msgType,
                        "from": _transformLongFormToShortForm(sessionData.inviting),
                        "to": {
                            "uuid": userUuId,
                            "device_id": sessionData.invited.device_id
                        }
                    },
                    [msgType]: {
                        "action": msgAction,
                        "session": {
                            "id": sessionData.id,
                            "channel": sessionData.channel,
                            "group_id": sessionData.group_id
                        }
                    }
                },
                "channel": channelId,
                "ttl": _pChatInviteTTL
            };
        };

        _mark(VHL.Msg.PerformanceMetric.mark.start.REVOKE_INVITE);


        /**
        * This function revokes the invite for a invited user.
        * @param {Object} payload - payload for revoking invite.
        */
        const revokeIndividualInvite = (payload) => {
            _pubnubClient.publish( // pubnub SDK called
                payload,
                function (status, response) {
                    if (status.error) {
                        _clearMarks([VHL.Msg.PerformanceMetric.mark.start.REVOKE_INVITE]);
                        // handle error
                        var err = _processError(
                            VHL.Msg.Errors.Source.PUBNUB,
                            VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                            VHL.Msg.Errors.Code.REVOKE_INVITE_FAILED,
                            "Pubnub internal error. See pubnub_data for more details.",
                            status
                        );
                        if(cbFailure && typeof cbFailure === "function") {
                            cbFailure(err);
                        }
                    } else {
                        if(_mapPartnersSessionData[sessionData.id]) {
                          postRevokeIndividualInvite(payload, sessionData, cbSuccess, cbFailure);
                        }
                    }

                }
            );
        }

        if (msgType === VHL.Msg.Types.PARTNER_CHAT_INVITE) {
          const payload = constructPayload(sessionData.invited.uuid);
          revokeIndividualInvite(payload);
        } else if (msgType === VHL.Msg.Types.GROUP_CHAT_INVITE) {
          sessionData.invited.uuid.forEach((userUuid) => {
            const payload = constructPayload(userUuid);
            revokeIndividualInvite(payload);
          });
        }
    };

    /**
    * This function revokes invite of the inviting user and clears the partner
    * chat session after revoking invite.
    * @param {Object} payload - payload for revoking invite.
    * @param {Object} sessionData - Session data of the group chat / partner chat
    * session for which  the session adapter was initialized.
    * @param {function} cbSuccess - (Optional) A callback function called on success
    * of revoke invite.
    * @param {function} cbFailure - (Optional) A callback function called on failure
    * of revoke invite.
    */
    const postRevokeIndividualInvite = (payload, sessionData, cbSuccess, cbFailure) => {
        _endPerformanceMetric("REVOKE_INVITE");
        payload.channel = pubNubChannelPrefixes.GROUP_CONTROL + sessionData.group_id + "." + _options.user.uuid;
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    // handle error
                    const err = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.REVOKE_INVITE_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    if(cbFailure && typeof cbFailure === "function") {
                        cbFailure(err);
                    }
                } else {
                    const sessionId = sessionData.id;
                    if(_mapPartnersSessionData[sessionId]) {
                        _clearChatTimeouts(sessionId, _getChatTimeoutType('INVITE'));
                        delete _mapPartnersSessionData[sessionId];
                    }
                    if(cbSuccess && typeof cbSuccess === "function") {
                        cbSuccess(response);
                    }
                }
            }
        );
    }

    /**
    * This function is called to create a LIVE video stream  via an appropriate
    * Streaming Provider (WebRTC).
    *
    * @param {function} cbSuccess - (Optional) A function that accepts a four argument,
                                               which are "session_id" & "token".
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __createMediaStream = function(cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        _log.info("Inside __createMediaStream", sessionData.id);

        // validating for mandatory parameter
        if(_externalMediaOptions.api_key === undefined) {
            // check if cbFailure is defined
            if (cbFailure) {
                var validationFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                    VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                    "One or more mandatory parameter needed by ClientWrapper was missing. Partner Chat did not initiate. API Key not provided."
                );
                cbFailure(validationFailedErr);
            }
            return; //exit
        } else {
            /**
             * Get a manager for working with the MediaStreams
             *
             * VHL.Msg.MediaStream.MediaStreamManager - Abstracts the communication
             * with WebRTC.
             *
             */
            var mediaOptions = _deepClone(_externalMediaOptions);

            if(sessionData.me_role === "invited") {
                mediaOptions.session_id =
                    _mapPartnersSessionData[sessionData.id].inviting.media.session_id;
            }

            _mediaStreamMgr = VHL.Msg.MediaStream.MediaStreamManager(
                sessionData.id,
                _mediaStreamManagerEventHandler,
                mediaOptions
            );

            _mark(VHL.Msg.PerformanceMetric.mark.start.CREATE_MEDIA_STREAM);
            _mediaStreamMgr.createMediaStream(
                sessionData.me_role,
                function success(mediaData) {
                    _endPerformanceMetric("CREATE_MEDIA_STREAM");
                    var meRole = sessionData.me_role;
                    if(!_mapPartnersSessionData[sessionData.id][meRole].media) {
                        _mapPartnersSessionData[sessionData.id][meRole].media = {};
                    }
                    _mapPartnersSessionData[sessionData.id][meRole].media.token = mediaData.token;
                    _mapPartnersSessionData[sessionData.id][meRole].media.session_id = mediaData.session_id;
                    _mapPartnersSessionData[sessionData.id].bMediaServerConnection = true;
                    if(_mapPartnersSessionData[sessionData.id].me_role === "invited") {
                        if(_externalMediaOptions.mode === VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER) {
                            cbSuccess(mediaData);
                        } else {
                            if(_mapPartnersSessionData[sessionData.id].bPartnerStreamCreated &&
                              _mapPartnersSessionData[sessionData.id].bMediaServerConnection) {
                                cbSuccess(mediaData);
                            } else {
                                _mapPartnersSessionData[sessionData.id].callbacks = {
                                    createMediaStream: {
                                        cbSuccess: cbSuccess,
                                        cbFailure: cbFailure
                                    }
                                };
                            }
                        }
                    } else {
                        cbSuccess(mediaData);
                    }
                },
                function failure(error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.CREATE_MEDIA_STREAM]);
                    var errReason = "Tokbox internal error. See tokbox_data for more details.";
                    if(error === "Audio device not found. Please attach audio device.") {
                        errReason = "Audio device not found. Please attach audio device.";
                    }
                    var err = _processError(
                        VHL.Msg.Errors.Source.TOKBOX,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.STREAM_CREATION_FAILED,
                        errReason,
                        error
                    );
                    if(cbFailure && typeof cbFailure === "function") { cbFailure(err); }
                }
            );
        }
    };

    /**
     * Function to show / hide my mediastream.
     * @param {boolean} bShowMediaStream - If true show my media stream.
     * @param {object} options - width and height of my media stream.
     * @param {function} cbSuccess - A function that is called when live streaming of my media
     *                               stream is started.
     * @param {function} cbFailure - A function that accepts an error object
     *                               with code and relavent message.
     */
    var __showMyMediaStream = function(bShowMediaStream, options, cbSuccess, cbFailure) {
        if(_mediaStreamMgr) {
            var self = this;
            if(!options) {
                options = {};
            }
            options.enable_audio = _externalMediaOptions.enable_audio;
            options.enable_video = _externalMediaOptions.enable_video;
            options.audio_level_events = _externalMediaOptions.audio_level_events;
            _mediaStreamMgr.publishMyMediaStream(
                bShowMediaStream,
                options,
                cbSuccess,
                function failure(error) {
                    var errorReason = "TokBox internal error. See tokbox-data for more details.";
                    if(error.name === "OT_USER_MEDIA_ACCESS_DENIED") {
                        errorReason = "Media Access Denied by User.";
                    } else if(error.name === "OT_HARDWARE_UNAVAILABLE") {
                        errorReason = error.message;
                    }
                    error = _processError(
                        VHL.Msg.Errors.Source.TOKBOX,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.SHOW_MY_MEDIA_STREAM_FAILED,
                        errorReason,
                        error
                    );
                    cbFailure(error);
                }
            );
        } else {
            _log.warn("Media Stream Manager is not initialized.");
        }
    };

    /**
    * This function is called to play a LIVE video stream via an appropriate
    * Streaming Provider ( WebRTC ).
    *
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is "session_id" for this session.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __playPartnerMediaStream = function(cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        _log.info("Calling playPartnerMediaStream", sessionData.id);

        _mediaStreamMgr.playPartnerMediaStream(
          cbSuccess,
          function failure(error) {
              var err = _processError(
                  VHL.Msg.Errors.Source.TOKBOX,
                  VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                  VHL.Msg.Errors.Code.PLAY_PARTNER_MEDIA_STREAM_FAILED,
                  "Tokbox internal error. See tokbox_data for more details.",
                  error
              );
              if(cbFailure && typeof cbFailure === "function") { cbFailure(err); }
          }
        );
        _clearChatTimeouts(sessionData.id, _getChatTimeoutType('PAIRING'));
    };

    /**
    * Function to start recording media stream.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __startRecording = function(recording_type, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        _log.info("Calling startRecording", sessionData.id);
        //Do not start recording if previous "recording" or "recording playbck" is in process
        if(sessionData.state === VHL.Msg.Session.State.RECORDING_STARTED ||
           sessionData.state === VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED) {
            var startRecordingFailedErr = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_START_FAILED,
                "Another media stream recording or playback is already in progress."
            );
            cbFailure(startRecordingFailedErr);
        } else {
            var startRecordingOptions = {
                course_id: _mapPartnersSessionData[sessionData.id].enrollment.course_id,
                school_id: _mapPartnersSessionData[sessionData.id].enrollment.school_id,
                activity_id: _mapPartnersSessionData[sessionData.id].activity_id,
                user_1: {
                    id: _mapPartnersSessionData[sessionData.id].inviting.uuid,
                    section_id: _mapPartnersSessionData[sessionData.id].inviting.section_id
                }
            };
            if (recording_type === VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM) {
              startRecordingOptions.users = _mapPartnersSessionData[sessionData.id].invited.uuid.map( (user_id) => {
                // TODO: get the exact user section, when calling users from different sections is resolved.
                return { id: user_id, section_id: _mapPartnersSessionData[sessionData.id].inviting.section_id };
              });
            } else {
              startRecordingOptions.user_2 = {
                  id: _mapPartnersSessionData[sessionData.id].invited.uuid,
                  section_id: _mapPartnersSessionData[sessionData.id].invited.section_id
              };
            } 
            _mark(VHL.Msg.PerformanceMetric.mark.start.START_RECORDING);
            _mediaStreamMgr.startRecording(
                startRecordingOptions,
                function success(recordingId) {
                    _endPerformanceMetric("START_RECORDING");
                    var msgType = recording_type;
                    var msgAction = VHL.Msg.Actions.RECORDING_STARTED;
                    var payload = {
                        "message": {
                            "context": {
                                "type": msgType,
                                "from": _transformLongFormToShortForm(_options.user),
                                "to": {}
                            },
                            [msgType]: {
                                "action": msgAction,
                                "session": {
                                    "id": sessionData.id,
                                    "channel": sessionData.channel,
                                    "group_id": sessionData.group_id
                                },
                                "media": {
                                    "recording_id": recordingId
                                }
                            }
                        },
                        "channel": sessionData.channel,
                        "storeInHistory": false
                    };
                    if(sessionData.me_role === "inviting") {
                        payload.message.context.to.uuid = sessionData.invited.uuid
                        payload.message.context.to.device_id = sessionData.invited.device_id
                    } else {
                      if (msgType === VHL.Msg.MediaStream.Events.Types.GROUP_CHAT_MEDIA_STREAM) {
                        let group_chat_view = new GroupChatView();
                        let selected_student_ids = [...group_chat_view.selected_student_ids];
                        selected_student_ids.push(sessionData.inviting.uuid);
                        selected_student_ids.splice(selected_student_ids.indexOf(_options.user.uuid), 1);
                        payload.message.context.to.uuid = selected_student_ids;
                      } else {
                        payload.message.context.to.uuid = sessionData.inviting.uuid
                      }
                     payload.message.context.to.device_id = sessionData.inviting.device_id
                    }
                    _pubnubClient.publish(
                        payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                var err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                                    VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_START_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                if(cbFailure && typeof cbFailure === "function") {
                                    cbFailure(err);
                                }
                            } else {
                                var sessionId = sessionData.id
                                _mapPartnersSessionData[sessionId].state = VHL.Msg.Session.State.RECORDING_STARTED;
                                _mapPartnersSessionData[sessionId].current_rec_id = recordingId;
                                if(! _mapPartnersSessionData[sessionId].recordings[recordingId]) {
                                    _mapPartnersSessionData[sessionId].recordings[recordingId] = {};
                                }
                                cbSuccess();
                            }
                        }
                    );
                },
                function failure(error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.START_RECORDING]);
                    var startRecordingFailedErr = _processError(
                        VHL.Msg.Errors.Source.TOKBOX,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                        VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_START_FAILED,
                        "TokBox internal error. See tokbox-data for more details.",
                        error
                    );
                    cbFailure(startRecordingFailedErr);
                }
            );
        }
    };

    /**
    * Function to stop recording media stream.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __stopRecording = function(recording_type, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        _log.info("Calling stopRecording", sessionData.id);
        var recordingId = _mapPartnersSessionData[sessionData.id].current_rec_id;
        if(recordingId) {
            _mark(VHL.Msg.PerformanceMetric.mark.start.STOP_RECORDING);
            _mediaStreamMgr.stopRecording(
                recordingId,
                function success() {
                    _endPerformanceMetric("STOP_RECORDING");
                    // call function to start polling Dynamo to fetch URL-Path.
                    _mark(VHL.Msg.PerformanceMetric.mark.start.GET_RECORDING_STATUS);
                    _mediaStreamMgr.getRecordingStatus(_options.user.uuid, recordingId);
                    var msgType = recording_type;
                    var msgAction = VHL.Msg.Actions.RECORDING_STOPPED;
                    var payload = {
                        "message": {
                            "context": {
                                "type": msgType,
                                "from": _transformLongFormToShortForm(_options.user),
                                "to": {}
                            },
                            [msgType]: {
                                "action": msgAction,
                                "session": {
                                    "id": sessionData.id,
                                    "channel": sessionData.channel,
                                    "group_id": sessionData.group_id
                                },
                                "media": {
                                    "recording_id": recordingId
                                }
                            }
                        },
                        "channel": sessionData.channel,
                        "storeInHistory": false
                    };
                    if(sessionData.me_role === "inviting") {
                        payload.message.context.to.uuid = sessionData.invited.uuid
                        payload.message.context.to.device_id = sessionData.invited.device_id
                    } else {
                        payload.message.context.to.uuid = sessionData.inviting.uuid
                        payload.message.context.to.device_id = sessionData.inviting.device_id
                    }
                    _pubnubClient.publish(
                        payload,
                        function (status, response) {
                            if (status.error) {
                                // handle error
                                var err = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                                    VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_STOP_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                if(cbFailure && typeof cbFailure === "function") {
                                    cbFailure(err);
                                }
                            } else {
                                _mapPartnersSessionData[sessionData.id].state = VHL.Msg.Session.State.RECORDING_STOPPED;
                                cbSuccess();
                            }
                        }
                    );
                },
                function failure(error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.STOP_RECORDING]);
                    /**
                     * in case, stopRecording failed due to Dynamo not being able to Conditional
                     * update the item.
                     */
                    if(error.status === 409) {
                        var stopRecordingFailedErr = _processError(
                            VHL.Msg.Errors.Source.TOKBOX,
                            VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                            VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_STOP_FAILED,
                            error.responseJSON.message,
                            error
                        );
                    } else {
                        var stopRecordingFailedErr = _processError(
                            VHL.Msg.Errors.Source.TOKBOX,
                            VHL.Msg.Errors.Context.PARTNER_CHAT_RECORDING,
                            VHL.Msg.Errors.Code.MEDIA_STREAM_RECORDING_STOP_FAILED,
                            "TokBox internal error. See tokbox-data for more details.",
                            error
                        );
                    }
                    cbFailure(stopRecordingFailedErr);
                }
            );

        }
    };

    /**
    * Sends a message to start pairing between the inviting & invited users of partner chat.
    * @param {function} pChatEventHandler - Callback event handler.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the start pairing message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __startPairing = function(chatInviteType, pChatEventHandler, cbSuccess, cbFailure) {
        var self = this;
        var msgType = chatInviteType;
        var msgAction = VHL.Msg.Actions.INITIATE;
        var sessionData = self.getSessionData();
        var payload = {
            "message": {
                "context": {
                    "type": msgType,
                    "from": _transformLongFormToShortForm(_options.user),
                    "to": {
                        "uuid": sessionData.invited.uuid,
                        "device_id": sessionData.invited.device_id
                    }
                },
                [msgType]: {
                    "action": msgAction,
                    "session": {
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id
                    },
                    "media": {
                        "session_id": sessionData.inviting.media.session_id
                    }
                }
            },
            "channel": sessionData.channel,
            "storeInHistory": false
        }; // Payload for the publishing invite accept message.
        _mark(VHL.Msg.PerformanceMetric.mark.start.START_PAIRING);
        _pubnubClient.publish( // pubnub SDK called
            payload,
            function (status, response) {
                if (status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.START_PAIRING]);
                    // handle error
                    var startPairingFailedErr = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                        VHL.Msg.Errors.Code.START_PAIRING_FAILED,
                        "Pubnub internal error. See pubnub-data for more details.",
                        status
                    );
                    cbFailure(startPairingFailedErr);
                } else {
                    _endPerformanceMetric("START_PAIRING");
                    _mapPartnersSessionData[sessionData.id].state = msgType + "#" + msgAction;
                    _registerPChatEventHandler(pChatEventHandler);
                    _subscribeToChatChannel(sessionData.channel);
                    cbSuccess(response);
                }
            }
        );
    };

    /**
    * Sends a message to confirm pairing between the inviting & invited users of partner chat.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the confirm pairing message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __confirmPairing = function(cbSuccess, cbFailure) {
        var self = this;
        if(_externalMediaOptions.mode === VHL.Msg.MediaStream.Modes.MOCK_MEDIASERVER) {
            var msgType = VHL.Msg.Types.PARTNER_CHAT_PAIRING;
            var msgAction = VHL.Msg.Actions.CONFIRM;
            var sessionData = self.getSessionData();
            var payload = {
                "message": {
                    "context": {
                        "type": msgType,
                        "from": _transformLongFormToShortForm(_options.user),
                        "to": {
                            "uuid": sessionData.inviting.uuid,
                            "device_id": sessionData.inviting.device_id
                        }
                    },
                    "PARTNER_CHAT_PAIRING": {
                        "action": msgAction,
                        "session": {
                            "id": sessionData.id,
                            "channel": sessionData.channel,
                            "group_id": sessionData.group_id
                        },
                        "media": {
                            "token": sessionData.invited.media.token,
                            "session_id": sessionData.invited.media.session_id
                        }
                    }
                },
                "channel": sessionData.channel,
                "storeInHistory": false
            }; // Payload for the publishing invite accept message.
            _mark(VHL.Msg.PerformanceMetric.mark.start.CONFIRM_PAIRING);
            _pubnubClient.publish( // pubnub SDK called
                payload,
                function (status, response) {
                    if (status.error) {
                        _clearMarks([VHL.Msg.PerformanceMetric.mark.start.CONFIRM_PAIRING]);
                        // handle error
                        var confirmPairingFailedErr = _processError(
                            VHL.Msg.Errors.Source.PUBNUB,
                            VHL.Msg.Errors.Context.PARTNER_CHAT_INIT,
                            VHL.Msg.Errors.Code.CONFIRM_PAIRING_FAILED,
                            "Pubnub internal error. See pubnub-data for more details.",
                            status
                        );
                        cbFailure(confirmPairingFailedErr);
                    } else {
                        _endPerformanceMetric("CONFIRM_PAIRING");
                        _mapPartnersSessionData[sessionData.id].state = msgType + "#" + msgAction;
                        cbSuccess(response);
                    }
                }
            );
        } else {
            cbSuccess();
        }
    };

    /**
    * Sends a message for ending the partner chat session.
    * @param {function} cbSuccess - (Optional) A function that accepts a single argument,
                                               which is an object having timetoken at which
                                               the end session message was sent.
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with statusCode and relavent message.
    */
    var __endSession = function(cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        /**
         * Stubbing callbacks if not passed. Client-wrapper calls this function without
         * callbacks. If callbacks are not stubbed, then event for endSession will be
         * fired to reference application.
         */
        cbSuccess = cbSuccess || function() {};
        cbFailure = cbFailure || function() {};
        if(_mediaStreamMgr) {
            _mediaStreamMgr.terminateMediaStream();
            cbSuccess();
        } else {
            _log.warn("Media Stream Manager is not initialized.");
        }
    };

    /**
    * Function to play recorded media stream.
    * @param {string} streamName - Name of the recorded stream.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __startRecordingPlayback = function(recordingId, cbSuccess, cbFailure) {
        //TODO - If recording is in process then do not play media stream.
        var sessionData = this.getSessionData();
        if(_mediaStreamMgr) {
            if(sessionData.state === VHL.Msg.Session.State.RECORDING_STARTED ||
               sessionData.state === VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED) {
                var startPlaybackFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                    VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                    "Another media stream recording or playback is already in progress."
                );
                cbFailure(startPlaybackFailedErr);
            } else {
                if(_mapPartnersSessionData[sessionData.id].recordings[recordingId]) {
                    var recordingUrl = _mapPartnersSessionData[sessionData.id].
                                        recordings[recordingId].url;
                    _mark(VHL.Msg.PerformanceMetric.mark.start.START_RECORDING_PLAYBACK);
                    _mediaStreamMgr.startRecordingPlayback(
                        recordingUrl,
                        function success() {
                            _endPerformanceMetric("START_RECORDING_PLAYBACK");
                            _mapPartnersSessionData[sessionData.id].state =
                                VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED;
                            cbSuccess();
                        },
                        function failure(err) {
                            var startPlaybackFailedErr = _processError(
                                VHL.Msg.Errors.Source.CLOUDFRONT,
                                VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                                VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                                "Cloud Front internal error. See cloudfront_data for more details.",
                                err
                            );
                            cbFailure(startPlaybackFailedErr);
                        }
                    );
                } else {
                    var startPlaybackFailedErr = _processError(
                        VHL.Msg.Errors.Source.CLIENTWRAPPER,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                        VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                        "Stream name not found in recording list"
                    );
                    cbFailure(startPlaybackFailedErr);
                }
            }
        }
    };

    /**
    * Function to play recorded media stream. It is also inform the partner user about
    * this action.
    * @param {string} streamName - Name of the recorded stream.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __startRecordingPlaybackWithPartnerSync = function(recordingId, recording_type, cbSuccess, cbFailure) {
        //TODO - If recording is in process then do not play media stream.
        var sessionData = this.getSessionData();
        var msgType = recording_type;
        var msgAction = VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_START;
        if(_mediaStreamMgr) {
            if(sessionData.state === VHL.Msg.Session.State.RECORDING_STARTED ||
               sessionData.state === VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED) {
                var startPlaybackFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                    VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                    "Another media stream recording or playback is already in progress."
                );
                cbFailure(startPlaybackFailedErr);
            } else {
                if(_mapPartnersSessionData[sessionData.id].recordings[recordingId]) {
                    var payload = {
                        "message": {
                            "context": {
                                "type": msgType,
                                "from": _transformLongFormToShortForm(_options.user),
                                "to": {}
                            },
                            [msgType]: {
                                "action": msgAction,
                                "session": {
                                    "id": sessionData.id,
                                    "channel": sessionData.channel,
                                    "group_id": sessionData.group_id
                                },
                                "media": {
                                    "recording_id": recordingId
                                }
                            }
                        },
                        "channel": sessionData.channel,
                        "storeInHistory": false
                    };
                    if(sessionData.me_role === "inviting") {
                        payload.message.context.to.uuid = sessionData.invited.uuid
                        payload.message.context.to.device_id = sessionData.invited.device_id
                    } else {
                        payload.message.context.to.uuid = sessionData.inviting.uuid
                        payload.message.context.to.device_id = sessionData.inviting.device_id
                    }
                    _pubnubClient.publish(
                        payload,
                        function (status, response) {
                            if (!status.error) {
                                var recordingUrl = _mapPartnersSessionData[sessionData.id].
                                                recordings[recordingId].url;
                                _mark(VHL.Msg.PerformanceMetric.mark.start.START_RECORDING_PLAYBACK);
                                _mediaStreamMgr.startRecordingPlayback(
                                    recordingUrl,
                                    function success() {
                                        _endPerformanceMetric("START_RECORDING_PLAYBACK");
                                        _mapPartnersSessionData[sessionData.id].state =
                                            VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED;
                                        cbSuccess();
                                    },
                                    function failure(err) {
                                        var startPlaybackFailedErr = _processError(
                                            VHL.Msg.Errors.Source.CLOUDFRONT,
                                            VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                                            VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                                            "Cloud Front internal error. See cloudfront_data for more details.",
                                            err
                                        );
                                        cbFailure(startPlaybackFailedErr);
                                    }
                                );
                            } else {
                                var startPlaybackFailedErr = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                                    VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                                    "Pubnub internal error. See pubnub_data for more details.",
                                    status
                                );
                                cbFailure(startPlaybackFailedErr);
                            }
                        }
                    ); // pubnub SDK called
                } else {
                    var startPlaybackFailedErr = _processError(
                        VHL.Msg.Errors.Source.CLIENTWRAPPER,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                        VHL.Msg.Errors.Code.START_MEDIA_STREAM_PLAYBACK_FAILED,
                        "Stream name not found in recording list"
                    );
                    cbFailure(startPlaybackFailedErr);
                }
            }
        }
    };

    /**
    * Function to stop playback of recorded media stream.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __stopRecordingPlayback = function(recording_type, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        if(_mediaStreamMgr) {
            _mediaStreamMgr.stopRecordingPlayback();
            _mapPartnersSessionData[sessionData.id].state =
                VHL.Msg.Session.State.RECORDING_PLAYBACK_STOPPED;
            cbSuccess();
        }
    };

    /**
    * Function to stop playback of recorded media stream. It is also inform the partner user about
    * this action.
    * @param {function} cbSuccess - (Optional).
    * @param {function} cbFailure - (Optional) A function that accepts an error object
                                               with code and relavent message.
    */
    var __stopRecordingPlaybackWithPartnerSync = function(recording_type, cbSuccess, cbFailure) {
        var sessionData = this.getSessionData();
        var msgType = recording_type;
        var msgAction = VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_STOP;
        if(_mediaStreamMgr) {
            var payload = {
                "message": {
                    "context": {
                        "type": msgType,
                        "from": _transformLongFormToShortForm(_options.user),
                        "to": {}
                    },
                    [msgType]: {
                        "action": msgAction,
                        "session": {
                            "id": sessionData.id,
                            "channel": sessionData.channel,
                            "group_id": sessionData.group_id
                        }
                    }
                },
                "channel": sessionData.channel,
                "storeInHistory": false
            };
            if(sessionData.me_role === "inviting") {
                payload.message.context.to.uuid = sessionData.invited.uuid
                payload.message.context.to.device_id = sessionData.invited.device_id
            } else {
                payload.message.context.to.uuid = sessionData.inviting.uuid
                payload.message.context.to.device_id = sessionData.inviting.device_id
            }
            _pubnubClient.publish(
                payload,
                function (status, response) {
                    if (!status.error) {
                        _mediaStreamMgr.stopRecordingPlayback();
                        _mapPartnersSessionData[sessionData.id].state =
                            VHL.Msg.Session.State.RECORDING_PLAYBACK_STOPPED;
                        cbSuccess();
                    } else {
                        var stopPlaybackFailedErr = _processError(
                            VHL.Msg.Errors.Source.PUBNUB,
                            VHL.Msg.Errors.Context.PARTNER_CHAT_PLAYBACK,
                            VHL.Msg.Errors.Code.STOP_MEDIA_STREAM_PLAYBACK_FAILED,
                            "Pubnub internal error. See pubnub_data for more details.",
                            status
                        );
                        cbFailure(stopPlaybackFailedErr);
                    }
                }
            ); // pubnub SDK called
        }
    };

    /**
    * Function to mute / unmute the audio while live streaming.
    */
    var __enableAudio = function(enableAudio) {
        _mediaStreamMgr.enableAudio(enableAudio);
    };

    /**
    * Function to pause / unpause the video while live streaming.
    */
    var __enableVideo = function(enableVideo) {
        _mediaStreamMgr.enableVideo(enableVideo);
    };

    /**
     * This is a generic function to send PubNub Command/Signalling messages to the Partner User.
     * data = {} | "string"
     */
    var __sendControlMessage = function(data, cbSuccess, cbFailure, controlMessageType) {
        var sessionData = this.getSessionData();
        _log.info("Calling sendControlMessage", sessionData.id);
        var msgType = controlMessageType || VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE;
        var msgAction = VHL.Msg.Actions.MESSAGE;
        var payload = {
            "message": {
                "context": {
                    "type": msgType,
                    "from": _transformLongFormToShortForm(_options.user),
                    "to": {}
                },
                [msgType]: {
                    "action": msgAction,
                    "session": {
                        "id": sessionData.id,
                        "channel": sessionData.channel,
                        "group_id": sessionData.group_id
                    },
                    "data": data
                }
            },
            "channel": sessionData.channel,
            "storeInHistory": false
        };
      switch(msgType){
        case VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE:
          if(sessionData.me_role === "inviting") {
              payload.message.context.to.uuid = sessionData.invited.uuid
              payload.message.context.to.device_id = sessionData.invited.device_id
          } else {
              payload.message.context.to.uuid = sessionData.inviting.uuid
              payload.message.context.to.device_id = sessionData.inviting.device_id
          }
          break;
        case VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE:
          let group_chat_view = new GroupChatView();
          let selected_student_ids = [...group_chat_view.selected_student_ids];
          selected_student_ids.push(sessionData.inviting.uuid);
          selected_student_ids.splice(selected_student_ids.indexOf(_options.user.uuid), 1);
          payload.message.context.to.uuid = selected_student_ids;
          if(sessionData.me_role === "inviting") {
              payload.message.context.to.device_id = sessionData.invited.device_id
          } else {
              payload.message.context.to.device_id = sessionData.inviting.device_id
          }
          break;
      }
      _mark(VHL.Msg.PerformanceMetric.mark.start.SEND_CONTROL_MESSAGE);
        _pubnubClient.publish(
            payload,
            function(status, response) {
                if(status.error) {
                    _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SEND_CONTROL_MESSAGE]);
                    // handle error
                    var stopPlaybackFailedErr = _processError(
                        VHL.Msg.Errors.Source.PUBNUB,
                        VHL.Msg.Errors.Context.PARTNER_CHAT_CONTROL_MESSAGE,
                        VHL.Msg.Errors.Code.MESSAGE_SEND_FAILED,
                        "Pubnub internal error. See pubnub_data for more details.",
                        status
                    );
                    cbFailure(stopPlaybackFailedErr);
                } else {
                    _endPerformanceMetric("SEND_CONTROL_MESSAGE");
                    if(cbSuccess && typeof cbSuccess === "function") {
                        cbSuccess();
                    }
                }
            }
        );
    };
    /** ###### End Of Partner Chat Adapter Member functions ############ */

    /** ====== Client Wrapper Member functions ==> Mapped to Public Methods */

    /**
    * Initializes the library, and established a connection with the Saas/PUSH provider. Setup should be
    * called only once i.e. ONE CONNECTION (on a page/tab) is allowed at a time. If called again, it will throw
    * an error (failure callback)
    * @param {string} grantEndPoint - The API endpoint that will return the roster data for the user.
    * @param {object} currentUser - (Optional) If this param is available, then the user is already logged in another
    *                                tab or has refreshed the tab. Grant API will not be called.
    * @param {object} mediaOptions - Contains media-stream-manager configurations (mode), publisher and subscriber
    *                                stream DOM id.
    * @param {function} cbSuccess - Success callback. A function that accepts a single argument which is the adapter
                                    object for further operations.
    * @param {function} cbFailure - Failure callback. A function that accepts a single argument which is an
                                    error object with more information
    */
    var __setup = function (grantEndPoint, currentUser, config, mediaOptions, eventHandler, cbSuccess, cbFailure) {
        _mark(VHL.Msg.PerformanceMetric.mark.start.SETUP);
        var deviceId, pubnubConfig = {};
        if(config) {
            if(config.partner_chat_timeouts) {
                _overrideChatTimeouts('PartnerChatTimeouts', config.partner_chat_timeouts);
            }

            if(config.group_chat_timeouts) { 
                _overrideChatTimeouts('GroupChatTimeouts', config.group_chat_timeouts);
            }

            if(!config.hasOwnProperty("message_history_retrieval")) {
               config.message_history_retrieval = VHL.Msg.PrivateChatHistoryRetrieval.Duration.THREE_DAYS;
            }
            if(config.hasOwnProperty("heartbeat_interval")) {
               pubnubConfig.heartbeatInterval = config.heartbeat_interval;
            }
            if(config.hasOwnProperty("activity_url")) {
                _activityUrl = config.activity_url;
            }
            if(config.hasOwnProperty("school_id")) {
                _schoolId = config.school_id;
            }
            if(config.hasOwnProperty("activity_id")) {
                _activityId = config.activity_id;
            }
            if(config.hasOwnProperty("invite_metadata")) {
                _inviteMetadata = config.invite_metadata;
            }
        } else {
            config = {
                "message_history_retrieval": VHL.Msg.PrivateChatHistoryRetrieval.Duration.THREE_DAYS
            }; // Initializing config.
        }
        const inviteTimeOut = _getChatInviteTimeout();
        if((inviteTimeOut / 3600000) > _pChatInviteTTL) {
            _pChatInviteTTL = Math.ceil(inviteTimeOut);
        }
        if(grantEndPoint === undefined || cbSuccess === undefined) { // Check/Validate if we have mandatory information.
            //Call failure if defined
            if (cbFailure) {
                var validationFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.SETUP,
                    VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                    "One or more mandatory parameter needed by ClientWrapper was missing. Setup did not initiate. Grant endpoint or Callback not provided."
                );
                cbFailure(validationFailedErr);
            }
            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SETUP]);
            return; //exit
        }

        /** Check if web storage supported by device. */
        if(!VHL.Msg.SessionStorage.Manager.isSessionStorageSupported) {
            if (cbFailure) { //Call failure if defined
                var validationFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.SETUP,
                    VHL.Msg.Errors.Code.SESSION_STORAGE_NOT_SUPPORTED,
                    "SessionStorage is not supported by device."
                );
                cbFailure(validationFailedErr);
            }
            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SETUP]);
            return; //exit
        }

        /** Check if setup has already been called previously. */
        if(_pubnubClient !== undefined) {
            //Call failure with error
            var validationFailedErr = _processError(
                VHL.Msg.Errors.Source.CLIENTWRAPPER,
                VHL.Msg.Errors.Context.SETUP,
                VHL.Msg.Errors.Code.ALREADY_INITIALIZED,
                "Setup has already been called OR Client-wrapper already been initialized."
            );
            cbFailure(validationFailedErr);
            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SETUP]);
            return; //exit
        }

        if(!mediaOptions) {
            //Call failure if defined
            if (cbFailure) {
                var validationFailedErr = _processError(
                    VHL.Msg.Errors.Source.CLIENTWRAPPER,
                    VHL.Msg.Errors.Context.SETUP,
                    VHL.Msg.Errors.Code.MANDATORY_PARAMETER_MISSING,
                    "One or more mandatory parameter needed by ClientWrapper was missing. Setup did not initiate. Media Options not provided."
                );
                cbFailure(validationFailedErr);
            }
            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SETUP]);
            return; //exit
        } else { // Store the media options provided by reference application
            _externalMediaOptions = mediaOptions;
        }

        if(currentUser && Object.keys(currentUser).length !== 0) {
            /**
             * User alredy logged-in in other tab / refreshed his page. User data provided by
             * reference app.
             */
            var sessionStorageData = VHL.Msg.SessionStorage.Manager.getData(); // Get user information for the curret session.
            var sessionUserInfo = sessionStorageData.data;
            if(sessionUserInfo && currentUser.user.uuid === sessionUserInfo.user.uuid) {
                /**
                 * User info available for this session and matches the data of current user.
                 * User refreshed the page. Use existing device_id
                 */
            } else {
                /**
                 * User info available for this session but did not  match the data of current user.
                 * Create a new device_id and clear session storage.
                 */
                VHL.Msg.SessionStorage.Manager.removeData();
            }
            _options = currentUser;
            deviceId = _getDeviceId(config);

            pubnubConfig.publishKey = currentUser.pubnub.publish_key;
            pubnubConfig.subscribeKey = currentUser.pubnub.subscribe_key;
            pubnubConfig.authKey = currentUser.auth_token;
            pubnubConfig.uuid = _options.user.uuid + ":" + deviceId;
            pubnubConfig.restore = _pubNubRestore;
            _pubnubClient = new PubNub(pubnubConfig); //Connect with PubNub SDK
            processSetup();
        }
        else {
            /**
             * User is not logged-in. Remove the data in session Storage and call the grant API.
             */
            VHL.Msg.SessionStorage.Manager.removeData();
            _mark(VHL.Msg.PerformanceMetric.mark.start.VHL_GRANT_ENDPOINT);
            _callAuthAPI(
                grantEndPoint,
                function success(userOptions) {
                    VHL.Chat.CONFIG.session = userOptions;
                    _endPerformanceMetric("VHL_GRANT_ENDPOINT");
                    _options = userOptions;
                    deviceId = _getDeviceId(config);
                    pubnubConfig.publishKey = userOptions.pubnub.publish_key;
                    pubnubConfig.subscribeKey = userOptions.pubnub.subscribe_key;
                    pubnubConfig.authKey = userOptions.auth_token;
                    pubnubConfig.uuid = _options.user.uuid + ":" + deviceId;
                    pubnubConfig.restore = _pubNubRestore;
                    _pubnubClient = new PubNub(pubnubConfig); //Connect with PubNub SDK
                    processSetup();
                },
                function failure(error) {
                    var errorDetails = {
                        statusCode: error.status
                    };
                    /**
                     * Checking for network issue.
                     * Ref: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState
                     */
                    if(error.readyState === 0) {
                        errorDetails.message = "Client or Server network is down.";
                    }
                    /**
                     * In case of server error, get information from response.
                     * Ref: https://github.com/vhl/dirt-driver-chat/wiki/Grants-Endpoint#error-status-4xx5xx
                     */
                    else {
                        errorDetails.message = error.statusText;
                        try {
                            errorDetails.error = JSON.parse(error.responseText);
                        } catch(exception) {
                            errorDetails.error = error.responseText;
                        }
                    }
                    _clearMarks([
                        VHL.Msg.PerformanceMetric.mark.start.SETUP,
                        VHL.Msg.PerformanceMetric.mark.start.VHL_GRANT_ENDPOINT
                    ]);
                    var grantApiFailedErr = _processError(
                        VHL.Msg.Errors.Source.XHR,
                        VHL.Msg.Errors.Context.SETUP,
                        VHL.Msg.Errors.Code.GRANT_API_FAILED,
                        "Grant API call failed",
                        errorDetails
                    );
                    cbFailure(grantApiFailedErr);
                }
            );
        }
        function processSetup() {
            var groupArray = [];
            for(var i in _options.roster.groups) {
                var sections = _options.roster.groups[i]
                               .sections.map(function(section) { return section.id });
                groupArray = groupArray.concat(sections);
            }

            // GroupChatChannelIds contains id of all group chat channels except for the
            // roster groups channels.
            VHL.Chat.GroupChatChannelIds = [];

            _pubnubClient.addListener({ //Setup Listeners (events will shows up after subscription)
                "message": function (data) {
                    /* If the message contains the groupChatAuth attribute notifying
                     * students that a group chat channel is created and that their
                     * Pubnub token needs to be updated.
                     */
                    if(data.message.groupChatAuth) {
                        const selectedUsers = data.message.selectedUsers;
                        if(selectedUsers && selectedUsers.includes(_options.user.uuid)) {
                            const gChatChannel = data.message.groupChatChannel;
                            __authorizePubnubChannel(gChatChannel);
                        }
                    }

                    if(_bInitialized) {
                      if(data && data.message && data.message.context) {
                          if(data.message.context.to) {
                              var to = data.message.context.to;
                              data.message.context.to = _transformShortFormToLongForm(to);
                          }
                          if(data.message.context.from) {
                              var from = data.message.context.from;
                              data.message.context.from = _transformShortFormToLongForm(from);
                          }
                      }
                      _fireEvent(data, "MESSAGE");
                  }
                },
                "presence": function (data) {
                  if(_bInitialized) {
                      if(data && data.state) {
                          var state = data.state;
                          data.state = _transformShortFormToLongForm(state);
                      }
                      _fireEvent(data, "PRESENCE");
                  }
                },
                "status": function (status) {
                    switch(status.category) {
                        /*
                            Per PubNub Support...

                            There is 'no' separate event to monitor a successful connection with PubNub.
                            Instead we need to use PNConnectedCategory event post subscription to a
                            channel.
                        */
                        case "PNConnectedCategory":
                            if(!_bInitialized) { // Initialization. The first Connect event is when PubNub is being initialized
                                // Setting pubnub setup time.
                                var setupTime = Date.now();
                                _setupTimetoken = _getPubnubTimeToken(setupTime);
                                if(config.message_history_retrieval ===
                                          VHL.Msg.PrivateChatHistoryRetrieval.Duration.UNLIMITED)
                                {
                                    _historyEndTimetoken = _getPubnubTimeToken(0);
                                } else {
                                    _historyEndTimetoken = _getPubnubTimeToken(
                                        setupTime - config.message_history_retrieval
                                    );
                                }
                                __getOnlineMembers(
                                    groupArray,
                                    function success(onlineUsers) {
                                        /**
                                         * The following condition evaluates to true for:
                                         * 1. First Device and it is a First Time Setup
                                         * 2. Additional Devices/Tabs and it is a First Time Setup
                                         * 3. Spawned Tab - by ACCEPTING the partner chat invite in a new TAB
                                         */
                                        if(_bNewDevice) {
                                            /**
                                             * I'm connected - push my state (Available, Idle) across all my groups
                                             */
                                            _initializeMyStateAcrossAllGroups(
                                                function success() {
                                                    cbSuccess(_constructClientAdaptor());
                                                    _bInitialized = true;
                                                    // Process pending invites for each group.
                                                    for(var i in groupArray) {
                                                        _processInviteHistory(groupArray[i]);
                                                    }
                                                },
                                                function failure(err) {
                                                    var stateInitializationFailedErr = _processError(
                                                        VHL.Msg.Errors.Source.PUBNUB,
                                                        VHL.Msg.Errors.Context.SETUP,
                                                        VHL.Msg.Errors.Code.STATE_INITIALIZATION_FAILED,
                                                        "Error while setting initial state in one of the roster group or section.",
                                                        err
                                                    );
                                                    cbFailure(stateInitializationFailedErr);
                                                }
                                            );
                                        }
                                        /**
                                         * SAME Device/Tab is Refreshed or Navigated
                                         * - State initialization is not REQUIRED
                                         */
                                        else {
                                            cbSuccess(_constructClientAdaptor());
                                            _bInitialized = true;
                                            // Process pending invites for each group.
                                            for(var i in groupArray) {
                                                _processInviteHistory(groupArray[i]);
                                            }
                                        }
                                    },
                                    function failure(err) {
                                        err.context = VHL.Msg.Errors.Context.SETUP;
                                        cbFailure(err);
                                    }
                                );
                                _endPerformanceMetric("SUBSCRIBE");

                            } else { //TODO Handle posting initialization Connect events
                            }
                            break;
                        case "PNBadRequestCategory":
                        case "PNAccessDeniedCategory":
                            _clearMarks([VHL.Msg.PerformanceMetric.mark.start.SUBSCRIBE]);
                            if(!_bInitialized) { // Initialization. The first Connect event is when PubNub is being initialized
                                var subscriptionFailedErr = _processError(
                                    VHL.Msg.Errors.Source.PUBNUB,
                                    VHL.Msg.Errors.Context.SETUP,
                                    VHL.Msg.Errors.Code.SUBSCRIPTION_FAILED,
                                    "Subscription failed for one of the roster groups or sections.",
                                    status.errorData
                                );
                                cbFailure(subscriptionFailedErr);
                            } else {
                                //TODO Handle posting initialization Connect events
                            }
                            break;
                        case "PNNetworkDownCategory":
                            _fireEvent(status, "STATUS");
                            break;
                        case "PNNetworkUpCategory":
                            _fireEvent(status, "STATUS");
                            break;
                            /** TODO - Default case implementation */
                    }
                }
            });
            _registerEventHandler(eventHandler); // Register event handler provided by logged in user.
            _subscribeEvents(groupArray); //Subscribe channels (roster)
            _endPerformanceMetric("SETUP");
        }

    }; //End of _setup()

    var __cleanup = function () {
        if(_pubnubClient) { //Skip cleanup if setup() was not called.
            _pubnubClient.unsubscribeAll();
            _pubnubClient.stop();
            VHL.Msg.SessionStorage.Manager.removeData();
        }
    };

    return { // Return public methods for the wrapper
        "setup": __setup,
        "cleanup": __cleanup
    };

})(); //End of Client Wrapper module
