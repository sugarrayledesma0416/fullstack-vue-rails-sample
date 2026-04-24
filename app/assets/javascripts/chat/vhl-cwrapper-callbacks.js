//success callback passed to cWrapper.setup()
VHL.Msg.cWrapperSuccess = function(controller) {
  return function cbSuccess(cAdapter) {
    /* Send chat metrics collected during cWrapper.setup() */
    /**
     * Grant endpoint latency:
     * The duration is measured from immediately before
     * clientWrapper's callAuthAPI is called until callAuthAPI's success callback is called.
     * This metric is only present if no token is found in m3's VhlChat::AuthCache, which causes
     * VHL.Chat.CONFIG.session to be undefined.
     */
    VHL.PerformanceApi.getMetrics('measure.vhl.msg.grant', function(metric) {
      // If there's no pubnub auth session data, we measure how much it takes to retrieve it
      // from the server.
      if(typeof VHL.Chat.CONFIG.session === 'undefined') {
        controller.sendMetrics('pnub_auth_cache_latency', { latency: metric, service: 'pubnub' });
      }
    });

    /**
     * Subscribe latency:
     * The duration is measured from immediately before
     * clientWrapper's subscribeToPubNubChannels is called
     * until the end of the PNConnectedCategory event handler,
     * which is defined in the clientWrapper and invoked from pubnub's library.
     */
    VHL.PerformanceApi.getMetrics('measure.vhl.msg.setState', function(metric) {
      controller.sendMetrics('available_status_latency', { latency: metric, service: 'pubnub' });
    });

    /**
     * Get online members latency:
     * This measures the how long it takes to retrieve a list of
     * online members for all of the sections in my roster.
     */
    VHL.PerformanceApi.getMetrics('measure.vhl.msg.subscribe', function(metric) {
      controller.sendMetrics('pnub_subscribe_latency', { latency: metric, service: 'pubnub' });
    });

    /* Time taken to setup the client wrapper */
    VHL.PerformanceApi.getMetrics('measure.vhl.msg.setup', function(metric) {
      controller.sendMetrics('cwrapper_setup_latency', { latency: metric, service: 'pubnub' });
    });

    function getOnlineMembersSuccess(groupPresence){
      /**
       * Get online members latency:
       * This measures the how long it takes to retrieve a list of
       * online members for all of the sections in my roster.
       */
      VHL.PerformanceApi.getMetrics('measure.vhl.msg.members', function(metric) {
        controller.sendMetrics('get_online_users_latency', { latency: metric, service: 'pubnub' });
      });

      /**
       * This is the structure of the response 'groupPresence' from Pubnub
       * passed to 'getOnlineMemberSuccess' :
       {
       section_1:
       {
       name: "section_1",
       occupancy: 2,
       occupants:
       {
       24:
       {
       device_count: 2,
       state:
       {
       firstName: "Brando",
       lastName: "Kunde",
       isTyping: false,
       name: "vhl_1_student", //TODO see if this can change in clientWrapper
       state: "AVAILABLE",
       username: "vhl_1_student"
       }
       }
       }
       },
       section_2: {
       ... same as section_1 objection
       }
       }
      */

      /**
       * Initialize a Conversation object for
       * all occupants from the 'groupPresence' object.
       * Each Conversation is initialized with a User object.
       * .
       */

      /* getOnlineMembers does not provide first/last username information.
       * We need to get this from the roster payload from the VHL server.
       */

      /* Grab an array of all sections from the roster from the VHL server */
      var rosterSections = _.flatten(_.map(VHL.Chat.CONFIG.roster.courses, function(course){
        return course.sections;
      }));

      _.each(groupPresence, function(group){
        var onlineUsers = [];
        var rosterSection = _.findWhere(rosterSections, { id: group.name });/* group.name refers to the section id */

        _.each(group.occupants, function(occupant, key) {

          /* Do not add myself to the roster */
          if (controller.myUuid !== key) {
            onlineUsers.push(key);

            /* Find the section and user from the VHL server roster info that matches
             * the section/user we are looping over from the getOnlineMembers payload
             */
            var onlineUser = _.find(rosterSection.users, function(user) {
              return key == user.uuid;
            });

            if(onlineUser) {
              controller.initNewRosterMember(onlineUser, rosterSection.id, occupant.state.state);
            };
          } else {
            // Set my state to `available` if my state is not defined on Pubnub.
            var userState = 'available';
            if(!_.isEmpty(occupant.state)) {
              // Here we receive a state that matches the ones defined by VHL.Msg.User.State
              // so we need to convert it to VHL.Chat.Status values (unavailable, available, busy).
              userState = occupant.state.state == 'AWAY' ? 'unavailable' : occupant.state.state;
              // This is a guard in case occupant.state.state is undefined. We default to 'available'.
              userState = typeof(userState) === "string" ? userState.toLowerCase() : 'available';
            }
            controller.setStateForUI(userState.toLowerCase());
          }
        });

        // We need to load the rest of the roster section (i.e. show offline users)
        // We use the onlineUsers to know which users are already shown in the chat view.
        controller.showOfflineUsers(onlineUsers, rosterSection);
      });
    } // End getOnlineMembersSuccess

    function getOnlineMembersFailure(err){
      console.log("There was an error getting online members", err);
      controller.sendMetrics('online_members_error', { error: err, service: 'pubnub' });
    }

    /**
     * This function returns the chat invite type based on the activity type.
     * @returns {string} chat invite type
     */
    function getChatInviteType() {
        if(VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            return VHL.Msg.Types.GROUP_CHAT_INVITE;
        } else {
            return VHL.Msg.Types.PARTNER_CHAT_INVITE;
        }
    };

    controller.set_cAdapter(cAdapter);

    // chat permissions for user
    var chatPermissions = VHL.Chat.CONFIG.permissions;

    // If I don't have live chat but I have pchat
    if (!chatPermissions.live_chat_enabled && chatPermissions.partner_chat_enabled) {
      // If I am in a group chat, partner Chat or infogap activity page
      if (VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType) ||
          VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
        // Build the roster
        cAdapter.getOnlineMembers(
          controller.getSections(),
          getOnlineMembersSuccess,
          getOnlineMembersFailure
        );
      } else {
        // If I am not on a partner chat/infogap activity page, do not get the roster, but do request my own pubnub state:
        // // 1) Determine what my own state is from pubnub
        // // 2) Convert my pubnub state to VHL.Chat.Status values (unavailable, available, busy)
        // // 3) On success, set my state in the client side models & update the availability toggle in the ui
        cAdapter.getUserState(
          controller.myUuid,
          "section_" + VHL.Chat.CONFIG.sectionId,
          function(data) {
            var currentUserState = data.state == 'AWAY' ? 'unavailable' : data.state;
            // It is possible for data.state to return {} if there is no
            // current state for the user on Pubnub. In this case, we set the user to available.
            currentUserState = typeof(currentUserState) === "string" ? currentUserState.toLowerCase() : 'available';
            controller.setStateForUI(currentUserState.toLowerCase());
          }, function (err) {
            console.log('Error getting user state', err);
            controller.sendMetrics('get_state_error', { error: err, service: 'pubnub' });
          }
        );
      }
    } else {
      // Build the roster because I have chat always available.
      // Instructors will always end up with this case, because we hard code their chat permissions
      // to enable both live chat and pchat.
      controller.get_cAdapter().getOnlineMembers(
        controller.getSections(),
        getOnlineMembersSuccess,
        getOnlineMembersFailure
      );
    }

    /* Joining a partner chat:
     * Invite was accepted on a previous tab. Finish
     * pairing the pairing, here, in the new activity tab.
     * View should be initialized with the inviting partner's uuid and section
     */
    if(controller.joinPartnerChatSession) {

      // The `pchatsession` param is parsed and passed as an arg to joinPartnerChatSessionSuccess.
      var pchatSessionFromParams = decodeURIComponent(VHL.Common.parse_query_string().pchatsession);
      var pchatSession = JSON.parse(pchatSessionFromParams);
      var joinPchatViewConfig;

      // Join to the partner chat session and accept the pchat invitation:
      controller.get_cAdapter().joinPartnerChatSession(
        pchatSession,
        function joinPartnerChatSessionSuccess(chatSessionAdapter){
          /* If joining the session is a success:
           * set the pChatAdapter
           * accept the pchat invitation. (At this point, we've opened a new tab but not yet accepted the invitation)
           */
          controller.set_pChatAdapter(chatSessionAdapter);
          controller.get_pChatAdapter().acceptInvite(
            getChatInviteType(),
            VHL.Msg.pChatEventHandler(controller),
            function acceptInviteSuccess() {
              if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
                VHL.Chat.GroupChatChannelIds.push(
                  pchatSession.channel.replace('gs_', '')
                );
                controller.initConversationsForGroupChat();
                controller.renderView({
                  event: 'i-join-pchat',
                });
              }
              console.log('pchat invitation accepted.');
            },
            function acceptInviteFailure(err) {
              console.log(err);
              controller.sendMetrics('accept_pchat_newtab_error', { error: err, service: 'pubnub' });
            }
          ); // end acceptInvite
        },
        function joinPartnerChatSessionFailure(error) {
          console.log(error);
          controller.sendMetrics('join_pchat_newtab_error', { error: error, service: 'pubnub' });
        }
      ); //end joinPartnerChatSession

      // Prepare configuration for the view with the inviting user and the inviting user's section
      var inviting_uuid = controller.get_pChatAdapter().getJoinPartnerSessionData().inviting_uuid;
      var inviting_section_id = controller.get_pChatAdapter().getJoinPartnerSessionData().group_id;
      joinPchatViewConfig = {inviting_uuid: inviting_uuid, inviting_section_id: inviting_section_id};
    } // end if(controller.joinPartnerChatSession)

    console.log('INIT VIEW')
    // If we are joining a pchat, initialize the view with a current conversation of the inviting user.
    controller.initView(controller, joinPchatViewConfig || null);


    /**
     * Render the view with the updated model.
     * If we are accepting a pchat invite, send an event.
     * When group chat accepted in a new tab, then renderView is called
     * after acceptInvite success instead of calling here.
     * It is so because the conversationId is not set to correct value yet.
     */
    console.log('RENDER VIEW')
    if (controller.joinPartnerChatSession) {
      if (!VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
        controller.renderView({
          event: 'i-join-pchat',
        });
      }
    } else {
      controller.renderView();
    }


  }; // End cbSuccess
};


  // failure callback passed to cWrapper.setup()
  VHL.Msg.cWrapperFailure = function(controller) {
    return function cbFailure(error) {
      console.log("setup failed", error);
      controller.sendMetrics('cwrapper_setup_error', { error: error, service: 'pubnub' });
    };
  };
