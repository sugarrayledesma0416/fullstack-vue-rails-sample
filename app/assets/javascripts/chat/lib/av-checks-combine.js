var VHL = VHL || {};

VHL.AVChecks = VHL.AVChecks || {};

/*
 * This function calculates the statistics obtained from Audio-Video streams
 * being published and subscribed.
 * This library (or code) is based on the Opentok's Opentok-Network-Test Library.
 * Ref: https://github.com/opentok/opentok-network-test/blob/master/js-sample/app.js
 */
VHL.AVChecks.Stats = (function () {

    var _audioBitsPerSecond, _audioPacketLossRatioPerSecond, _testTimeout;
    var _videoBitsPerSecond, _videoPacketLossRatioPerSecond;

    var _testStreamingCapability = function(config, subscriber, publisher, cbSuccess) {
        _testTimeout = config.test_duration;
        _audioBitsPerSecond = config.audio_threshold.bits_per_second;
        _audioPacketLossRatioPerSecond = config.audio_threshold.packet_loss_ratio_per_second;
        _videoBitsPerSecond = config.video_threshold.bits_per_second;
        _videoPacketLossRatioPerSecond = config.video_threshold.packet_loss_ratio_per_second;

        _performQualityTest({subscriber: subscriber, timeout: _testTimeout}, function(error, results) {

            var testResults = {
                "audio": {
                    "is_hardware_available_with_permissions": false
                },
                "video": {
                    "is_hardware_available_with_permissions": false
                },
                "elapsedTimeMs": results.elapsedTimeMs
            };

            if(results.audio) {
                testResults.audio.is_hardware_available_with_permissions = true;
                testResults.audio.stats = {
                    packets_per_second: results.audio.packetsPerSecond,
                    bits_per_second: results.audio.bitsPerSecond,
                    packets_lost_per_second: results.audio.packetsLostPerSecond,
                    packet_loss_ratio_per_second: results.audio.packetLossRatioPerSecond
                };
                testResults.audio.threshold = {
                    bits_per_second: _audioBitsPerSecond,
                    packet_loss_ratio_per_second: _audioPacketLossRatioPerSecond
                };
            }

            if(results.video) {
                testResults.video.is_hardware_available_with_permissions = true;
                testResults.video.stats = {
                    packets_per_second: results.video.packetsPerSecond,
                    bits_per_second: results.video.bitsPerSecond,
                    packets_lost_per_second: results.video.packetsLostPerSecond,
                    packet_loss_ratio_per_second: results.video.packetLossRatioPerSecond
                };
                testResults.video.threshold = {
                    bits_per_second: _videoBitsPerSecond,
                    packet_loss_ratio_per_second: _videoPacketLossRatioPerSecond
                };

                var audioVideoSupported = results.video.bitsPerSecond > _videoBitsPerSecond &&
                    results.video.packetLossRatioPerSecond < _videoPacketLossRatioPerSecond &&
                    results.audio.bitsPerSecond > _audioBitsPerSecond &&
                    results.audio.packetLossRatioPerSecond < _audioPacketLossRatioPerSecond;

                if(audioVideoSupported) {
                    testResults.audio.quality = "good";
                    testResults.video.quality = "good";
                    cbSuccess(testResults);
                } else {
                    testResults.video.quality = "bad";
                    if(results.audio.packetLossRatioPerSecond < _audioPacketLossRatioPerSecond) {
                        testResults.audio.quality = "good";
                        cbSuccess(testResults);
                    } else {
                        // try audio only to see if it reduces the packet loss
                        publisher.publishVideo(false);

                        _performQualityTest(
                            {subscriber: subscriber, timeout: 5000},
                            function(error, results) {
                                var audioSupported = results.audio.bitsPerSecond > _audioBitsPerSecond &&
                                    results.audio.packetLossRatioPerSecond < _audioPacketLossRatioPerSecond;

                                if(audioSupported) {
                                    testResults.audio.quality = "good";
                                } else {
                                    testResults.audio.quality = "bad";
                                }
                                cbSuccess(testResults);
                            }
                        );
                    }
                }
            }
            else {
                // If we tried to set video constraints, but no video data was found
                var audioSupported = results.audio.bitsPerSecond > _audioBitsPerSecond &&
                    results.audio.packetLossRatioPerSecond < _audioPacketLossRatioPerSecond;

                if(audioSupported) {
                    testResults.audio.quality = "good";
                } else {
                    testResults.audio.quality = "bad";
                }
                cbSuccess(testResults);
            }
        });
    };

    var _performQualityTest = function(config, cbSuccess) {
        var startMs = new Date().getTime();
        var testTimeout;
        var currentStats;

        var bandwidthCalculator = _bandwidthCalculatorObj({
            subscriber: config.subscriber
        });

        var cleanupAndReport = function() {
            currentStats.elapsedTimeMs = new Date().getTime() - startMs;
            cbSuccess(undefined, currentStats);

            window.clearTimeout(testTimeout);
            bandwidthCalculator.stop();
        };

        // bail out of the test after "config.test_duration" (or 15 seconds default).
        window.setTimeout(cleanupAndReport, config.timeout);

        bandwidthCalculator.start(function(stats) {
            console.log(stats);
            currentStats = stats;
        });
    };

    var _bandwidthCalculatorObj = function(config) {
        var intervalId;

        config.pollingInterval = config.pollingInterval || 500;
        config.windowSize = config.windowSize || 2000;
        config.subscriber = config.subscriber || undefined;

        return {
            start: function(reportFunction) {
                var statsBuffer = [];
                var last = {
                    audio: {},
                    video: {}
                };

                intervalId = window.setInterval(function() {
                    config.subscriber.getStats(function(error, stats) {
                        if(stats) {
                            // Possible keys of stats, are "timestamp", "audio".
                            var activeMediaTypes = Object.keys(stats)
                            .filter(function(key) {
                                return key !== "timestamp";
                            });
                            var snapshot = {};
                            var nowMs = new Date().getTime();
                            var sampleWindowSize;

                            activeMediaTypes.forEach(function(type) {
                                snapshot[type] = Object.keys(stats[type]).reduce(function(result, key) {
                                    result[key] = stats[type][key] - (last[type][key] || 0);
                                    last[type][key] = stats[type][key];
                                    return result;
                                }, {});
                            });

                            // get a snapshot of now, and keep the last values for next round
                            snapshot.timestamp = stats.timestamp;

                            statsBuffer.push(snapshot);
                            statsBuffer = statsBuffer.filter(function(value) {
                                return nowMs - value.timestamp < config.windowSize;
                            });

                            sampleWindowSize = _getSampleWindowSize(statsBuffer);

                            if (sampleWindowSize !== 0) {
                                reportFunction(_calculatePerSecondStats(
                                    statsBuffer,
                                    sampleWindowSize + (config.pollingInterval / 1000)
                                ));
                            }
                        }
                    });
                }, config.pollingInterval);
            },

            stop: function() {
                window.clearInterval(intervalId);
            }
        };
    };

    var _getSampleWindowSize = function(samples) {
        var times = _pluck(samples, "timestamp");
        return (_max(times) - _min(times)) / 1000;
    };

    var _calculatePerSecondStats = function(statsBuffer, seconds) {
        var stats = {};
        var activeMediaTypes = Object.keys(statsBuffer[0] || {})
        .filter(function(key) {
            return key !== "timestamp";
        });

        activeMediaTypes.forEach(function(type) {
            stats[type] = {
                packetsPerSecond: _sum(_pluck(statsBuffer, type), "packetsReceived") / seconds,
                bitsPerSecond: (_sum(_pluck(statsBuffer, type), "bytesReceived") * 8) / seconds,
                packetsLostPerSecond: _sum(_pluck(statsBuffer, type), "packetsLost") / seconds
            };
            stats[type].packetLossRatioPerSecond = (
                stats[type].packetsLostPerSecond / stats[type].packetsPerSecond
            );
        });

        stats.windowSize = seconds;
        return stats;
    };

    var _pluck = function(arr, propertName) {
        return arr.map(function(value) {
          return value[propertName];
        });
    };

    var _sum = function(arr, propertyName) {
        if (typeof propertyName !== "undefined") {
            arr = _pluck(arr, propertyName);
        }

        return arr.reduce(function(previous, current) {
            return previous + current;
        }, 0);
    };

    var _max = function(arr) {
        return Math.max.apply(undefined, arr);
    };

    var _min = function (arr) {
        return Math.min.apply(undefined, arr);
    };

    return {
        "testStreamingCapability": _testStreamingCapability
    };
})();

