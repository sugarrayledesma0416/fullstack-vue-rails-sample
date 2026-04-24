// event handler for all PartnerChat events, passed when accepting an invitation.
VHL.Msg.pChatEventHandler = function(controller, is_group_chat){
  let _is_group_chat = is_group_chat;
  let _partner_id = getPartnerId();

  /* helper functions */

  function playSenderMediaStream() {
    // When the recipient confirms the pairing, it means that the recipient has created successfully
    // a media stream and it's ready to show the webcam/mic, so the sender can play it and see
    // the data.
    controller.get_pChatAdapter().playPartnerMediaStream(function() {
      console.log('sender is playing his media stream now.');

      VHL.PerformanceApi.getMetrics('measure.vhl.msg.startPairing', function(metric) {
        controller.sendMetrics('start_pairing_latency', { latency: metric, service: 'tokbox' });
      });

    }, function(err) {
      console.log(err);
      controller.sendMetrics('play_sender_mediastream_error', { error: err, service: 'tokbox' });
    });
  }

    /**
   * Flow of the creation process of a recipient's media stream:
   *  1. Create media stream (Call get_pChatAdapter().createMediaStream).
   *    - On Sucess:
   *      2. Try to show the created media stream (Call get_pChatAdapter().showMyMediaStream).
   *        - On Sucess:
   *          3. Confirm pairing (Tell the sender that we are good to start video chatting).
   *          4. Play the partner media stream (Show partner's video with get_pChatAdapter().playPartnerMediaStream).
   *        - On Error:
   *          - Console log an error and cWrapper stops propagation.
   *    - On Error:
   *      - Console log an error and cWrapper stops propagation.
   **/
  function createRecipientMediaStream() {
    console.log(controller.get_pChatAdapter().getSessionData());

    // The recipient has received the notification from the sender that it's ready to show
    // the webcam/mic, so it's necessary to create a media stream that it's going to be shared
    // with the sender.
    controller.get_pChatAdapter().createMediaStream(function(mediaData) {
      VHL.PerformanceApi.getMetrics('measure.vhl.media.createMediaStream', function(metric) {
        controller.sendMetrics('create_recipient_mediastream_latency',
          { latency: metric, service: 'tokbox' }
        );
      });

      if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
        var video_size = { width: '100%', height: '100%' };
      } else {
        var video_size = { width: '10em', height: '10em' };
      }
      // Once the media stream is created, the recipient needs to tell the sender that it's ready
      // to show the webcam/mic, ending the pairing process.
      controller.get_pChatAdapter().showMyMediaStream(true, video_size, function() {
        controller.get_pChatAdapter().confirmPairing(function(data) {
          console.log('Pairing confirmed.', data);
          /* If there are info-gap references on the page, both of them
           *   have a CSS class identifying them as info-gap references.
           *   The view maps the label 'a' to the first reference and
           *   'b' to the second. The recipient should see the second
           *   reference.
           *
           * The counterpart to this call is in createSenderMediaStream,
           *   in vhl-msg-event-handler.js.
           */
          controller.assignInfoGapReference('b');
        }, function(err) {
          console.log('Error pairing', err);
          controller.sendMetrics('pairing_error', { error: err, service: 'tokbox' });
        });

        // Enable/disable video depending on config option passed to controller.
        // FIXME: when invited user unchecks the share-video checkbox, that user can see their
        //   own video for a split second before it is blacked out. The inviter does not see
        //   the invited user's video.
        controller.setVideoSharing();

        // Skip this for GroupChat, we will handle it on the streamCreated event.
        if (!VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
          // When the pairing is confirmed, the recipient can see the webcam/mic from the sender
          // playing the received media stream.
          controller.get_pChatAdapter().playPartnerMediaStream(function() {
            console.log('Recipient playing media stream.');
          }, function(err) {
            console.log('Error playing recipient media stream', err);
            controller.sendMetrics('play_recipient_mediastream_error',
              { error: err, service: 'tokbox' }
            );
          });
        }
      }, function(error) {
        console.log('Error trying to show recipient media stream', error);
        controller.sendMetrics('show_recipient_mediastream_error',
          { error: error, service: 'tokbox' }
        );
      });
    }, function(error) {
      console.log('Error creating recipient media stream', error);
      controller.sendMetrics('create_recipient_mediastream_error',
        { error: error, service: 'tokbox' }
      );
    });
  }


  /** function enableSubmit
   * Call this function when the pchat event handler recieves a COMBINE_COMPLETE action
   * (combined streams for pchat recording are available for user to play).
   * @param {Object} - Event data for the COMBINE_COMPLETE event that was
   * passed into the pChat event handler.
   */
  function enableSubmit(event) {
    /* We need figure out the partner id & partner section id to add to the submission data.
     * Both users' ids are available in the pChatAdapter's sessinon, in this form:
     *  sessionData.invited.uuid, sessionData.invited.section_id
     *  sessionData.inviting.uuid, sessionData.inviting.section_id
     * We choose the uuid/section that is NOT me, and assign it to the partner.
     */
    const sessionData = controller.get_pChatAdapter().getSessionData();
    let partner_id, section_name_and_id;

    if (sessionData.me_role === "inviting") {
      section_name_and_id= sessionData.invited.section_id;
    } else {
      section_name_and_id= sessionData.inviting.section_id;
    }
    let partner_section_id = parseInt(section_name_and_id.slice(section_name_and_id.indexOf("_" )+1));

    // grab the recording path from the event, removing any query params.
    const full_recording_path = event.mediaData.url.split('?')[0];
    // isolate the relative path i.e. sessionId/archiveId/archive.mp4
    const relative_recording_path = full_recording_path.split(VHL.Chat.CONFIG.partner_chat_cdn + "/")[1];

    // Assign values to hidden form elements that are part of the submission payload.
    if (Array.isArray(_partner_id)) {
      partner_section_id = JSON.stringify(_partner_id.map((_user_id) => partner_section_id));
      partner_id = JSON.stringify(_partner_id);
    } else {
      partner_id = _partner_id;
    }
    $('#partner_id').attr('value', partner_id);
    $('#partner_section_id').attr('value', partner_section_id);
    $('#recording_path').attr('value', relative_recording_path);

    let exportWithSubmitFeatureElm = document.querySelector('.js-export-with-submit-feature');
    if (exportWithSubmitFeatureElm?.value == 'true') {
      enableSubmitAndBindPortfolio();
    } else {
      enableSubmitButton();
      bindForAjaxSubmission();
    }
  }

  /**
   * Remove click handlers on submit button and
   * use ajax instead of sumitting the form.
   */
  function bindForAjaxSubmission() {
    let submitBtnElm = document.getElementById('_activity_submit');
    submitBtnElm?.setAttribute('onclick','')
    $(submitBtnElm).off('click')
    $(submitBtnElm).on('click', function(evt){
      evt.preventDefault();
      ajax_submission();
    })
  }

  /**
   * Enable submit button.
   */
  function enableSubmitButton() {
    let submitBtnElm = document.getElementById('_activity_submit');
    submitBtnElm?.classList?.remove('is-disabled');
    submitBtnElm?.removeAttribute('disabled');
  }

  /**
   * Enable submit button and bind event for portfolio export with submission.
   */
  function enableSubmitAndBindPortfolio() {
    enableSubmitButton();
    document.addEventListener(
      'export-on-submit-selected',
      () => bindForAjaxSubmission()
    );
  }

  function ajax_submission() {
    let form = $('#activity_form');
    let form_url = form.attr('action');

    // We have always been calling this before submitting pchats, thus it's ported to this chat system.
    VHL.Activity.is_storing_work();

    // This ajax submits the activity for both partners.
    $.ajax({
      type: "POST",
      url: form_url,
      data: form.serialize(),
      dataType: 'json',
      async: false,
      success: (data) => {
        let pChatAdapter = controller.get_pChatAdapter();
        let controlMessageType = (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType) ?
                                  VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE :
                                  VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE);
        
        // For info_gap_partner_chat_v2, don't notify partner about submission
        // to allow each student to complete their activities independently
        const activityType = document.querySelector('meta[name="VHL.activity_type"]').content;
        const shouldNotifyPartner = activityType !== 'info_gap_partner_chat_v2';
        
        if (pChatAdapter && shouldNotifyPartner) {

          // Notify partner about submission using pChatAdapter (if session is not terminated yet)
          pChatAdapter.sendControlMessage(
            { type: "submitted" },
            function success() {
              console.log('Partner is notified of submission.');
            },
            function failure(err) {
              console.log('Notifying partner of submission failed.');
            },
            controlMessageType
            );
        } else if (!shouldNotifyPartner) {
          console.log('Partner notification skipped for info_gap_partner_chat_v2 activity.');
        } else {
            
          // Use PubNub adapter to notify partner about submission (eg. when call is disconnected)
          if (shouldNotifyPartner) {
            sendSubmittedMessagePostSession();
          }
        }

        /* confirm_unanswered_submissions is defined in mae.
        It's called when we submit every activity & has been ported over the submission handling in the old chat client gem.
        https://github.com/vhl/chat_client/blob/4ffd90adda06ee3bec05fda154550ee0beb5f129/app/assets/javascripts/partner_chat/chat_ui.js#L1813
        */
        confirm_unanswered_submissions();
        controller.disableSubmit();
        controller.renderView({ event: 'submitted'});

        /* Set a flag to indicate that the activity has been submitted.
        We check the flag when the call is ended by either user, and refresh
        to reveal the completed view if it had been submitted.
        */
        controller.set_activitySubmitted(true);
        
        if (!pChatAdapter) {
          
          // Refresh the page, because call is already disconnected and activity is submitted.
          location.replace(location.origin + location.pathname);
        }
      }
    });
  }

  function sendSubmittedMessagePostSession() {

    // Form fields #partner_id, #partner_section_id, #recording_path store
    // appropriate values from session etc when submit button gets enabled for a pchat recording.
    // We will pass these values to other partner to enable context match.
    // We avoided sending #recording_path's as we are not yet sure whether this would always match.
    let partnerId = $('#partner_id').attr('value');
    let partnerSectionId = $('#partner_section_id').attr('value');
    
    controller.sendSubmittedMessagePostSession(
      partnerId,
      partnerSectionId,
      function success() {
        console.log('Partner is notified of submission, post-session.');
      },
      function failure(err) {
        console.log('Notifying partner of submission failed, post-session.');
      },
    );
  }

  /**
   * Add review modal click handler.
   */
  function modalReviewClickHandler() {
    controller.replayRecording();
    document.querySelector('.js-review-modal').classList.add('u-hidden');
  }

  /**
   * Remove review modal that is opened for Iphone users.
   */
  function removeReviewModal() {
    document.querySelector('.js-modal-review-btn').removeEventListener('click', modalReviewClickHandler);
    document.querySelector('.js-review-modal').classList.add('u-hidden');
  }

  /**
   * Check if device is iPhone or iPad.
   */
  function isIphoneOrIpad() {
    return (
      navigator.userAgent.indexOf('iPhone') > -1 ||
      (
        navigator.maxTouchPoints &&
        navigator.maxTouchPoints > 2 &&
        /MacIntel/.test(navigator.platform)
      )
    );
  }

  /**
   * Returns the user id for all the partners in the call
   * @returns {(number|Array)} User id for all the partners in the call
   */
  function getPartnerId() {
    let partner_id = null;
    const sessionData = controller.get_pChatAdapter().getSessionData();

    if (sessionData.me_role === "inviting") {
      partner_id = sessionData.invited.uuid;
    } else {
      if (_is_group_chat) {
        let selected_student_ids = [sessionData.inviting.uuid, ...sessionData.invited.uuid];
        if(selected_student_ids.indexOf(controller.myUuid) !== -1) {
          selected_student_ids.splice(selected_student_ids.indexOf(controller.myUuid), 1);
        }
        partner_id = selected_student_ids;
      } else {
        partner_id = sessionData.inviting.uuid;
      }
    }

    return partner_id;
  }

  function pChatEventHandler(sessionId, event) {
    switch (event.type) {
      // The recipient and the sender receives the PARTNER_CHAT_PAIRING
      // which allow us to know when to create the media stream (the channel that sends and receive
      // webcam/mic data).
    case VHL.Msg.Actions.PARTNER_CHAT_PAIRING:
    case VHL.Msg.Actions.GROUP_CHAT_PAIRING:
      switch (event.action) {
      case VHL.Msg.Actions.INITIATE:
        // The recipient recieves this action. which means that the sender just created a
        // media stream and it's ready to share the webcam/mic with the recipient.
        createRecipientMediaStream();
        break;
      case VHL.Msg.Actions.CONFIRM:
        // The recipient recieves this action. It means that the sender is waiting to pair the
        // media stream with the one the recipient just created, so both can see the webcam/mic.
        // It's here when the recipient plays the sender media stream to show the data.

        playSenderMediaStream();
        break;
      }
      break;
    case VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM:
    case VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM:
      switch (event.action) {
        case VHL.Msg.Actions.STREAM_TERMINATED:
          let idPartnerWhoLeft = event.mediaData.student_id_stream_terminated;
          _partner_id = _partner_id.filter(function(id) {
            return id !== idPartnerWhoLeft;
          });
          controller.renderView({event: 'someone-leaves', fromUuid: idPartnerWhoLeft });
          break;
        case VHL.Msg.Actions.RECORDING_STARTED:
          console.log('video recording started');

          controller.renderView({ event: 'they-start-rec' });
          break;
        case VHL.Msg.Actions.RECORDING_STOPPED:
          console.log('video recording stopped');

          controller.renderView({ event: 'they-stop-rec' });
          break;
        case VHL.Msg.Actions.COMBINE_COMPLETE:
          console.log('video combining completed');

          controller.set_playbackData(event.mediaData);
          controller.renderView({ event: 'video-combine-complete' });

          /* If the "practice" flag has been set in the DOM,
           *   don't enable the submit button. A student in practice
           *   mode should not be able to submit the activity.
           */
          if ($('#practice').val() != 'yes') {
            enableSubmit(event);
          }
          break;
        case VHL.Msg.Actions.COMBINE_FAILED:
          console.log('video combining failed');

          controller.sendMetrics('polling_recording_failed', { error: event, service: 'tokbox' });

          break;
        case VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_START:
          const sessionData = controller.get_pChatAdapter().getSessionData();
          console.log('starting playback for receiver');
          if (isIphoneOrIpad()) {
            if (sessionData.state !== VHL.Msg.Session.State.RECORDING_PLAYBACK_STARTED) {
              const reviewBtn = document.querySelector('.js-modal-review-btn');
              reviewBtn.removeEventListener('click', modalReviewClickHandler);
              document.querySelector('.js-review-modal').classList.remove('u-hidden');
              reviewBtn.addEventListener('click', modalReviewClickHandler);
            }
          } else {
            controller.replayRecording();
          }
          break;
        case VHL.Msg.Actions.PARTNER_RECORDING_PLAYBACK_STOP:
          console.log('stopping playback for receiver');
          removeReviewModal();
          // This event is received by the partner that didn't stop the playback sync.
          controller.stopPlayback();
          controller.enableSubmit();
          break;
        case VHL.Msg.Actions.RECORDING_PLAYBACK_COMPLETE:
          removeReviewModal();
          // This event is received when playback ends b/c the end of the recording was reached.
          controller.renderView({ event: 'playback-complete' });
          break;

        case VHL.Msg.Actions.AUDIO_LEVEL_UPDATED:
          // This event is received when the adapter sends an audio level (very frequent!)
          // So throttle the frequency down:

          controller.updateAudioLevel(event.mediaData.audio_level);
          break;

        // This action is received when either the sender or the recipient decides to end
        // the call (the video chatting).
      case VHL.Msg.Actions.TERMINATE:
        removeReviewModal();
        controller.set_pChatAdapter(null);
        controller.disableSubmit();
        // If the activity has been submitted, reload the page and show the completed view.
        if (controller.get_activitySubmitted()) {
          // reload this activity without the query string
          location.replace(location.origin + location.pathname);
        } else if (event.from.uuid !== controller.myUuid) {
          console.log('Call ended by sender');
          controller.renderView({ event: 'they-hangup' });
        } else {
          controller.renderView({ event: 'i-hangup' });
        }
        controller.setMyState('available');
        break;
      }
    break;

    case VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE:
    case VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE:
      switch(event.action) {
        case VHL.Msg.Actions.MESSAGE:
        if (event.data.type === "submitted") {
          controller.disableSubmit();

          /* Set a flag to indicate that the activity has been submitted.
             We check the flag when the call is ended by either user, and refresh
             to reveal the completed view if it had been submitted.
          */
          controller.set_activitySubmitted(true);
          controller.renderView({ event: 'submitted'});
          }

          if (event.data.type === 'sync-redo') {
            controller.renderView({ event: 'they-redo'});
            controller.disableSubmit();
          }
          break;
      }
      break;
    }
  }; // End pChatEventHandler
  return pChatEventHandler;
};
