// event handler for all Pubnub events, passed into clientWrapper.setup()
VHL.Msg.eventHandler = function(controller) {
  // We need this guard variable, to control how many times the view should be updated when
  // the user changes the state.
  let _viewUpdated = false;

  /* helpers */
  function handleStateChange(event) {
    var new_state = event.state.state;

    if (event.uuid === controller.myUuid) {

      let currentState = controller.get_myCurrentState();

      if (VHL.Chat.Status[currentState] != new_state) {
        _viewUpdated = false; // User can update their view.
      }

      if (_viewUpdated) {
        return; // View already updated, so no need to do it again.
      }

      // If I change state from another device (tab, browser, etc),
      // update the UI.
      if (new_state === VHL.Msg.User.State.AVAILABLE) {
        controller.renderView({ event: 'i-available' });
      } else if (new_state === VHL.Msg.User.State.AWAY) {
        controller.renderView({ event: 'i-unavailable' });
      }

      _viewUpdated = true;

      return;
    }

    var conversation = controller.findConversation(event.uuid, event.group);

    // If there's no conversation but we receive a state change from another user,
    // that means that the roster wasn't loaded because the course only grants pchat level
    // and the user IS NOT in a pchat/infogap activity.
    if (conversation == null) {
      return;
    }

    // If the new state is AWAY == UNAVAILABLE
    if(new_state == VHL.Msg.User.State.AWAY) {
      conversation.user.state = 'unavailable';
      controller.renderView({ event: 'they-unavailable' });
    } else if(new_state == VHL.Msg.User.State.AVAILABLE) {
      conversation.user.state = 'available';
      controller.renderView({ event: 'they-available' });
    } else if(new_state == VHL.Msg.User.State.BUSY) {
      conversation.user.state = 'busy';
      controller.renderView({ event: 'they-busy' });
    }
  }

  function handlePresenceJoin(event) {
    // We do not want to show ourselves in our own roster.
    if (event.uuid !== controller.myUuid) {
      var existingConversation = controller.findConversation(event.uuid, event.group);
      var userState = 'offline';

      // Identify the user status using the event object
      if(event.state.state == VHL.Msg.User.State.AWAY) {
        userState = 'unavailable';
      } else if(event.state.state == VHL.Msg.User.State.AVAILABLE) {
        userState = 'available';
      } else if(event.state.state == VHL.Msg.User.State.BUSY) {
        userState = 'busy';
      }

      //In the case that a new user is enrolled, and the user logs on and produces a join event,
      //there will not be an existing conversation for that user.
      //In this case we need to create a new conversation.
      if(existingConversation == null) {
        var userProperties = event.state;
        userProperties.uuid = event.uuid;

        controller.initNewRosterMember(userProperties, event.group, userState);
      } else {
        existingConversation.user.state = userState;
      }

      controller.renderView({ event: 'they-join' });
    }
  }

  function handlePresenceLeave(event) {
    var conversation = controller.findConversation(event.uuid, event.group);

    // If there's no conversation but we receive a state change from another user,
    // that means that the roster wasn't loaded because the course only grants pchat level
    // and the user IS NOT in a pchat/infogap activity.
    if (conversation == null) {
      return;
    }

    // We set this state ONLY when someone leaves or timeout.
    conversation.user.state = 'offline';

    controller.renderView({event: 'they-leave' });
    console.log('someone left chat');
  }

  function handlePrivateChatMessage(event, is_history_message) {
    var anyMessageFromMe = event.messages.some(function(message) {
      return message.from.uuid == controller.myUuid;
    });

    // We need to do this validation to avoid issues trying to send
    // undefined metrics, because the measure only happens when the message
    // is sent by me. Also, we don't want to try to get metrics while fetching message history,
    // because there's another metric that is measuring the history data retrieval and it should
    // be gathered only when all history messages have been retrieved.
    if (anyMessageFromMe && !is_history_message) {
      VHL.PerformanceApi.getMetrics('measure.vhl.msg.sendMessage', function(metric) {
        controller.sendMetrics('send_message_latency', { latency: metric, service: 'pubnub' });
      });
    }

    event.messages.forEach(function(message) {
      controller.addMessage(event.group, message, is_history_message);
    });

    controller.renderView({event: 'new-message' });
  }

  /**
  * This function handles submission message by other partner when pchat session is unavailable (eg
  * when call is disconnected). As session related information is not available to act on the
  * message, this function validates that the current view is still in the same Pchat context.
  */
  function handleSubmittedMessagePostSession(event) {
    let pChatAdapter = controller.get_pChatAdapter();
    if (pChatAdapter) {
      console.log(`PostSession-Submitted message is out of context and ignored.
                   User is in another session.`);
      return;
    }

    let isSubmissionContextMatched = isSubmissionContextMatchedPostSession(event);
    if (isSubmissionContextMatched) {
      controller.disableSubmit();
      controller.set_activitySubmitted(true);
      controller.renderView({ event: 'submitted' });

      // Refresh the page, because call is already disconnected and activity is submitted.
      location.replace(location.origin + location.pathname);
    } 
  }

  function isSubmissionContextMatchedPostSession(event) {

      // We avoided comparing relative combined recordingPath ie $('#recording_path').attr('value')
      // from both side to validate context as we are not yet sure whether this would always match.
      // Compare values of Form fields #partner_id, #user_section_id & submitButton state to ensure
      // that user has pending submission for same recording session for which message has arrived.
      let partnerId = $('#partner_id').attr('value');
      let isPartnerMatched = event.from && event.from.uuid && event.from.uuid === partnerId;
      let userSectionId = $('#user_section_id').attr('value');
      let isSectionMatched = event.data && userSectionId === event.data.sectionId;
      let $submitButton = $('#_activity_submit');
      let isSubmitButtonEnabled = $submitButton.length && $submitButton.attr('disabled') != "disabled";
      let isSubmittable = !controller.get_activitySubmitted() && isSubmitButtonEnabled;
      let isSubmissionContextMatched = isPartnerMatched && isSectionMatched && isSubmittable;
      if (!isSubmissionContextMatched) {
        console.log(`PostSession-Submitted message is out of context and ignored.
          isPartnerMatched: ${isPartnerMatched},
          isSectionMatched:${isSectionMatched},
          isSubmittable: ${isSubmittable}`);
      }

      return isSubmissionContextMatched;
  }

  function showReceivedInvitation(inviter, inviter_sectionId, event) {
    // Here, we are asking the recipient to accept or reject the invitation.
    // Invitation sent, send metrics.
    controller.renderView({
      event: 'they-invite',
      inviterName: inviter.first_name + ' ' + inviter.last_name,
      inviterUserId: inviter.uuid,
      inviterSectionId: inviter_sectionId,
      activityTitle: event.inviteMetadata.activityTitle,
      isPartnerChat: event.inviteMetadata.isPartnerChat,
      isGroupChat: event.inviteMetadata.isGroupChat
    });
  }

  // Here is where the partner chat events start to interact with the UI and the expected workflow.
  function handlePartnerchatInvitation(event) {
    // We need to keep this adapter globally. We must kill it when the partner chat session is done.
    if(!controller.get_pChatAdapter()) {
      controller.set_pChatAdapter(event.sessionAdapter);
    }

    switch (event.action) {
    case VHL.Msg.Actions.INVITE:
      console.log('someone is calling!');
      //True if current activity is type partner chat activity
      var partnerChatActivity = VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType);

      if (partnerChatActivity && controller.isLiveChatInvitation()) {
        console.log('Invitation rejected: user is in a partner chat activity');
        controller.declineInvitation();
        controller.renderView({ event: 'i-reject-livechat' });

        controller.set_pChatAdapter(null);
        controller.setMyState('available');
      } else {
        // This event is to handle the invitation received. This logic it's going to be executed
        // by the recipient.
        var sessionData = controller.get_pChatAdapter().getSessionData();
        var inviter = sessionData.inviting; // We retrieve the sender name.
        var inviter_sectionId = sessionData.group_id; // And the section ID.
        showReceivedInvitation(inviter, inviter_sectionId, event);
      }
      break;

    case VHL.Msg.Actions.ACCEPT:
      // This event is to notify the SENDER that the RECIPIENT has just accepted the invitation sent.
      var invited = controller.get_pChatAdapter().getSessionData().invited;
      var invited_sectionId = controller.get_pChatAdapter().getSessionData().group_id;
      let conversationId = null;
      console.log('invitation accepted by receiver.');

      if(VHL.Chat.CONFIG.activityType === 'group_chat') {
        const group_chat_view = new GroupChatView();
        conversationId = group_chat_view.group_chat_channel_id();
      } else {
        conversationId = `${invited_sectionId}-${invited.uuid}`;
      }

      controller.renderView({
        event: controller.isLiveChatInvitation() ? 'they-accept': 'they-accept-pchat',
        invitedName: invited.first_name + ' ' + invited.last_name,
        conversationId: conversationId
      });
      createSenderMediaStream();

      break;

    case VHL.Msg.Actions.REVOKE:
      // According to the docs (https://github.com/vhl/dirt-driver-chat#invited-tab-1-step-2--accept-in-new-tab-or-reject-the-invitation)
      // It's necessary to compare if the current pChat session is the same as the sender/recipient just revoked/rejected.
      if (controller.get_pChatAdapter().getSessionId() == event.sessionData.id) {
        controller.renderView({
          event: 'they-revoke'
        });
        console.log('Invitation revoked.');
        controller.set_pChatAdapter(null);
      }

      controller.setMyState('available');
      break;

    case VHL.Msg.Actions.REJECT:
      console.log('Invitation rejected!');
      controller.set_pChatAdapter(null);

      controller.renderView({ event: 'they-reject' });
      controller.setMyState('available');
      break;

    case VHL.Msg.Actions.HISTORY_INVITE_RECEIVE:
      console.log('Received an invite while not on this page.');
      var inviter = event.from;
      var inviter_sectionId = event.sessionData.group_id;

      showReceivedInvitation(inviter, inviter_sectionId, event);
      break;
      // no default
    } // end switch
  } // end handlePartnerchatInvitation

  function handleGroupchatInvitation(event) {
    // We need to keep this adapter globally. We must kill it when the partner chat session is done.
    if(!controller.get_pChatAdapter()) {
      controller.set_pChatAdapter(event.sessionAdapter);
    }

    switch (event.action) {
    case VHL.Msg.Actions.INVITE:
      console.log('someone is calling!');
      //True if current activity is a group chat activity
      var groupChatActivity = VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType);

      if (groupChatActivity && controller.isLiveChatInvitation()) {
        console.log('Invitation rejected: user is in a chat activity');
        controller.declineInvitation();
        controller.renderView({ event: 'i-reject-livechat' });

        controller.set_pChatAdapter(null);
        controller.setMyState('available');
      } else {
        // This event is to handle the invitation received. This logic it's going to be executed
        // by the recipient.
        var sessionData = controller.get_pChatAdapter().getSessionData();
        var inviter = sessionData.inviting; // We retrieve the sender name.
        var inviter_sectionId = sessionData.group_id; // And the section ID.
        showReceivedInvitation(inviter, inviter_sectionId, event);
      }
      break;

    case VHL.Msg.Actions.ACCEPT:
      // This event is to notify the SENDER that the RECIPIENT has just accepted the invitation sent.
      var invited = controller.get_pChatAdapter().getSessionData().invited;
      var invited_sectionId = controller.get_pChatAdapter().getSessionData().group_id;
      let conversationId = null;
      console.log('invitation accepted by receiver.');

      if(VHL.Chat.CONFIG.activityType === 'group_chat') {
        const group_chat_view = new GroupChatView();
        conversationId = group_chat_view.group_chat_channel_id();
      } else {
        conversationId = `${invited_sectionId}-${invited.uuid}`;
      }

      controller.renderView({
        event: controller.isLiveChatInvitation() ? 'they-accept': 'they-accept-pchat',
        invitedName: invited.first_name + ' ' + invited.last_name,
        conversationId: conversationId
      });
      createSenderMediaStream();

      break;

    case VHL.Msg.Actions.ACCEPT_LATER:
      triggerStartPairingForLateJoiner();
      break;

    case VHL.Msg.Actions.REVOKE:
      // According to the docs (https://github.com/vhl/dirt-driver-chat#invited-tab-1-step-2--accept-in-new-tab-or-reject-the-invitation)
      // It's necessary to compare if the current pChat session is the same as the sender/recipient just revoked/rejected.
      if (controller.get_pChatAdapter().getSessionId() == event.sessionData.id) {
        controller.renderView({
          event: 'they-revoke'
        });
        console.log('Invitation revoked.');
        controller.set_pChatAdapter(null);
      }

      controller.setMyState('available');
      break;

    case VHL.Msg.Actions.REJECT:
      console.log('Invitation rejected!');
      controller.set_pChatAdapter(null);

      controller.renderView({ event: 'they-reject' });
      controller.setMyState('available');
      break;

    case VHL.Msg.Actions.HISTORY_INVITE_RECEIVE:
      console.log('Received an invite while not on this page.');
      var inviter = event.from;
      var inviter_sectionId = event.sessionData.group_id;

      showReceivedInvitation(inviter, inviter_sectionId, event);
      break;
      // no default
    } // end switch
  } // end handlePartnerchatInvitation

  function createSenderMediaStream() {
    // In order to share the webcam/mic through javascript,
    // it's necessary to create a media stream that is going to be like a bridge for the
    // information between the sender and the recipient.
    controller.get_pChatAdapter().createMediaStream(function(mediaData) {
      VHL.PerformanceApi.getMetrics('measure.vhl.media.createMediaStream', function(metric) {
        controller.sendMetrics('create_sender_mediastream_latency',
          { latency: metric, service: 'tokbox' }
        );
      });

      if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
        var video_size = { width: '100%', height: '100%' };
      } else {
        var video_size = { width: '10em', height: '10em' };
      }
      // Once the media stream channel for the sender is created, we need to make it visible to the
      // recipient, with this media stream.
      controller.get_pChatAdapter().showMyMediaStream(true, video_size, function() {
        console.log('Mediastream shown.');
        // Once we make the media stream for the sender visible, we need to tell the recipient
        // that the sender is ready to share the webcam/mic and it's waiting for confirmation.
        var is_group_chat = VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType);
        var chatInviteType = (is_group_chat ? VHL.Msg.Types.GROUP_CHAT_PAIRING : VHL.Msg.Types.PARTNER_CHAT_PAIRING);
        controller.get_pChatAdapter().startPairing(chatInviteType, VHL.Msg.pChatEventHandler(controller, is_group_chat), function(data) {
          console.log('paired', data);

          /* If there are info-gap references on the page, both of them
           *   have a CSS class identifying them as info-gap references.
           *   The view maps the label 'a' to the first reference and
           *   'b' to the second. The sender should see the first reference.
           *
           * The counterpart to this call is in createRecipientMediaStream,
           *   in vhl-msg-pchat-event-handler.js.
           */
          controller.assignInfoGapReference('a');
        }, function(err) {
          console.log('cannot pair', err);
          controller.sendMetrics('sender_pairing_error', { error: err, service: 'tokbox' });
        });
      }, function(err) {
        console.log('Error trying to show the media stream', err);
        controller.sendMetrics('show_sender_mediastream_error', { error: err, service: 'tokbox' });
      });
    }, function(err) {
      console.log('Error creating media stream.', err);
      controller.sendMetrics('create_sender_mediastream_error', { error: err, service: 'tokbox' });
    });
  }

  /**
   * This method triggers PAIRING INITIATE for group chat.
   * Flag bMediaServerConnection in session data is used to check
   * that media stream is already setup.
   * This is for those partners who accepted the invitation but after
   * the media stream was created and pairing was done in response of
   * first acceptance and so those late joiners could not pair.
   */
  function triggerStartPairingForLateJoiner() {
    const isGroupChat = VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType);
    if (!isGroupChat) return;
    const sessionData = controller.get_pChatAdapter().getSessionData();
    if (!sessionData.bMediaServerConnection) return;

    controller.get_pChatAdapter().startPairing(
      VHL.Msg.Types.GROUP_CHAT_PAIRING,
      VHL.Msg.pChatEventHandler(controller, isGroupChat),
      (data) => console.log('triggerd pairing again', data),
      (err) => console.log('cannot pair again', err)
    );
  }

  function eventHandler(event) {
    console.log("from handler", event);
    switch (event.type) {
    case VHL.Msg.Types.PRESENCE:
      switch (event.action) {
      case VHL.Msg.Actions.JOIN:
        handlePresenceJoin(event);
        console.log('yay! someone joined the roster!');
        break;
      case VHL.Msg.Actions.LEAVE:
        /** LEAVE actions are produced for timeouts (navigating away from vhlcentral)
         * and also explicitly logging out of vhlcentral.
         */
        handlePresenceLeave(event);
        break;
      case VHL.Msg.Actions.STATE_CHANGE:
        handleStateChange(event);
        break;
      }
    case VHL.Msg.Types.PRIVATE_CHAT:
      switch(event.action) {
      case VHL.Msg.Actions.HISTORY_MESSAGE:
        // Tell the handler that the message we received is from the history
        handlePrivateChatMessage(event, true);
        break;
      case VHL.Msg.Actions.NEW_MESSAGE:
        handlePrivateChatMessage(event);
        break;
      case VHL.Msg.Actions.HISTORY_RETRIEVAL_COMPLETE:
        // This action is triggered when the retrieval history process is done.
        // The event contains a summary of the number of messages retrieved and a pubnub timetoken.
        console.log(event.status);
        console.log('History retrieval complete');

        break;
      }
      break;

    case VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION:
      switch (event.action) {
        case VHL.Msg.Actions.SUBMITTED_POST_SESSION:
          handleSubmittedMessagePostSession(event);
          break;
      }
      break;
      
      // When a user tries to call other user, this is the event that the recipient receives.
    case VHL.Msg.Types.PARTNER_CHAT_INVITE:
      handlePartnerchatInvitation(event);
      break;

    case VHL.Msg.Types.GROUP_CHAT_INVITE:
      handleGroupchatInvitation(event);
      break;

    case VHL.Msg.Types.TIMEOUT:
      switch (event.action) {
      case VHL.Msg.Actions.PARTNER_CHAT_INVITE:
      case VHL.Msg.Actions.GROUP_CHAT_INVITE:
        console.log('Invitation timeout');
        controller.set_pChatAdapter(null); // Destroy partner chat session.
        controller.renderView({ event: 'invite-timeout' });
        controller.setMyState('available');
        break;
      }
      break;
    } // End switch (event.type)
  }; //End eventHandler
  return eventHandler;
};