var VHL = VHL || {};

VHL.AVChecks = VHL.AVChecks || {};

/**
 * Media Client API endpoints.
 * Purpose - These endpoints are used to interact with external media service
 *           providers like Tokbox.
 */
VHL.AVChecks.Endpoints = {
    "CREATE_SESSION": "/sessions",
    "CREATE_TOKEN": "/sessions/{{sessionId}}/tokens"
};

if (typeof _ === "function") {
    _.templateSettings = {
        "interpolate": /\{\{(.+?)\}\}/g
    };
}

/*
 * Setup - This function sets up the TokBox session, token, and
 *         functions to start and end test.
 * Returns - test adapter, containing functions to start and end test.
 */
VHL.AVChecks.Adapter = (function() {

    var _externalConfig;
    var _externalMediaOptions, _sessionId, _session, _token;
    var _publisher, _subscriber, _publisherEl;

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

    /*
     * This function creates a div element to publish the user's video,
     * attaches to a container, and attaches the container to the document,
     * also hides the div (as subscribed div needs to be shown).
     */
    var _prepareHTMLContent = function() {
        // create a div element, with display none.
        _publisherEl = document.createElement('div');
        _publisherEl.style.display = "none";
        var container = document.createElement('div');
        container.className = 'container';

        container.appendChild(_publisherEl);
        document.body.appendChild(container);
    };

    /** ====== AV Checks Functions ==> Mapped to Public Methods */

    /*
     * This function sets up the tokbox session and token, and returns a map,
     * containing functions to start and end test.
     */
    var __setup = function(config, mediaOptions, cbSuccess, cbFailure) {
        _externalMediaOptions = mediaOptions;
        _externalConfig = {
            test_duration : (config.test_duration || 15) * 1000,
            audio_threshold: {
                bits_per_second: config.audio_threshold.bits_per_second || 25000,
                packet_loss_ratio_per_second:
                                        config.audio_threshold.packet_loss_ratio_per_second || 0.05
            },
            video_threshold: {
                bits_per_second: config.video_threshold.bits_per_second || 250000,
                packet_loss_ratio_per_second:
                                        config.video_threshold.packet_loss_ratio_per_second || 0.03
            }
        };
        _doAJAX(
            _externalMediaOptions.media_base_url + VHL.AVChecks.Endpoints.CREATE_SESSION,
            "POST", null, null,
            function success(sessionData) {
                _sessionId = sessionData.id;
                console.log("New tokbox session created: " + _sessionId);
                cbSuccess({
                    "runTest": __runTest,
                    "cleanUp": __cleanUp
                });
            },
            function failure(error) {
                cbFailure(error);
            }
        );
    };

    /*
     * This function creates a publisher, connects to a session and subscribes
     * itself in the session, and starts the audio-video test.
     */
    var __runTest = function(cbSuccess, cbFailure) {
        // This publisher uses the default resolution (640x480 pixels) and frame rate (30fps).
        // For other resoultions you may need to adjust the bandwidth conditions in
        // testStreamingCapability().

        _session = OT.initSession(_externalMediaOptions.api_key, _sessionId);
        var endPoint = _.template(VHL.AVChecks.Endpoints.CREATE_TOKEN);
        endPoint = endPoint({
            "sessionId": _sessionId
        });
        _prepareHTMLContent();
        _doAJAX(
            _externalMediaOptions.media_base_url + endPoint,
            "POST", null, null,
            function success(tokenData) {
                _token = tokenData.id;
                console.log("New tokbox token created: " + _token);
                _publisher = OT.initPublisher(
                    _publisherEl,
                    {},
                    function onInitPublisher(error) {
                        if(error) {
                            console.log("Could not acquire your camera. Try connecting a camera.");
                            cbFailure(error);
                        } else {
                            console.log("Publisher created.");
                            _session.connect(_token, function onConnect(error) {
                                if(error) {
                                    console.log("Could not connect to OpenTok. Try again.");
                                    cbFailure(error);
                                } else {
                                    console.log("Session connected.");
                                    _session.publish(_publisher, function onPublish(error) {
                                        if(error) {
                                            console.log("Could not publish video.");
                                            cbFailure(error);
                                        } else {
                                            console.log("Stream published");
                                            _subscriber = _session.subscribe(
                                                _publisher.stream,
                                                _externalMediaOptions.my_media_element,
                                                {
                                                    audioVolume: 0,
                                                    insertMode: 'append',
                                                    testNetwork: true
                                                },
                                                function onSubscribe(error, subscriber) {
                                                    if(error) {
                                                        cbFailure(error);
                                                        console.log("Could not subscribe to video.");
                                                    } else {
                                                        console.log("Subscribed to video. Test ready to start");
                                                        _subscriber = subscriber;
                                                        subscriber.on('videoElementCreated', function (event) {
                                                            event.element.setAttribute('aria-label', 'Your Camera Feed');
                                                        });
                                                        VHL.AVChecks.Stats.testStreamingCapability(_externalConfig,
                                                                    _subscriber, _publisher, cbSuccess, cbFailure);
                                                    }
                                                }
                                            );
                                        }
                                    });
                                }
                            });
                        }
                    }
                );
            },
            function failure(error) {
                // This call will never return an error, except for Request Time Out.
                cbFailure(error);
            }
        );


    };

    /*
     * This function ends the audio-video test (disconnects the user from session and
     * cleans the session).
     */
    var __cleanUp = function(cbSuccess) {
        _session.on("sessionDisconnected", function() {
            cbSuccess();
        });

        // Check if the session is connected before we call a session.disconnect()
        if(typeof _session !== "undefined" && _session.currentState === 'connected')
        {
            _session.unsubscribe(_subscriber);
            _session.unpublish(_publisher);
            _session.disconnect();
            _session = undefined;
        }
        else {
            // Clear the session variable if session is in disconnected state
            _session = undefined;
            cbSuccess();
        }
    };

    return { // Return public methods for the AVChecks
        "setup": __setup
    };
})();
