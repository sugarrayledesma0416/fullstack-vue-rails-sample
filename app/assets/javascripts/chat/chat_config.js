VHL.Chat = VHL.Chat || {};

// This is for any dynamic chat / session related data that is accessed globally.
VHL.Chat.GlobalState = {
  INVITING: 'inviting',
  INVITED: 'invited'
};

VHL.Chat.isPartnerChatActivity = function(activityType) {
  // check if the activity type exists and it contains the string 'partner_chat', we can
  // use this function to know if the user is trying to load the chat in a
  // partner_chat or info_gap_partner_chat activity.
  return activityType != null && activityType.indexOf('partner_chat') > -1; 
}

VHL.Chat.isSoloVideoRecordingActivity = function(activityType) {
  return activityType != null && activityType === 'solo_video_recording';
}

VHL.Chat.isSoloVideoIncludedInMultiPartActivity = function() {
  if(document.querySelector("meta[name='VHL.solo_video_included']")) {
    const soloVideoIncluded = document.querySelector("meta[name='VHL.solo_video_included']").content;
    return soloVideoIncluded == 'true' ? true : false;
  } else {
    return false;
  }
}

VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity = function(activityType) {
  return VHL.Chat.isSoloVideoRecordingActivity(activityType) ||
         VHL.Chat.isSoloVideoIncludedInMultiPartActivity();
}

VHL.Chat.isGroupChatActivity = function(activityType) {
  return activityType != null && activityType.indexOf('group_chat') > -1; 
}

VHL.Chat.isActivityWithVideoRecording = function(activityType) {
  return VHL.Chat.isPartnerChatActivity(activityType) ||
         VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(activityType) ||
         VHL.Chat.isGroupChatActivity(activityType);
}

