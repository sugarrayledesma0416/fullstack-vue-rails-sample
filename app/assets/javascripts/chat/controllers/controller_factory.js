// Supported VHL Status
VHL.Chat.Status = {
  'available': VHL.Msg.User.State.AVAILABLE,
  'unavailable': VHL.Msg.User.State.AWAY,
  'busy': VHL.Msg.User.State.BUSY
};

/**
 * @param {object} cWrapper - the clientWrapper library for Pubnub service.
 * @param {object} chatConfig - the chat configurations. It defines if we should boot live chat or other chat type.
 *                              It also defines the VHL Chat session and the sectionId.
 **/

VHL.Chat.controllerFactory = function(config) {

  var config = _.defaults(_.clone(config),
                          {
                            chatSession: undefined,
                            sectionId: null,
                            courseId: null,
                            activityId: null,
                            activityUrl: null,
                            myUuid: null,
                            joinPartnerChatSession: false,
                            canRecord: false,
                            hasVideoPlayback: false,
                            showRosterPanelBody: true,
                            chatContainer: '.js-live-chat-container',
                            usePartnerChatActivityStyle: false,
                            startCallButton: '.js-start-call',
                            cancelCallButton:'.js-cancel-call',
                            loadUI: true,
                            // This value is assigned when we are building the roster in the `getOnlineMembers` callback.
                            currentUserState: null,
                            stats: { pubnub_index: 'vhl-chat-client-pubnub',
                              tokbox_index: 'vhl-chat-client-tokbox' }
                          });

  var _chatApp = new VHL.Chat.ChatApp(VHL.Chat.CONFIG.roster, config.myUuid);
  var _view;
  var _pChatAdapter = null;
  var _pChatEventHandler = null;
  var _joinPartnerSessionData = null;
  var _cAdapter = null;
  var _playbackData = null;
  var _acceptOnNewTab = false; // true only when an invite is recieved with metadata including an activity url (pchat invite)
  var _activitySubmitted = false;

  // TODO extract stats stuff.
  var pubnubDispatcher = new VHL.CarlinDispatch.Logstash(config.stats.pubnub_index);
  var tokboxDispatcher = new VHL.CarlinDispatch.Logstash(config.stats.tokbox_index);

  /* Roster */
  /**
   * Returns a flat array of all sections for all courses in _chatApp.roster
   * @returns {Array}
   */
  function getSections() {
    return _.map(VHL.Chat.CONFIG.grantsRoster.roster.groups,
                 function(group){
                   return group.id;
                 });
  };

  function findConversation(uuid, sectionId) {
    return _chatApp.findConversation(uuid, sectionId);
  }
  
  /**
   * This returns a group chat conversation by conversation id
   * @param {string} conversationId - Group chat conversation id
   * @return {VHL.Chat.Conversation} - conversation instance
   */
  function findGroupConversationById(conversationId) {
    return _chatApp.findGroupConversationById(conversationId);
  }

  /**
   * This returns user objects for a given userIds list.
   * @param {Array<string>} userIds - UserIds list
   * @param {string} sectionId
   * @return {Array<VHL.Chat.User>}
   */
  function getConversationUsersByIds(userIds, sectionId) {
    return _chatApp.getConversationUsersByIds(userIds, sectionId);
  }

  /**
   * A wrapper function to initialize group conversation data.
   */
  function initConversationsForGroupChat() {
    return _view.initConversationsForGroupChat();
  }

  /**
   * addConversation - Add a new conversation.
   * @param  {String} fromUuid - id of user corresponding to conversation
   */
  function addConversation(fromUuid) {
    _chatApp.addConversation(fromUuid);
  }
  
  /**
   * Remove group conversation from model.
   * @param  {string} conversationId
   */
  function removeGroupConversation(conversationId) {
    _chatApp.conversations = _chatApp.conversations.filter(
      (convo) => !(convo.isGroupChat && convo.id === conversationId)
    );
  }

  /**
   * Remove group conversation messages.
   * @param  {string} conversationId
   */
  function removeGroupConversationMessages(conversationId) {
    _chatApp.conversations = _chatApp.conversations.map((convo) => {
      if (convo.isGroupChat && convo.id === conversationId) {
        convo.messages = [];
      }
      return convo
    });
  }

  /**
   * initNewRosterMember
   * @param {object} userProperties - It contains the uuid, first/last name and username of the new roster member.
   * @param {string} userSectionId - The sectionId used by the cWrapper.
   * @param {string} state - One of the three Pnub status (AVAILABLE, AWAY, BUSY) or 'offline'.
   *
   * This function creates a new member in the chat roster and associates the new object to a conversation
   * then we try to retrieve the chat history from Pnub for the new user.
   **/
  function initNewRosterMember(userProperties, userSectionId, state) {
    var availability = availabilityFromState(state);

    // VHL.Chat.CONFIG.pchatActivityRoster will only be defined on pchat
    // or infogap activities via activity presenter on server.
    const pchatRoster = VHL.Chat.CONFIG.pchatActivityRoster;
    const uuid = parseInt(userProperties.uuid);

    // Search pchat roster to see if this user has completed the activity.
    const completed = pchatRoster ? pchatRoster.students_complete.includes(uuid) : null;
    var newUser = new VHL.Chat.User(userProperties.uuid,
                                    userProperties.first_name,
                                    userProperties.last_name,
                                    userProperties.username,
                                    userSectionId,
                                    availability,
                                    completed);

    _chatApp.conversations.push(new VHL.Chat.Conversation(newUser));
  }

  /**
   * Add a new conversation instance into conversations array for group chat.
   * @param {Array<string>} otherUserIds - User Ids of the other chat participants.
   * @param {string} sectionId - The sectionId used by the cWrapper.
   * @param {string} conversationId - Conversation id for a group for group chat.
   *
   * This function clears existing group conversation for the conversationId if already exists.
   * This is for usecase when user did not leave conversation view and accepts a call again.
   **/
  function initConversationDataForGroupChat(otherUserIds, sectionId, conversationId) {
    const userList = this.getConversationUsersByIds(otherUserIds, sectionId)
    const newUsers = userList.map(
      (user) => new VHL.Chat.User(
        user.uuid,
        user.firstName,
        user.lastName,
        user.username,
        user.sectionId,
        user.state,
        user.completedActivity
        )
      );
    _chatApp.conversations = _chatApp.conversations.filter(
      (convo) => convo.id !== conversationId
    );
    _chatApp.conversations.push(new VHL.Chat.Conversation(newUsers, conversationId));
  }

  function availabilityFromState(state) {
    var availability;
    switch(state) {
    case VHL.Msg.User.State.AVAILABLE:
      availability = 'available';
      break;
    case VHL.Msg.User.State.AWAY:
      availability = 'unavailable';
      break;
    case VHL.Msg.User.State.BUSY:
      availability = 'busy';
      break;
    case 'offline':
      availability = 'offline';
      break;
    }
    return availability;
  }

  function showOfflineUsers(onlineUsers, rosterSection) {
    var offlineUsers = _.reject(rosterSection.users, function(user) {
      return _.contains(onlineUsers, user.uuid);
    });

    _.each(offlineUsers, function(offlineUser) {
      initNewRosterMember(offlineUser, rosterSection.id, 'offline');
    });
  }

  /* Presence */

  /**
   * VHL.Chat.setUserAvailable - Use this
   * when you want to force
   * a user into an "available" state
   * when the user closes the browser
   * or uses the "back" button.
   **/
  VHL.Chat.setUserAvailable = function() {
    setMyState('available');
  }

  /**
   * setMyState - change current state
   * @param {String} one of the states defined in the VHL.Msg.User.State object.
   * @param {Function} cbSuccess Callback function for setting state  success.
   * @param {Function} cbFailure Callback function for setting state failure.
   */

  function setStateForUI(myState) {
    config.currentUserState = myState;
  }

  function setMyState(myState, cbSuccess, cbFailure) {
    // invitation accepted. Changing state to myState
    var stateOptions = {
      'state': VHL.Chat.Status[myState],
      'isTyping': false
    };

    var sections = getSections();
    // Setup value that is used by the availability toggle.
    setStateForUI(myState);


    _cAdapter.updateMyStateMultiGroups(sections, stateOptions, function(data) {
      console.log(data);
      console.log('You are', myState, 'now for sections', sections.join());

      VHL.PerformanceApi.getMetrics('measure.vhl.msg.setState', function(metric) {
        // We set the state for all users when we initialize the roster, so this metric
        // can be undefined while setting everything up.
        if (metric != null) {
          sendMetrics('change_status_latency', { latency: metric, service: 'pubnub' });
        }
      });

      if (myState === 'busy') {
        // The user has entered a video chat or partner chat.
        // Make sure if they close the browser window,
        // they are returned to a busy state.
        window.addEventListener("beforeunload", function () {
          // In the event that the user has clicked "logout",
          // The chat system will not be available, and
          // VHL.Chat.setUserAvailable will be unavailable.
          try {
            VHL.Chat.setUserAvailable();
          }
          catch(error) {
            console.log("The chat application is not available", error);
            sendMetrics('chat_app_notavailable_error', { error: error, service: 'pubnub' });
          }
        });
      }
      if(typeof cbSuccess === 'function') {
        cbSuccess();
      }
    }, function(error) {
      console.log('We cannot set you in a', myState, 'state for sections', sections.join(), error);
      sendMetrics('setting_state_error', { error: error, service: 'pubnub' });
      if(typeof cbFailure === 'function') {
        cbFailure();
      }
    });
  }
  /**
   * setAvailability - Set user's availability.
   * @param {Boolean} status - true = available; false = not available.
   * @param {Function} cbSuccess Callback function to pass to setMyState's success callback.
   * @param {Function} cbFailure Callback function to pass to setMyState's failure callback.
   */

  function setAvailability(status, cbSuccess, cbFailure) {
    console.log('Setting availability to ' + status);

    var state = status ? 'available' : 'unavailable';
    setMyState(state, cbSuccess, cbFailure);
  }

  /* Messaging */
  /**
   * sendMessage - Call the PubNub adapter with new message details from the View.
   * @param  {String} recipientId userId of the other chat participant.
   * @param  {String} sectionId   Id of the section shared by the participants.
   * @param  {String} message     Text of the message.
   * @param  {function} cbSuccess Callback function for send message success.
   * @param  {function} cbFailure Callback function for send message failure.
   */
  function sendMessage(recipientId, sectionId, message,
                        cbSuccess, cbFailure) {
    _cAdapter.sendMessage(
      recipientId,
      sectionId,
      message,
      cbSuccess,
      cbFailure
    );
  }

  /**
   * sendGroupMessage - Call the PubNub adapter with new message details from the View.
   * @param  {Array<string>} recipientIds - User Ids of the other chat participants.
   * @param  {string} group - Group chat channel name.
   * @param  {string} message - Text of the message.
   * @param  {function} cbSuccess - Callback function for send group message success.
   * @param  {function} cbFailure - Callback function for send group message failure.
   */
  function sendGroupMessage(recipientIds, group, message, cbSuccess, cbFailure) {
    _cAdapter.sendGroupMessage(
      recipientIds,
      group,
      message,
      cbSuccess,
      cbFailure
      );
  }

  /**
   * sendSubmittedMessagePostSession - Call the PubNub adapter with
   * PARTNER_CHAT_CONTROL_MESSAGE_POST_SESSION message, SUBMITTED_POST_SESSION action details.
   * @param  {String} recipientId userId of the other chat participant.
   * @param  {String} sectionId Id of the section shared by the participants.
   * @param  {function} cbSuccess Callback function for send message success.
   * @param  {function} cbFailure Callback function for send message failure.
   */
  function sendSubmittedMessagePostSession(recipientId, sectionId,
    cbSuccess, cbFailure) {
      _cAdapter.sendSubmittedMessagePostSession(
        recipientId,
        sectionId,
        cbSuccess,
        cbFailure
      );
  }
  
  function addMessage(groupId, message, is_history_message) {
    _chatApp.addMessage(groupId, message, is_history_message);
  }

  function retrieveMessageHistoryFor(uuId, sectionId, message_limit) {
    message_limit = message_limit || 10; // 10 messages as a limit by default
    _cAdapter
      .retrieveMessageHistory(uuId,
                              sectionId,
                              message_limit,
                              false, // If true, retrieve all messages up to limit in one call. false to retrieve in batches.
                              {}, // Options for future extensions.
                              function(success) {
                                console.log('Waiting for pubnub to send message history');
                              }, function(error) {
                                console.log('history retrieve error', error);
                                sendMetrics('retrieve_history_error',
                                  { error: error, service: 'pubnub' });
                              });
  }

  /**
   * This function returns true
   * if invitation comes from a Live Chat
   * */
  function isLiveChatInvitation() {
    const activityUrl = _pChatAdapter.getJoinPartnerSessionData().activity_url;
    return (activityUrl === '/' || activityUrl == null);
  }

  /**
   * This function returns the chat invite type based on the activity type.
   * @returns {string} chat invite type
   */
  function getChatInviteType() {
    return _view.is_group_chat ? VHL.Msg.Types.GROUP_CHAT_INVITE : VHL.Msg.Types.PARTNER_CHAT_INVITE;
  }

  /**
   * This function returns the recording type based on the activity type.
   * @returns {string} recording type.
   */

  function getRecordingType() {
    return (_view.is_group_chat ? VHL.Msg.Types.GROUP_CHAT_MEDIA_STREAM : VHL.Msg.Types.PARTNER_CHAT_MEDIA_STREAM);
  }

  /* Invitations / Video calls */
  /**
   * startCall - begin an audio/video call
   * @param {String} uuid - id of the user to call
   */
  function startCall(uuid, sectionId, courseId) {
    console.log('Calling ', uuid + ' - ' + sectionId);

    // The sender wants to start a call (video chat) with the recipient. We need to pass
    // the uuid of the user, the sectionId and the courseId.
    // NOTE: we assume that groupId === sectionId, that's why we are passing sectionId twice.
    _cAdapter.initiatePartnerChat(uuid, sectionId, courseId, sectionId, function(partnerChatAdapter) {
      console.log('partner chat initialized.');

      // When the session for the call (video chat) is ready to be used, we can send the invitation
      // to the recipient.
      _pChatAdapter = partnerChatAdapter;

      _pChatAdapter.sendInvite(VHL.Msg.Types.PARTNER_CHAT_INVITE, function() {
        console.log('Invitation sent.');

      // Set focus on the cancel button.
        $(config.cancelCallButton).focus();

        // Invitation sent, send metrics.
        VHL.PerformanceApi.getMetrics('measure.vhl.msg.sendInvite', function(metric) {
          // Time it took to send an invitation.
          sendMetrics('send_invitation_latency', { latency: metric, service: 'pubnub' });
        });

        setMyState('busy');
      },
        function(error) {
          console.log('Error sending invite:', error);
          sendMetrics('send_invite_error', { error: error, service: 'pubnub' });
          _view.setMediaStep('initial');
        });
    }, function(error) {
      console.log('error intializing partner chat', error);
      sendMetrics('pchat_initialize_error', { error: error, service: 'pubnub' });
    });

  }

  function startGroupCall(inviteesUuids, sectionId, courseId) {
    var group_chat_view = new GroupChatView();
    var group_chat_channel_id = group_chat_view.group_chat_channel_id();
    _cAdapter.initiateGroupChat(group_chat_channel_id, inviteesUuids, sectionId, courseId, sectionId, function(partnerChatAdapter) {
      console.log('group chat initialized.');

      // When the session for the call (video chat) is ready to be used, we can send the invitation
      // to the recipient.
      _pChatAdapter = partnerChatAdapter;

      _pChatAdapter.sendInvite(VHL.Msg.Types.GROUP_CHAT_INVITE, function() {
        console.log('Invitation sent.');

      // Set focus on the cancel button.
        $(config.cancelCallButton).focus();

        // Invitation sent, send metrics.
        // TODO: should we add metrics as with pChat.
        setMyState('busy');
      },
      function(error) {
        console.log('Error sending invite:', error);
        // TODO: should we add metrics as with pChat.
        _view.setMediaStep('initial');
      });
    }, function(error) {
      console.log('error intializing group chat', error);
      // TODO: should we add metrics as with pChat.
    });
  }

  function acceptInvitation() {
    if (_acceptOnNewTab) {
      setMyState('busy');
      /* Accept a pchat invitation:
       * If an activity URL was passed via the invitation, this is a partner chat invite.
       * Open the activity in a new tab. Video pairing completes in the new tab.
       */

      // Append pairing info to new activity tab URL

      var pChatJoinSessionDataEncoded = encodeURIComponent(JSON.stringify(_joinPartnerSessionData));
      var protocol = window.location.protocol + "//";
      var host = window.location.host;

      /* The value of config.enableVideo has just been set in chat_view.js, in
       * the click handler for .js-accept-invitation.
       */
      window.open(protocol + host + _joinPartnerSessionData.activity_url + "?joinchat=true&enable_video=" + config.enableVideo + "&pchatsession=" + pChatJoinSessionDataEncoded);
    } else {
      /* Accept a live chat invitation:
       * If no activity URL was passed, this is a live chat invitation.
       * Video pairing completes in this tab.
       */
      _pChatAdapter.acceptInvite(getChatInviteType(), _pChatEventHandler,
                                 function acceptInviteSuccess() {
                                   console.log('Invitation accepted. Telling the sender.');
                                   VHL.PerformanceApi.getMetrics('measure.vhl.msg.acceptInvite', function(metric) {
                                     // Time it took to tell Pubnub that the invitation was accepted.
                                     sendMetrics('accept_invite_latency',
                                       { latency: metric, service: 'pubnub' }
                                     );
                                   });

                                   setMyState('busy');
                                 },
                                 function acceptInviteFailure(err) {
                                   console.log('Error accepting invitation', err);
                                   sendMetrics('accept_invite_error',
                                     { error: err, service: 'pubnub' }
                                   );
                                 });
    }
  }

  function declineInvitation(chatInviteType) {
    const inviteType = chatInviteType || getChatInviteType();
    _pChatAdapter.rejectInvite(inviteType, function() {
      console.log('rejected!');

      VHL.PerformanceApi.getMetrics('measure.vhl.msg.rejectInvite', function(metric) {
        // Time it took to tell Pubnub that the invitation was rejected.
        sendMetrics('reject_invite_latency',
          { latency: metric, service: 'pubnub' }
        );
      });

      endPartnerChatSession();
    }, function(err) {
      console.log('We cannot reject the invitation', err);
      sendMetrics('reject_invite_error', { error: err, service: 'pubnub' });
    });
  }

  /**
   * revokeCall - cancel an audio/video call
   * @param {String} uuid - id of the user to call
   */
  function revokeCall() {
    _pChatAdapter.revokeInvite(getChatInviteType(), function() {
      console.log('We revoke your invitation to call!');

      VHL.PerformanceApi.getMetrics('measure.vhl.msg.revokeInvite', function(metric) {
        // Time it took to tell Pubnub that an invitation was revoked.
        sendMetrics('revoke_invite_latency', { latency: metric, service: 'pubnub' });
      });

      endPartnerChatSession();
    }, function(err) {
      console.log('Error trying to revoke the call', err);
      sendMetrics('revoke_invite_error', { error: err, service: 'pubnub' });
    });

    setMyState('available');
  }

  function endCall() {
    disableSubmit();
    setMyState('available');
    _pChatAdapter.endSession(function() {
      endPartnerChatSession();
      console.log('Call ended');
      if(get_activitySubmitted()) {
        // reload this activity without the query string
        location.replace(location.origin + location.pathname);
      }
    }, function(err) {
      console.log('Error trying to end the call', err);
      sendMetrics('end_call_error', { error: err, service: 'pubnub' });
    });
  }

  /* cAdapter and pChatAdapter */
  function get_cAdapter() {
    return _cAdapter;
  }

  function set_cAdapter(cAdapter) {
    _cAdapter = cAdapter;
  }

  function get_pChatAdapter() {
    return _pChatAdapter;
  }

  function set_pChatAdapter(pChatAdapter) {
    _pChatAdapter = pChatAdapter;
  }

  function set_playbackData(metaData) {
    _playbackData = metaData;
  }

  function set_activitySubmitted(state) {
    _activitySubmitted = state;
  }

  function get_activitySubmitted() {
    return _activitySubmitted;
  }

  function get_myCurrentState() {
    return config.currentUserState;
  }

  function endPartnerChatSession() {
    _pChatAdapter = null;
    _pChatEventHandler = null;
    _joinPartnerSessionData = null;
    _acceptOnNewTab = false;
  }

  function isPartnerInSamePchatActivity(activityUrl) {
    let isSameActivity = window.location.pathname.indexOf(activityUrl) > -1;
    
    // This code gets into details of sectionId/activityId if above simple check returns false.
    // Below code section is to handle use case when instructor calls from same activityid but
    // sectionid is mismatched in url because instructor is at section 0.
    if (!isSameActivity && _pChatAdapter && VHL.Chat.CONFIG) {
      let sessionData = _pChatAdapter.getSessionData();
      if (sessionData) {
           
        // This is based on assumption that 
        // condition (sessionData.me_role === "invited") is true here.
        let sectionIdWithPrefix = sessionData.inviting.section_id;

        // For partner user, sectionID & activityID are taken from pchat sessionData.
        // Remove prefix because sessionData stores section_id in format of "section_<section id>".
        let sectionIDForPartner = sectionIdWithPrefix.slice(sectionIdWithPrefix.indexOf("_") + 1);
        let activityIDForPartner = sessionData.activity_id;
    
        // For current user, sectionID & activityID are taken from VHL.Chat.CONFIG.
        // Because sessionData.invited.section_id does not give required value for current user.
        // Another alternative for sectionID is value from meta tag ('meta[name="VHL.section_id"]')
        // but is not used here for the lack of clarity about any advantage
        // over VHL.Chat.CONFIG.sectionId.
        let sectionIDForCurrentUser = VHL.Chat.CONFIG.sectionId.toString();
        let activityIDForCurrentUser = VHL.Chat.CONFIG.activityId;
           
        // Checks for not-empty value (includes "0") and evaluate the expression to boolean value.
        let isSameActivityId = ((activityIDForCurrentUser || activityIDForCurrentUser === "0") 
          && activityIDForCurrentUser === activityIDForPartner) ? true : false;
        let isSameSectionId = ((sectionIDForCurrentUser || sectionIDForCurrentUser === "0")
          && sectionIDForCurrentUser === sectionIDForPartner) ? true : false;
        let isOneSectionIdIsZero = sectionIDForCurrentUser === "0" || sectionIDForPartner === "0";
        
        // Compare activityIds and ignore comparison of sectionIds if one of the sectionId is 0.
        isSameActivity = isSameActivityId && (isSameSectionId || isOneSectionIdIsZero);
      }
    }

    return isSameActivity;
  }

  function beginPartnerChatSession(pChatEventHandler) {
    /* Extract metadata from the pchatAdapter
     * that provides invite details.
     * If the metadata includes an activityUrl,
     * we open a new tab and join the video session
     * in the new tab.
     */
    _pChatEventHandler = pChatEventHandler;
    _joinPartnerSessionData = _pChatAdapter.getJoinPartnerSessionData();
    var activityUrl = _joinPartnerSessionData.activity_url;
    var activityUrlDefined = activityUrl !== '/' && activityUrl != null && activityUrl.length > 0;

    // If there is an activityUrl and is not empty and is not an empty string and is not using the
    // partner chat activity style for chat, open in a new tab.

    if (activityUrlDefined && !config.usePartnerChatActivityStyle) {
      _acceptOnNewTab = true;
    } else {
      // If the activityURL does not match the one where the user is located, open a new tab.

      _acceptOnNewTab = !isPartnerInSamePchatActivity(activityUrl) && activityUrlDefined;
    }
  }

  function get_acceptOnNewTab() {
    return _acceptOnNewTab;
  }

  /* View */

  function renderView(options) {
    var data = { data: _chatApp.getViewData() };
    if (_.isObject(options)) {
      _.extend(data, options);
    }
    _view.update(data);
    if ((VHL.Chat.CONFIG.activityType === 'group_chat') && (typeof GroupChatView !== 'undefined')) {
      var group_chat_view = new GroupChatView();
      group_chat_view.chat_view = _view;
      group_chat_view.init_invite_checkboxes();
      group_chat_view.init_invite_button();
    }
  }

  /**
   * Send a new audio level event to the view
   * @param  {Number} level [description]
   */
  function updateAudioLevel(audioLevel) {
    _view.update({event: 'audio-level', level: audioLevel});
  }

  /*
   * viewConfig
   * @param {Object} viewConfig - view specific configuration that is unavailable during controller construction.
   * When initializing the view on a new tab from a pchat invite, the config object must include:
   * inviting_uuid
   * inviting_section_id
   */
  function viewConfiguration(viewConfig) {
    if (viewConfig) {
      // If view specific configs were passed, extend them with the chat application configuration.
      return _.extend(viewConfig, config);
    }
    return config;
  }

  function initView(controller, viewConfig) {
    if (config.loadUI) {
      _view = new VHL.Chat.View(controller, viewConfiguration(viewConfig));
    } else {
      /* If we are launching chat without an UI, view is an object with public functions as no-ops. */
      _view = {
        updateAvailability: function() {},
        update: function() {}
      };
    }
  }

  /* Metrics */
  function sendMetrics(eventName, data) {
    if (data.service === 'pubnub') {
      console.log("dispatched to pubnub index:" + eventName, data);
      pubnubDispatcher.dispatch(eventName, data);
    } else if (data.service === 'tokbox') {
      console.log("dispatched to tokbox index:" + eventName, data);
      tokboxDispatcher.dispatch(eventName, data);
    }
  }

  /* Recording */
  function startRecording() {
    let recording_type = getRecordingType();
    _pChatAdapter.startRecording(recording_type, function() {
      VHL.PerformanceApi.getMetrics('measure.vhl.media.startRecording', function(metric) {
        // Time it took to tell Tokbox to start recording.
        // Started by me.
        sendMetrics('start_recording_latency', { latency: metric, service: 'tokbox' });
      });

      console.log('Recording started by', config.myUuid);
    }, function(error) {
      console.log('Error trying to start a video recording:', error);
      sendMetrics('start_recording_error', { error: error, service: 'tokbox' });
    });
  }

  function stopRecording() {
    let recording_type = getRecordingType();
    _pChatAdapter.stopRecording(recording_type, function() {
      VHL.PerformanceApi.getMetrics('measure.vhl.media.stopRecording', function(metric) {
        // Time it took to tell Tokbox to stop recording.
        // Started by me.
        sendMetrics('stop_recording_latency', { latency: metric, service: 'tokbox' });
      });

      console.log('Recording stopped by', config.myUuid);
    }, function(error) {
      console.log('Error trying to stop the video recording:', error);
      sendMetrics('stop_recording_error', { error: error, service: 'tokbox' });
    });
  }

  /* Sync playback process to replay recording for both users.
   * This method needs to be called before replayRecording(). */
  function syncPlayback() {
    const syncSuccess = () => {
      VHL.PerformanceApi.getMetrics('measure.vhl.db.recordingStatus', function(metric) {
        sendMetrics('finish_polling_latency', { latency: metric, service: 'tokbox' });
      });

      VHL.PerformanceApi.getMetrics('measure.vhl.cdn.playbackRecording', function(metric) {
        // Started by me.
        sendMetrics('start_playback_latency', { latency: metric, service: 'pubnub' });
      });

      console.log('Playback sync started');
    };
    const syncError = (error) => {
      console.log('Error trying to sync playback', error);
      sendMetrics('sync_playback_error', { error: error, service: 'pubnub' });
    };

    console.log('Starting playback with', _playbackData);
    _view.update({event: 'i-play-recording'});

    var recording_type = getRecordingType();
    _pChatAdapter.startRecordingPlaybackWithPartnerSync(_playbackData.recording_id,
                                                        recording_type,
                                                        syncSuccess,
                                                        syncError);
  }

  /* Replay a recording */
  function replayRecording() {
    const replaySuccess = () => console.log('Playback started');
    const replayError = (error) => {
      console.log('Error trying to play recording', error);
      sendMetrics('start_playback_error', { error: error, service: 'pubnub' });
    };

    this.disableSubmit();
    _view.update({event: 'they-play-recording'});

    _pChatAdapter.startRecordingPlayback(_playbackData.recording_id,
                                          replaySuccess,
                                          replayError);
  }

  /*
   * Enable/disable video and change button state.
   *
   * For a pchat activity opening in a new tab,
   *   the enable_video setting is passed to the config
   *   from the server via a URL param.
   */
  function setVideoSharing() {
    _view.setVideoSharing(config.enableVideo);
  }

  function enableAudio(isEnabled) {
    get_pChatAdapter().enableAudio(isEnabled);
  }

  function enableVideo(isEnabled) {
    get_pChatAdapter().enableVideo(isEnabled);
  }

  /* Sync stopping playback */
  function syncStopPlayback() {
    const stopSuccess = () => {
      console.log('Playback stopped');
      _view.update({event: 'i-stop-playback'});
    }
    const stopError = (error) => {
      console.log('Error trying to sync stop playback', error);
      sendMetrics('stop_playback_error', { error: error, service: 'pubnub' });
    };

    var recording_type = getRecordingType();
    _pChatAdapter.stopRecordingPlaybackWithPartnerSync(recording_type, stopSuccess, stopError);
    console.log('Stopping playback with', _playbackData);
  }

  /* Respond to remote user stopping playback. */
  function stopPlayback() {
    let recording_type = getRecordingType();
    _pChatAdapter.stopRecordingPlayback(recording_type,
        function success() {
          _view.update({event: 'they-stop-playback'});
        },
        function error(err) {
          console.log('error stopping playback from remote.', err);
          sendMetrics('stop_playback_error', { error: err, service: 'pubnub' });
        }
    );
  }

  /* Trigger other user to reset recording UI for a redo */
  function redoRecordSync(data) {
    var controlMessageType = (_view.is_group_chat ?
                             VHL.Msg.Types.GROUP_CHAT_CONTROL_MESSAGE :
                             VHL.Msg.Types.PARTNER_CHAT_CONTROL_MESSAGE);      
    _pChatAdapter.sendControlMessage(
      { type: 'sync-redo' },
      () => {
        // success:
        console.log('Sent ctrl msg to redo recording.');
        VHL.PerformanceApi.getMetrics('measure.vhl.msg.sendControlMessage', function(metric) {
          sendMetrics('send_control_message_latency', { latency: metric, service: 'pubnub' });
        });
      },
      (error) => {
        // error:
        console.log('Ctrl msg to redo record failed.', error);
        sendMetrics('redo_record_error', { error: error, service: 'pubnub' });
      },
      controlMessageType
    );
  }

  function assignInfoGapReference(label) {
    /* If we are in an info-gap activity, show the given
     *   reference. Expected values are 'a' for the first
     *   reference and 'b' for the second.
     */
    _view.assignInfoGapReference(label);
  }

  /* Use this to disable the submit button on pchat activities */
  function disableSubmit() {
    _view.disableSubmit();
  }

  /* This method enables the submit button on chat activities */
  function enableSubmit() {
    _view.enableSubmit();
  }

  /** Get map of conversationId => last-opened timestamp from local storage.
   *    If it's not in local storage yet, return a hash. Make sure that the
   *    returned hash has an entry for the current user.
   */
  function getLastOpenedTimes() {
    /* If lastOpenedTimes is not yet in storage, the get will return null,
     *   and the JSON parse will also return null. In that case, set the var
     *   to an empty hash so that we can add an entry for the current user.
     */
    var storageData = sessionStorage.getItem('lastOpenedTimes');
    var lastOpenedTimes = storageData ? JSON.parse(storageData) : {};

    /* There may not be an entry in the map for the current user.
     *   Add one if it's not there so that get/setLastOpenedTime will have
     *   a hash to read from and set a key/value in.
     */
    if (_.isUndefined(lastOpenedTimes[this.myUuid])) {
      lastOpenedTimes[this.myUuid] = {};
    }
    return $.extend({}, lastOpenedTimes);
  }

  /* Find last-opened time for the given conversationId. */
  function getLastOpenedTime(conversationId) {
    return this.getLastOpenedTimes()[this.myUuid][conversationId];
  }

  /** Set the last-opened timestamp for the given conversationId to now.
   *    Put the updated convo-ID/timestamp into local storage.
   */
  function setLastOpenedTime(conversationId) {
    var lastOpenedTimes = this.getLastOpenedTimes();

    /** Store conversationId => timestamp map for the current user.
     *    This is to allow for multiple users to log in on the same client.
     */
    lastOpenedTimes[this.myUuid][conversationId] = Date.now();

    sessionStorage.setItem('lastOpenedTimes', JSON.stringify(lastOpenedTimes));
  }

  /* Returned as a controller object */
  return {
    setStateForUI: setStateForUI,
    myUuid: config.myUuid,
    joinPartnerChatSession: config.joinPartnerChatSession,
    getSections: getSections,
    findConversation: findConversation,
    findGroupConversationById: findGroupConversationById,
    getConversationUsersByIds: getConversationUsersByIds,
    initConversationsForGroupChat: initConversationsForGroupChat,
    addConversation: addConversation,
    removeGroupConversation: removeGroupConversation,
    removeGroupConversationMessages: removeGroupConversationMessages,
    initNewRosterMember: initNewRosterMember,
    initConversationDataForGroupChat: initConversationDataForGroupChat,
    showOfflineUsers: showOfflineUsers,
    setMyState: setMyState,
    setAvailability: setAvailability,
    sendMessage: sendMessage,
    sendGroupMessage: sendGroupMessage,
    sendSubmittedMessagePostSession: sendSubmittedMessagePostSession,
    addMessage: addMessage,
    retrieveMessageHistoryFor: retrieveMessageHistoryFor,
    startCall: startCall,
    startGroupCall: startGroupCall,
    beginPartnerChatSession: beginPartnerChatSession,
    acceptInvitation: acceptInvitation,
    declineInvitation: declineInvitation,
    revokeCall: revokeCall,
    endCall: endCall,
    get_cAdapter: get_cAdapter,
    set_cAdapter: set_cAdapter,
    get_pChatAdapter: get_pChatAdapter,
    set_pChatAdapter: set_pChatAdapter,
    get_acceptOnNewTab: get_acceptOnNewTab,
    get_myCurrentState: get_myCurrentState,
    initView: initView,
    renderView: renderView,
    updateAudioLevel: updateAudioLevel,
    sendMetrics: sendMetrics,
    startRecording: startRecording,
    stopRecording: stopRecording,
    set_playbackData: set_playbackData,
    syncPlayback: syncPlayback,
    replayRecording: replayRecording,
    setVideoSharing: setVideoSharing,
    enableAudio: enableAudio,
    enableVideo: enableVideo,
    syncStopPlayback: syncStopPlayback,
    stopPlayback: stopPlayback,
    redoRecordSync: redoRecordSync,
    set_activitySubmitted: set_activitySubmitted,
    get_activitySubmitted: get_activitySubmitted,
    assignInfoGapReference: assignInfoGapReference,
    disableSubmit: disableSubmit,
    enableSubmit: enableSubmit,
    getLastOpenedTime: getLastOpenedTime,
    getLastOpenedTimes: getLastOpenedTimes,
    setLastOpenedTime: setLastOpenedTime,
    isLiveChatInvitation: isLiveChatInvitation
  }; //end return
};