VHL.Chat.init = function(config) {

  const isPartnerChat = VHL.Chat.isPartnerChatActivity(config.activityType);
  const isGroupChat = VHL.Chat.isGroupChatActivity(config.activityType);

  // Determine if chat is enabled on the current course. If no chat is enabled, exit.
  // There are three levels of permission for partner chat/live chat.
  // 1. No access, so partner_chat_enabled/live_chat_enabled is false.
  // 2. Partner chat only, so partner_chat_enabled is true and live_chat_enabled is false.
  // 3. Live chat, which includes partner chat permissions.

  // Additionally, chat can be disabled for a view by setting
  // @disable_chat_on_page to true in a Rails controller.
  const disableChat = document.querySelector("meta[name='VHL.disable_chat_on_page']").content;
  if (!config.permissions.partner_chat_enabled || disableChat === 'true') {
    console.log('Chat is not enabled');
    return;
  }

  const isActivityPopup = document.body.classList.contains('js-activity-popup');
  const isViaVtext = document.body.classList.contains('js-activity-popup-via-vtext');

  if (!config.instructorUser && isActivityPopup && !isViaVtext) {
    console.log('Chat is not enabled on M3 popup activities for students');
    return;
  }

  // Do not run chat on non pchat/infogap activities for instructors
  if (
    config.instructorUser && 
    config.activityType && 
    !(isPartnerChat || isGroupChat)
  ) {
    console.log('Chat is not enabled on nonpchat activities for instructors.');
    return;
  }

  // Exit if Pubnub, the chat messaging service, is not configured.
  if (!config.pubnub_configured) {
    console.log("Chat is not configured. Please add the Pubnub configuration file.");
    return;
  }

  // Show Chat icon in masthead before init to avoid glitch.
  // Iff chat is enabled in course after passing the above conditions.
  $('.js-chat-tab').removeClass('u-hidden');

  function schoolId(schoolIds) {
    if (schoolIds) {
      // If the user has multiple schools. We select the first one in the list by default.
      // This behaviour is commonly used in other places like gradebook roster for enrollment.
      return schoolIds[0];
    } else {
      console.log('No school ids present');
      return null;
    }
  }

  // If the "joinchat" param is present in the params,
  // we are in a tab spawned from a pchat invite
  function joinPartnerChatSessionFromParams() {
    var params = VHL.Common.parse_query_string();
    return params.joinchat === "true";
  }


  function grabActivityTitle() {
    return $('meta[name="VHL.activity_title"]').attr('content');
  }

  /* VHL Messaging Client Wrapper expects a value of type undefined if no chat session is found in the cache.
   * https://github.com/vhl/dirt-driver-chat#1-initialization
   */
  console.log('sessiondata', config.session);
  var chatSession = _.isEmpty(config.session) ? undefined : config.session;

  // Here we create settings that configure chat as either a partner chat or a live chat.
  var settings;
  if (
    (isPartnerChat || isGroupChat)
    && !VHL.Chat.CONFIG.isCompletedPchatView
  ) {
    settings = {
      chatSession:chatSession,
      schoolId: schoolId(config.schoolIds),
      sectionId: config.sectionId,
      courseId: config.courseId,
      activityId: config.activityId,
      /* If the sender is in practice mode, the URL has "/practice"
       *   at the end. That URL is transmitted to the recipient in the
       *   invitation via activity_url. If it ends in "/practice", it will
       *   route the recipient to ActivitiesController#practice instead of
       *   the regular controller action for activities, and practice mode
       *   isn't valid for a user who hasn't submitted yet.
       *
       * Here, we remove "/practice" from the end so that the activity will
       *   open normally for the recipient.
       */
      activityUrl: window.location.pathname.replace(/\/practice$/, ''),
      myUuid: String(config.userId), //All uuid's are stored as strings.
      joinPartnerChatSession: joinPartnerChatSessionFromParams(),
      canRecord: true,
      hasVideoPlayback: true,
      showChatTab: false,
      showRosterPanelBody: false,
      autoScroll: false,
      usePartnerChatActivityStyle: true,
      inviteMetadata: { 
        isPartnerChat, 
        activityTitle: grabActivityTitle(), 
        isGroupChat,
      },
      /* In a partner chat, config.enableVideo is set server-side
       *
       *
       *
       *
       *   based on a URL param passed to the new tab containing
       *   the pchat activity.
       */
      enableVideo: config.enableVideo
    };
 
    if(isPartnerChat) {
      settings.chatContainer = '.js-pchat-activity-container';
      settings.startCallButton = '.js-start-pchat-activity';
    } else {
      settings.chatContainer = '.js-group-chat-activity-container';
      settings.startCallButton = '.js-start-group-chat-activity';
    }

  } else {
    // This block corresponds to live chat configs.
    settings =  {
      chatSession: chatSession,
      sectionId: config.sectionId,
      courseId: config.courseId,
      myUuid: String(config.userId), //All uuid's are stored as strings.
      canRecord: false,
      hasVideoPlayback: false,
      showChatTab: config.permissions.live_chat_enabled
                   || config.permissions.partner_chat_enabled,
      showRosterPanelBody: config.permissions.live_chat_enabled,
      chatContainer: '.js-live-chat-container',
      autoScroll: true,
      usePartnerChatActivityStyle: false,
      startCallButton: '.js-start-call',
      inviteMetadata: { isPartnerChat: false, isGroupChat: false },
      /* In a live chat, enableVideo is set dynamically after config is
       *   initialized. It is set to a sensible default here.
       */
      enableVideo: true
    };
  }

  let chatController = null;
  let wrapperConfig = null;

  // Set the controller and the wraapperConfig just for non solo-video-recording activities.
  // Solo video recording uses a separate logic so none of them are needed.
  // SVR logic: app/assets/javascripts/solo_video_recording/
  if (!VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(config.activityType)) {
    // Instantiate the chat controller.
    chatController = VHL.Chat.controllerFactory(settings);

    // Initialize the clientWrapper.
    wrapperConfig = {
      join_partner_chat_session: settings.joinPartnerChatSession,
      partner_chat_timeouts: {
        invite_timeout_duration: 30, // seconds
        pairing_timeout_duration: 300, // seconds
      },
      group_chat_timeouts: {
        invite_timeout_duration: 40, // seconds
        pairing_timeout_duration: 300, // seconds
      },

      message_history_retrieval: VHL.Msg.PrivateChatHistoryRetrieval.Duration.SEVEN_DAYS,
      heartbeat_interval: 0,
      activity_url: settings.activityUrl,
      school_id: settings.schoolId,
      activity_id: settings.activityId,
      invite_metadata: settings.inviteMetadata
    };
  }

  let mediaConfig = null;
  if(!VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(config.activityType)) {
    mediaConfig = {
      mode: VHL.Msg.MediaStream.Modes.MEDIASERVER,
      media_base_url: '/video_chat',
      partner_media_element: 'partner-video',
      my_media_element: 'my-video',
      playback_media_element: 'playback-video',
      api_key: config.tokboxApiKey,
      cdn_base_url: config.partner_chat_cdn,
      enable_audio: true,
      enable_video: config.enable_video,
      audio_level_events: true // If true, it will allow us to grab audio levels for spinner.
    };
  }

   if(!VHL.Chat.isSoloVideoRecordingOrIncludedInMultiPartActivity(config.activityType)) {
     /**
      * grant_endpoint: The request to the grant endpoint must include a section_id param. This
      * is necessary for the student's auth token to be generated. Instructor sessions will
      * ignore this param, and instead pick up the section id from the focus.
      */
     VHL.Msg.ClientWrapper.setup('/chat?section_id=' + settings.sectionId,
                                 settings.chatSession,
                                 wrapperConfig,
                                 mediaConfig,
                                 VHL.Msg.eventHandler(chatController),
                                 VHL.Msg.cWrapperSuccess(chatController),
                                 VHL.Msg.cWrapperFailure(chatController));
   }
};
