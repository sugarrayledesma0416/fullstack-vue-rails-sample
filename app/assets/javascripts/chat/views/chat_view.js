//= require music/features/accent_bar_component/accentBarComponent
/* global VHL: true, swfobject: true */

/* ======================================================= *

    VHL.Chat.View

    UI event handlers and DOM manipulation

    1. The View Constructor
    2. Constants
    3. Widget
    4. Conversations
    5. Messages
    6. Invitations
    7. Video
    8. Misc. UI
    9. Rendering
   10. User Events
   11. Update the View (Public API)


/* ==== 1. View Constructor =================================== */

VHL.Chat.View = (function() {
  var self;
  var dataCache = { conversations: [] };
  var callAudio = null;
  const audio = new VHL.Audio.File('/text_selected.mp3');

  /** View
   * @constructor - View must be constructed after the DOM is ready.
   * @param {Object} controller - the chat controller.
   * @property {String} dataCache - Cached version of model data.
   * @property {Boolean} available - state of the local user's presence setting.
   * @property {Boolean} audioOn - state of the audio toggle.
   * @property {Boolean} videoOn - state of the camera toggle.
   * @property {String} conversationTemplate - markup template for a single conversation.
   * @property {String} rosterTemplate - markup template for the roster.
   * @property {String} messageTemplate - markup template for a single message.
   * @property {Object} unreadConversations - conversation Ids with unread messages splited by ','.
   * @property {Object} currentConversation - tracks open conversation details:
   *                    {String} otherUserId - who you're chatting with
   *                    {String} sectionId - what section you share
   *                    {String} mediaStep - name of UI template currently in use for media chat.
   * @property {Object} ui - (private) various String constants for selectors, states, and messages.
   **/
  function View(controller, config) {
    self = this;
    this.unreadConversations = sessionStorage.getItem('conversationList') ?
                               sessionStorage.getItem('conversationList').split(',') : [];
    this.config = config;
    this.controller = controller;
    this.available = config.currentUserState === 'available';
    this.audioOn = true;
    this.videoOn = true;
    this.conversationTemplate = $(ui.conversationTemplateId).html();
    this.rosterTemplate = $(ui.rosterTemplateId).html();
    this.messageTemplate = $(ui.messageTemplateId).html();
    this.invitationTemplate = $(ui.invitationTemplateId).html();
    this.startCallButton = config.startCallButton;
    this.recordingUIIsActive = false;
    this.recordBtn = null;
    this.reviewBtn = null;
    this.redoRecordBtn = null;
    this.references = {
      'a': $(ui.referenceA),
      'b': $(ui.referenceB)
    };
    this.userIsInstructor = $(ui.referenceContainer).data('userIsInstructor');

    this.audioLevel = 0;
   // This function is used to alert users if it tries to leave the page
   // during a partner chat video using the beforeunload window event.
   // Some browsers display the returned string in the dialog box, but others
   // display their own message
    this.alertOnPchatLeave =  function (e) {
      if (!VHL.Common.shouldPreventWarningsAfterTimeout()) {
        e.preventDefault();
        e.returnValue = "Are you sure you want to leave?";
      }
    }

    this.avCheck = new VHL.Chat.AVCheck();

    // Object to track current conversation details.
    this.currentConversation = {
      otherUserId: null,
      sectionId: null,
      mediaStep: 'initial',
      recordingStep: 'initial'
    };

    const accentBarEnabled = document.querySelector('meta[name="VHL.program_accent_bar_enabled"]')?.content === 'true' || false;
    const inInstitutionAdmin = document.querySelector('meta[name="VHL.in_institution_admin"]')?.content === 'true' || false;
    if (accentBarEnabled && !inInstitutionAdmin) {
      this.accentBar = new VHL.AccentBarComponent();
    }

    attachEventHandlers();
    this.updateAvailabilityUI(this.available);
    customizeUI();

    // Show chat widget.
    $(ui.chatWidget).removeClass(ui.isHidden);
    // The video object is created at initialization
    // time, and moved to where it is needed, so we can just re-use one
    // instead of having multiple video objects hanging around.
    // When not in use, it sits inside a hidden element.

    if(this.config.joinPartnerChatSession) {
      // If joinPartnerChatSession is true, we have accepted a pchat invite in a new activity tab.
      // initialize the view with currentConversation of inviting partner and load history.
      this.currentConversation.otherUserId = self.config.inviting_uuid;
      this.currentConversation.sectionId = self.config.inviting_section_id;
      this.controller.retrieveMessageHistoryFor(this.currentConversation.otherUserId,
                                                this.currentConversation.sectionId);
    }
  }

  /* ===================================================== *
       private vars and functions
   * ===================================================== */


  /* ==== 2. Constants =================================== */

  var ui = {
    // Template selectors:
    rosterTemplateId:       '#roster-template',
    conversationTemplateId: '#conversation-template',
    groupChatConversationTemplateId: 'group-chat-conversation-template',
    messageTemplateId:      '#message-template',
    invitationTemplateId:   '#chat-invitation-template',

    // Element selectors:
    rosterDisclosureBtn:  '.js-disclosure--roster__btn',
    rosterDisclosure:     '.js-disclosure--roster',
    rosterPanel:          '.js-roster-panel',
    rosterUser:           '.js-roster-user',
    roster:               '.js-roster',
    conversationPanel:    '.js-conversation-panel',
    conversationScroller: '.js-conversation-scroller',
    chatAvailability:     '.js-chat-availability',
    chatAvailabilityLabel:'.js-chat-availability-label',
    panelContainer:       '.js-panel-container',
    conversation:         '.js-conversation',
    chatWidget:           '.js-chat-widget',
    chatWidgetWrapper:    '.js-chat-widget-wrapper',
    chatOptionsTab:       '.js-chat-options-tab',
    openChatButton:       '.js-open-chat-btn',
    chatTab:              '.js-chat-tab',
    closeChatButton:      '.js-close-chat-btn',
    chatButtonIcon:       '.js-chat-button-icon',
    backToRosterButton:   '.js-back-to-roster-btn',
    closeMobileChatButton:'.js-close-mobile-chat-button',
    newChatMessage:       '.js-new-message',
    sendButton:           '.js-send-btn',
    sendForm:             '.js-chat-form',
    mediaBox:             '.js-media-box',

    endCallButton:        '.js-end-call',
    allStartCallBtns:     '.js-start-btn',
    cancelCallButton:     '.js-cancel-call',
    acceptInvitationBtn:  '.js-accept-invitation',
    declineInvitationBtn: '.js-decline-invitation',
    shareVideoOnAccept:   '.js-share-video-on-accept',

    // Recording Controls
    recordBtn:            '.js-rec-btn',
    reviewBtn:            '.js-review-btn',
    redoRecordBtn:        '.js-redo-rec-btn',
    recordingTimer:       '.js-rec-timer',
    avCheckLink:          '.js-open-av-check',

    submitPChatActivity:  '.js-submit-chat',
    toggleAudioButton:    '.js-toggle-audio',
    toggleVideoButton:    '.js-toggle-video',
    invitationChatWrapper:'.js-chat-invitation-wrapper',
    mediaTestWrapper:     '.js-media-test-wrapper',
    mediaChatWrapper:     '.js-media-chat-wrapper',
    mediaChatAction:      '.js-media-chat-action',
    mediaChatStep:        '.js-media-chat-step',
    mediaRecordingStep:   '.js-media-recording-step',
    chatVideoContainer:   '.js-chat-video-container',
    loadMoreMsgItem:      '.js-load-more-item',
    loadMoreMsgLink:      '.js-load-more-link',
    notRecordingText:     '.js-not-recording-text',
    chatVideoObject:      '#video-media-chat',
    chatMyVideo:          '#my-video',
    chatPartnerVideo:     '#partner-video',
    chatPlaybackVideo:    '#playback-video',
    submittedBox:         '.js-submitted-box',
    referenceA:           '.js-info-gap-label-A',
    referenceB:           '.js-info-gap-label-B',
    referenceContainer:   '.js-info-gap-references',

    // State classnames:
    isOpen:               'is-open',
    isHidden:             'u-hidden',
    hasConversation:      'has-conversation',
    chatWidgetHasConversation: 'chat-widget-has-conversation',
    hasMessages:          'has-messages',
    liveChatDisabled:     'chat-disabled',
    highlightedReference: 'is-highlighted',

    // Variant classnames:
    chatWidgetPchat:      'c-chat-widget--pchat',
    chatWidgetGroupChat:  'c-chat-widget--group-chat',

    // UI text:
    feedbackMessages: {
      calling:      'You sent an invite for Video Chat.',
      testing:      '{{ name }} accepted your invitation.',
      connecting:   'You are ready for Video Chat.',
      chatting:     'You are connected to Video Chat.'
    },

    props: {
      // A limitation in Google Chrome requires a Flash video
      // be larger than 400 x 300:
      flashWidth: 401,
      flashHeight: 301
    }
  };

  ui.chatInnerUI = `${ui.panelContainer}, ${ui.chatVideoContainer}`;


  /* ==== 3. Widget ======================================= */

  function openChatWidget() {
    var textElements = document.querySelectorAll('.js-new-message');

    [...textElements].forEach((textElement) => {
      if (self.accentBar) self.accentBar.register(textElement);
    });

    // Open chat widget even if live chat is disabled and set its state.
    if (!$(ui.chatWidget).hasClass(ui.isOpen)) {
      // Slide the chat widget into view:
      $(ui.chatWidget).addClass(ui.isOpen);
      $(ui.openChatButton).addClass(ui.isOpen);
      localStorage.setItem('chatDrawerOpen', "true");
    }

    // Show the panel container:
    $(ui.panelContainer).removeClass(ui.isHidden);
    document.querySelector(ui.chatWidget)?.classList.remove('hide-live-chat-pane');

    // If live chat is enabled, only then show the users in roster panel.
    if(self.config.showRosterPanelBody) {
      // Show roster panel body containing users list.
      $(ui.roster).removeClass(ui.isHidden);
      // Unhide contents from assistive tech:
      $(ui.chatInnerUI).attr('aria-hidden', false);
    }

    // focus on close button when chat widget opens
    $(ui.closeChatButton).focus();
    rosterNavigation();
  }

  function closeChatWidget() {
    let getAccentBar = document.querySelector('.js-accent-bar-modal');
    // Add accent bar validation for prgorams that doesn't have accent bar.
    if (!getAccentBar || $(".js-accent-bar-modal").is(":hidden")) {
      // If chat widget is open, then close chat widget and set its state.
      if ( $(ui.chatWidget).hasClass(ui.isOpen)) {
        // Close the chat widget:
        $(ui.chatWidget).removeClass(ui.isOpen);
        $(ui.openChatButton).removeClass(ui.isOpen);
        localStorage.setItem('chatDrawerOpen', "false");
      }

      // Hide the panel container:
      // to avoid invisible tabbing from roster to chat screen
      $(ui.panelContainer).addClass(ui.isHidden);
      document.querySelector(ui.chatWidget)?.classList.add('hide-live-chat-pane');

      if (self.config.showRosterPanelBody) {
        // Hide roster panel body containing users list.
        $(ui.roster).addClass(ui.isHidden);
        // Hide contents from assistive tech:
        $(ui.chatInnerUI).attr('aria-hidden', true);
      }
      if (self.accentBar) self.accentBar.deactivateAll();
    }
  }


  /* ==== 4. Conversations ================================ */


  function setCurrentConversation(otherUserId, sectionId) {
    self.currentConversation.otherUserId = otherUserId;
    self.currentConversation.sectionId = sectionId;
  }

  /**
   * This returns user ids of other users for
   * a group chat conversation using session data.
   * @param {Object.<string, object>} sessionData - session data
   * @return {Array<string>}
   */
  function getOtherUserIdsFromSession(sessionData) {
    const otherUserIds = [...sessionData.invited.uuid];
    otherUserIds.push(sessionData.inviting.uuid);
    otherUserIds.splice(otherUserIds.indexOf(self.controller.myUuid), 1);
    return otherUserIds;
  }

  function clearCurrentConversation() {
    setCurrentConversation(null, null);
  }

  function getCurrentConversationId() {
    let conversation_id = null;
    if (self.currentConversation.sectionId !== null) {
      // TODO: leave only is_group_chat ?
      if (Array.isArray(self.currentConversation.otherUserId) || self.is_group_chat) {
        conversation_id = new GroupChatView().group_chat_channel_id();
      } else {
        conversation_id = self.currentConversation.sectionId + '-' + self.currentConversation.otherUserId;
      }
    }
    return conversation_id;
  }

  function getConversationPanel(conversationId) {
    return $(ui.conversationPanel + '-' + conversationId);
  }

  /**
   * Add newly added conversations and their messages to the DOM.
   * @param {Array} convos - Collection of conversation objects.
   */
  function addNewConversations(convos) {
    let conversationsTemplate = '';
    let messagesTemplate = '';

    if (convos.length <= 0) {
      return;
    }

    convos.forEach((convo) => {
      const shouldAddConvoElm = getConversationPanel(convo.conversationId).length < 1;
      if (shouldAddConvoElm) {
        if (convo.isGroupChat) {
          conversationsTemplate += VHL.Templater.get(convo, self.getGroupChatTemplate());
        } else {
          conversationsTemplate += VHL.Templater.get(convo, self.conversationTemplate);
        }
      }

      // If conversation elm is not added then avoid adding message html alone otherwise
      // it would get appended as sibling to other conversation elms.
      if (!convo.isGroupChat || shouldAddConvoElm) {
        conversationsTemplate += convo.messages.reduce((memo, message) => {
          // Since we are adding a new conversation, we don't need to scroll to the latest message.
          addUnread(message, convo.conversationId);

          return memo + VHL.Templater.get(message, self.messageTemplate);
        }, '');
      }
    });

    /**
     * @since 2021-10-07
     * TODO: Change this condition to something
     * that uses a config variable to decide whether to attach, rather
     * than the presence of the ui element.
     */
    const uiPanel = document.querySelector(ui.panelContainer);

    if (uiPanel) {
      if(self.is_group_chat) {
        convos.forEach(convo => {
          const shouldAddConvoElm = getConversationPanel(convo.conversationId).length < 1;

          if(shouldAddConvoElm) {
            uiPanel.innerHTML += conversationsTemplate + messagesTemplate;
          }
        });
      } else {
        uiPanel.innerHTML += conversationsTemplate + messagesTemplate;
      }
    }
  }

  function scrollToEnd($scroller) {
    let $messageList = $scroller.find(ui.conversation);
    $scroller.scrollTop($messageList.outerHeight());
  }

  function scrolledToEnd($scroller, $messageList) {
    // This function tells us if the user is scrolled at or near to the bottom of the messages
    const closeEnough = 100;
    return $scroller.scrollTop() > ($messageList.outerHeight() - $scroller.outerHeight() - closeEnough);
  }

  function activateConversation(id) {
    var $widget = $(ui.chatWidget);
    var $panel = getConversationPanel(id);
    var $scroller = $panel.find(ui.conversationScroller);
    const mobileTabbedViewElm = document.querySelector('.js-mobile-tabs-view');

    // Hide all conversations:
    $(ui.conversationPanel).addClass(ui.isHidden);
    // Show the current one:
    $panel.removeClass(ui.isHidden);
    // Slide the conversation panel into view:
    $widget.addClass(ui.hasConversation);
    mobileTabbedViewElm?.classList.add(ui.chatWidgetHasConversation);

    // Hide roster panel.
    $(ui.rosterPanel).addClass(ui.isHidden);
    // Tab navigation other than partner chat and group chat activity page.
    if (
      !self.config.inviteMetadata.isPartnerChat &&
      !self.config.inviteMetadata.isGroupChat
    ) {
      circularNavigation(
        $(ui.backToRosterButton),
        $(ui.sendButton)
      );
    }
    // Wait for slide to end:
    $widget.on('transitionend', function() {
      // Scroll down to make sure most recent messages are visible:
      scrollToEnd($scroller);
      // Put focus on the new message field:
      if (self.config.autoScroll) {
        $panel.find(ui.newChatMessage).focus();
      }
      $widget.off('transitionend');
    });
    // Show appropriate 'start chat' button:
    $(self.config.startCallButton).removeClass(ui.isHidden);

    self.controller.setLastOpenedTime(id);
    localStorage.setItem('chatCurrentConversation', id);
  }


  /* ==== 5. Messages =================================== */
  /*
   * Mark chat and conversation with "has new messages"
   */
  function populateUnreadMessages() {
   // Update the roster and open chat button with unread conversation indicators:
    _.each(self.unreadConversations, function(count, key) {
      var $conversationButton = $('.js-conv-' + key);
      $conversationButton.toggleClass(ui.hasMessages, true);
    });
    $(ui.openChatButton).toggleClass(ui.hasMessages, false).removeAttr("aria-label");

   //Update each conversation with unread messages indicators:
    if (self.unreadConversations.length > 0){
      if (!$(ui.openChatButton).hasClass(ui.hasMessages)) {
        $(ui.openChatButton).addClass(ui.hasMessages).attr("aria-label","New Messages");
        $(ui.chatButtonIcon).attr('name', 'chat-unread-message');
      }
     self.unreadConversations.forEach((conversation) => {
        $('.js-conv-' + conversation).toggleClass(ui.hasMessages, true);
      });
    }
  }

  function isUnread(message, conversationId) {
    var lastOpenedTime = self.controller.getLastOpenedTime(conversationId);
    return message.time > (lastOpenedTime || 0);
  }

  /*
   * Save unread messages in sessionStorage
   */
  function addUnread(message, conversationId) {
    if (!message.fromMe && isUnread(message, conversationId)) {
      self.unreadConversations.push(conversationId);
      sessionStorage.setItem('conversationList', self.unreadConversations.join(','));
    }
  }

  /*
   *Delete read messages and update session storage only with no read messages
   *
   */
  function clearUnread(conversationId) {
    if(sessionStorage.getItem('conversationList')) {
      self.unreadConversations = self.unreadConversations.filter(id => id != conversationId);
      sessionStorage.setItem('conversationList', self.unreadConversations.join(','));
    $('.js-conv-' + conversationId).toggleClass(ui.hasMessages, false);
    }
    populateUnreadMessages();
  }

  /**
   * Add one or more collections of new messages to the DOM.
   * @param {Array} updatedConvos - Collection of conversation objects with new messages.
   * This is called by render.
   */
  function addNewMessages(updatedConvos) {
    // Loop over each conversation that has new messages
    _.each(updatedConvos, function(convo) {
      var $panel = getConversationPanel(convo.conversationId);
      var $messageList = $panel.find(ui.conversation);
      var $scroller = $panel.find(ui.conversationScroller);
      var atBottom = scrolledToEnd($scroller, $messageList);
      var template = '';
      var lastMsgFromMe = null;
      let lastMsg = null;
      let lastMsgAnnouncement = null;
      let messages = convo.messages;
      let $msgAnnouncement = $panel.find('.js-last-msg-announcement');
      _.each(messages, function(msg) {
        const msgForTempl = {...msg, ...{ isGroupChat: convo.isGroupChat }}
        template += VHL.Templater.get(msgForTempl, self.messageTemplate);

        addUnread(msg, convo.conversationId);
        lastMsgFromMe = msg.fromMe;
        lastMsg = msg;
      });

      if (template != '') {
        $messageList.html(template);
        // If the last of the messages was mine, scroll to the bottom
        // otherwise, only scroll to the bottom if the user is already
        // scrolled near the bottom of the messages.
        if (lastMsgFromMe || atBottom) {
          scrollToEnd($scroller);
        }
        if (lastMsgFromMe) {
          lastMsgAnnouncement = `You said: ${lastMsg.body}`;
        }
        else {
          lastMsgAnnouncement = `${lastMsg.fromFirst} ${lastMsg.fromLast} says: ${lastMsg.body}`;
        }
        $msgAnnouncement.html(lastMsgAnnouncement);
      }
      //Check for only incoming message.
      if(messages[messages.length-1].messageFrom != 'You said' &&
        isUnread(messages[messages.length-1], convo.conversationId)) {
        audio.play()?.then(_ => { }).catch(error => {
          //If play() is blocked by browser.
          console.log("Autoplay was prevented");
        });
      }

    });
  }

  /* ==== 6. Invitations ================================= */

  function showInvitation(fromName, fromUserId, fromSectionId, message, options) {
    // Insert invitation content:
    $(ui.invitationChatWrapper).html(
      VHL.Templater.get({ name: fromName,
                          msg: message,
                          fromUserId: fromUserId,
                          fromSectionId: fromSectionId },
                        self.invitationTemplate)
    );
    // Display the invitation:
    $(ui.invitationChatWrapper).removeClass(ui.isHidden)
      .removeClass('is-dismissed')
      .addClass('is-revealed');

    callAudio = new Audio('/call_selected.mp3');

    callAudio.addEventListener('ended', function() {
          this.currentTime = 0;
          this.play();
    }, false);

      callAudio.play()?.then(_ => {
        //If play() is not blocked by the browser.
        console.log("Playing incoming call sound...");
      }).catch(error => {
        //If play() is blocked by browser.
        console.log("Autoplay was prevented");
      });

    $(ui.acceptInvitationBtn).focus();
    // Default Navigation behaviour
    circularNavigation(
      $(ui.shareVideoOnAccept),
      $(ui.declineInvitationBtn)
    );
  }

  function dismissInvitation() {
    $(ui.invitationChatWrapper).addClass('is-dismissed')
      .addClass(ui.isHidden)
      .removeClass('is-revealed');
    if (callAudio) {
      callAudio.pause();
    }
    callAudio = null;
  }


  /* ==== 7. Video ======================================= */

  /**
   * Make sure the conversation is visible, and show the video.
   * @param  {[type]} mode           - 'chat' or 'test', determines DOM location
   * @param  {[type]} conversationId - ID of the conv panel to show
   */
  function startMediaChat(mode, conversationId) {
    document.querySelector(ui.avCheckLink)?.focus();
    var $panel = getConversationPanel(conversationId);
    activateConversation(conversationId);
    showVideo($panel, mode);
  }

  /**
   * Move the video object into the conversation panel.
   * @param  {jQuery} $panel - The current conversation panel.
   * @param  {string} mode - 'chat' or 'test'
   */
  function showVideo($panel, mode) {
    var destination = (mode === 'chat') ? ui.mediaChatWrapper : ui.mediaTestWrapper;
    console.log('panel to move video to ', $panel);
    $(ui.chatVideoObject).appendTo($panel.find(destination));
    $(ui.chatVideoObject).removeClass(ui.isHidden);

    //if is a partner chat video call add the event to alert users if it tries to leave the page
    if(self.config.usePartnerChatActivityStyle) {
      window.addEventListener('beforeunload', self.alertOnPchatLeave);
    }
  }

  /**
   * Put the video object away in a hidden element to be re-used later.
   */
  function putAwayVideo() {
    $(ui.chatVideoObject).appendTo(ui.chatVideoContainer);
    $(ui.chatVideoObject).addClass(ui.isHidden);
    if (self.config.canRecord) { cleanupRecordingUI(); }
  }

  /**
   * Hide any infogap references that were revealed when the call connected.
   */
  function unassignInfoGapReferences() {
    let $bothReferences = $(self.references['a'].selector + ',' +
                            self.references['b'].selector);
    if (self.userIsInstructor) {
      $bothReferences.removeClass(ui.highlightedReference);
    } else{
      $bothReferences.addClass('u-hidden');
    }
  }

  /**
   * Reset data attribute 'available' in 5 partner video containers
   * for next group chat call session.
   */
  function resetVideoContainerAvailability() {
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      for (let i = 1; i <= 5; ++i) {
        let partnerVideoContainer = document.querySelector(`#partner-video-${i}`);
        if (partnerVideoContainer.dataset.available !== 'true') {
          partnerVideoContainer.dataset.available = true;
        }
      }
    }
  }

  /**
   * Cleanup the UI after hanging up from a call:
   *  Hide the video element
   *  Hide any InfoGap references
   *  Reset partner video container availability data attribute for group chat
   *  Go to roster view in case of group chat
   */
  function hangupRenderCallback() {
    putAwayVideo();
    unassignInfoGapReferences();
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      resetVideoContainerAvailability();
      backToRoster();
    }
  }

  /**
   * Cleanup the UI after call invite is canceled (eg rejected/ revoked)
   */
  function cancelInviteRenderCallback() {
    putAwayVideo();
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      backToRoster();
    }
  }

  /**
   * Cleanup the UI after call invite is canceled due to timeout
   */
  function inviteTimeoutRenderCallback() {
    dismissInvitation();
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      backToRoster();
    }
  }

  /**
   * Disable or enable the call button
   */
  function setStartCallButtonDisabledState(disable) {
    $(ui.allStartCallBtns).prop('disabled', disable);
  };

  function hidePlaybackVideoContainer() {
    $(ui.chatPlaybackVideo).removeClass('c-chat-video-element');
  }

  function showPlaybackVideoContainer() {
    $(ui.chatPlaybackVideo).addClass('c-chat-video-element');
  }

  /* ==== 8. Misc. UI ==================================== */

  // Helper functions to make repetitive DOM code more readable:


  /**
   * This function returns mobile tabs view object in case of a group
   * chat or partner chat activity.
   * @returns { VHL.MobileTabsViewGroupchat | VHL.MobileTabsViewPchat }
   */
  function getMobileTabsView() {
    if (VHL.MobileTabsViewGroupchat) {
      return VHL.MobileTabsViewGroupchat;
    } else if(VHL.MobileTabsViewPchat) {
      return VHL.MobileTabsViewPchat;
    }
  }

  function setState(states, elements) {
    // TODO: Replace these with calls to $.setState.
    // If elements is a single object, put it in an array:
    elements = (Array.isArray(elements)) ? elements : [elements];
    elements.forEach((query) => {
      // Avoid jQuery elements altogether, so we don't have implicit jQuery.each calls made.
      element = document.querySelectorAll(query.selector);
      element.forEach((el) => {
        if (states.indexOf('show') >= 0) { $(el).removeClass('u-hidden'); }
        if (states.indexOf('hide') >= 0) { $(el).addClass('u-hidden'); }
        if (states.indexOf('enable') >= 0) { $(el).prop('disabled', false); }
        if (states.indexOf('disable') >= 0) { $(el).prop('disabled', true); }
      });
    });
  }

  function backToRoster() {
    const mobileTabbedViewElm = document.querySelector('.js-mobile-tabs-view');

    $(ui.chatWidget).removeClass(ui.hasConversation);
    mobileTabbedViewElm?.classList.remove(ui.chatWidgetHasConversation);

    const conversationId = getCurrentConversationId();
    // Clear unread count when going back to roster:
    clearUnread(conversationId);
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      self.controller.removeGroupConversation(conversationId);
      const convoSelector = `.js-conversation-panel-${conversationId}`;
      document.querySelectorAll(convoSelector).forEach(convoElm => convoElm.remove());
    }
    clearCurrentConversation();
    // Hide conversation panel and show roster panel with focus on first roster user.
    $(ui.conversationPanel).addClass(ui.isHidden);
    $(ui.rosterPanel).removeClass(ui.isHidden);
    $(`${ui.roster} ${ui.rosterUser}`).first().focus();
    if (self.is_group_chat) {
      var group_chat_view = new GroupChatView();
      group_chat_view.init_invite_checkboxes();
      group_chat_view.init_invite_button();
    }
  }

  /**
   * Make UI adjustments depending on chat configuration:
   */
  function customizeUI() {
    // Chat tab: Since this code won't run if no chat functionality
    // is enabled in a course, just show the tab if its not a pchat activity:
    $(ui.chatTab).toggleClass(ui.isHidden, self.config.usePartnerChatActivityStyle);
    // show only availability toggle button when:
    // 1) live chat is disabled and pchat is enabled.
    // 2) It is not a pchat activity.
    let showToggleOnly = (!self.config.showRosterPanelBody && !self.config.usePartnerChatActivityStyle);
    $(ui.chatWidget).toggleClass(ui.liveChatDisabled, showToggleOnly);
    // If its a pchat activity, show the roster panel.
    if(self.config.usePartnerChatActivityStyle) {
      $(ui.roster).removeClass(ui.isHidden);
      // Unhide contents from assistive tech:
      $(ui.chatInnerUI).attr('aria-hidden', false);
    }

    // Move chat widget to the correct location:
    $(ui.chatWidgetWrapper).detach().appendTo(self.config.chatContainer);

    // Mark it as the pchat or group chat variant for styling purposes:
    const chatWidgetVariant =
      self.config.inviteMetadata.isGroupChat ?
      ui.chatWidgetGroupChat :
      ui.chatWidgetPchat;
    $(ui.chatWidget).toggleClass(chatWidgetVariant, self.config.usePartnerChatActivityStyle);

    // Show/hide Playback video element:
    $(ui.chatPlaybackVideo).toggleClass(ui.isHidden, !self.config.hasVideoPlayback);

    window.addEventListener('storage', (evt) => {
      // If the key is not related to the chat drawer, then ignore event.
      const allowedKeys = ['chatDrawerOpen', 'chatCurrentConversation',
                           'chatInvitation', 'logout', 'toggleAvailability'];

      if (!allowedKeys.includes(evt.key)) {
        return;
      }

      if (evt.key === 'logout' && evt.newValue === 'true') {
        setTimeout(() => window.location.reload(), 2000);
        return;
      }

      if (evt.key === 'chatInvitation') {
        dismissInvitation();
        // It is necessary to clear this value when dimissing invites.
        self.controller.set_pChatAdapter(null);
      }

      if (evt.key === 'chatDrawerOpen' && evt.newValue === 'true') {
        // Because there's nothing to update after we open the chat, it is safe to return.
        openChatWidget();
        return;
      } else if(evt.key === 'chatDrawerOpen' && evt.newValue == 'false') {
        // Because there's nothing to update after we close the chat, it is safe to return.
        closeChatWidget();
        return;
      }

      if (evt.key === 'chatCurrentConversation') {
        var isUndefined = (evt.newValue === 'undefined' || evt.newValue === 'null' ||
          evt.newValue == null || evt.newValue === '-undefined');
        var isEmpty = isUndefined || evt.newValue.length === 0 || evt.newValue === '';

        if (isUndefined || isEmpty) {
          backToRoster();

        } else if(!self.is_group_chat) {
          // currentConversation is formatted as "section_[sectionId]-[userId]"
          const currentConversation = evt.newValue;
          const sectionId = currentConversation.split("-")[0]
          const userId = currentConversation.split("-")[1]
          setCurrentConversation(userId, sectionId);
          // grab history for the user that is currently selected.
          self.controller.retrieveMessageHistoryFor(userId, sectionId);
          activateConversation(getCurrentConversationId());
        }
      }

      if (evt.key === 'toggleAvailability') {
        self.updateAvailabilityUI(evt.newValue === 'true');
      }
    });

    // set initial values for local storage key events, so it can trigger events.
    localStorage.setItem('chatDrawerOpen', 'false');
    localStorage.setItem('chatCurrentConversation', null);
    localStorage.setItem('chatInvitation', null);
    localStorage.setItem('logout', false);
    localStorage.setItem('toggleAvailability', true);
  }

  /**
   * Enable/Disable internal chat navigation.
   * @param {boolean} newState true = enable nav, false = disable nav.
   */
  function enableNavigation(newState) {
    $(ui.backToRosterButton).prop('disabled', !newState);
    $(ui.closeChatButton).prop('disabled', !newState);
  }

  function updateVideoButton(newState) {
    const toggleVideoBtn = document.querySelector(ui.toggleVideoButton);
    if (!toggleVideoBtn) return;

    toggleVideoBtn.classList.toggle('is-off', !newState);
    toggleVideoBtn.setAttribute('aria-pressed', !newState);
  }

  function updateAudioButton(newState) {
    const toggleAudioBtn = document.querySelector(ui.toggleAudioButton);
    if (!toggleAudioBtn) return;

    toggleAudioBtn.classList.toggle('is-off', !newState);
    toggleAudioBtn.setAttribute('aria-pressed', !newState);
  }

  function enableAudioAndVideoButtons(newState) {
    $(ui.toggleAudioButton).prop('disabled', !newState);
    $(ui.toggleVideoButton).prop('disabled', !newState);
  }

  /**
   * Closes the chat window on body click outside the panel or open button.
   *
   * @param {MouseEvent} evt - Mouseup event.
   */
  function handleBodyMouseUp(evt) {
    // If click is inside the panelContainer, do nothing
    if ($(ui.panelContainer).is(evt.target) || $(ui.panelContainer).has(evt.target).length > 0) {
      return;
    }
    // If click is on the openChatButton or its descendants, do nothing
    if ($(ui.openChatButton).is(evt.target) || $(ui.openChatButton).has(evt.target).length > 0) {
      return;
    }
    // Otherwise, close the chat window if open
    if ($(ui.chatWidget).hasClass(ui.isOpen)) {
      exitChatWindow();
      evt.stopPropagation();
    }
  }

  /**
   * Get the full name of the remote chat partner.
   *
   */
  function otherUserName() {
    var $panel = getConversationPanel(getCurrentConversationId());
    return $panel.find('.js-chat-other-username').text().trim();
  }

  function registerDisclosure() {
    // Register only those disclosures which are in the roster panel and not outside.
    $(`${ui.rosterDisclosure}`).each(function(idx, disclosure) {
      const jsDisclosure = new VHL.Music.V1.Disclosure($(disclosure));
    });
  }

  function exitChatWindow() {
    closeChatWidget();
    // If on a conversation, mark it as read when clicking "Hide".
    if (getCurrentConversationId()) {
      clearUnread(getCurrentConversationId());
    }
  }

  /**
   * This function changes mobile view to mobile's first/landing view for activity
   */
  function exitMobileChatWindow() {
    const mobileTabsView = getMobileTabsView();

    // Set pchat mobile view to first/landing page
    // which has Mobile Tabs View component's tabset hidden and shows reference content.
    if (mobileTabsView) {
      mobileTabsView.setState("TABSET_HIDDEN");
      mobileTabsView.setActiveTab("REFERENCE");
    }

    $(".js-mobile-tabs-view").addClass("c-mobile-chat-activity-landing-page");
    if (VHL.ActivityShell
      && typeof VHL.ActivityShell.setActivityHeight == "function") {
      VHL.ActivityShell.setActivityHeight();
    }
  }

  // Tab navigation should be trapped in Live-Chat.
  function circularNavigation($firstSelector, $lastSelector) {
    $firstSelector.keydown(function (evt) {
      if (evt.keyCode === 9 && evt.shiftKey) {
        $lastSelector.focus();
        evt.preventDefault();
      }
    });

    $lastSelector.keydown(function (evt) {
      if (evt.keyCode === 9 && !evt.shiftKey) {
        $firstSelector.focus();
        evt.preventDefault();
      }
    });
  }

  function rosterNavigation() {
    // Default first and last elements for navigation
    var $firstChatElement = $(ui.rosterPanel).find(ui.closeChatButton);

    /**
     * If roster panel is hidden in case of live-chat disabled & pchat enabled.
     * Chat availability toggle will be the last element.
     *  */
    var $lastChatElement = (self.config.showRosterPanelBody)
                            ? $(`${ui.roster} ${ui.rosterUser}`).last()
                            : $(ui.chatAvailability);

    // On click of last disclosure in roster.
    $(ui.rosterDisclosure).last().click(function (evt){
      var $rosterHeaderButton = $(evt.target);

      // Unbind the events registered previously.
      $firstChatElement.off('keydown');
      $lastChatElement.off('keydown');

      // If last disclosure is expanded, the last user of disclosure is the last element.
      // else, header of last disclosure is the last element.
      if ($rosterHeaderButton.attr('aria-expanded') === 'true') {
        $lastChatElement = $(`${ui.roster} ${ui.rosterUser}`).last();
      } else {
        $lastChatElement = $rosterHeaderButton;
      }

      // Set circular navigation behaviour on toggling disclosure.
      circularNavigation($firstChatElement, $lastChatElement);
    });

    // Default Navigation behaviour
    circularNavigation($firstChatElement, $lastChatElement);
  }


  /* ==== 9. Rendering =================================== */

  /**
   * Show the correct media chat UI state depending on which
   * step of the process we are on:
   *
   *   'initial': Show avatar & 'start call' button
   *   'calling': Invite has been sent; waiting for invitee to reply
   *   'testing': Making sure A/V devices are functioning.
   *   'connecting': Waiting for the stream to start.
   *   'chatting': a media chat is active & ongoing.
   *
   * @param {String} step  Name of the current step
   */
  function showMediaStep(step) {
    /* If the user has not yet clicked on a roster member,
     * there is no current conversation, and the UI should not be reset.
     */
    if (getCurrentConversationId()) {
      if (self.is_group_chat) {
        const bDisableChat = step !== 'chatting';
        self.disableTextGroupChatUI(bDisableChat);
      }
      var $panel = getConversationPanel(getCurrentConversationId());
      $(ui.mediaChatStep).addClass(ui.isHidden);
      $panel.find('.js-media-chat-' + step).removeClass(ui.isHidden);
      self.currentConversation.mediaStep = step;
      $(ui.mediaRecordingStep, $panel).addClass(ui.isHidden);

      // Show recording UI if enabled:

      if (step === 'chatting' && self.config.canRecord) {
        showRecordingStep('initial');
      }

      // If users are making a call or a/v chatting, don't show the a/v test link
      if (step === 'chatting' || step === 'calling') {
        setState('hide', $panel.find(ui.avCheckLink));
      } else {
        setState('show', $panel.find(ui.avCheckLink));
      }
    }
  }

  function setupRecordingUI() {
    var $panel = getConversationPanel(getCurrentConversationId());
    const template = $('.js-chat-activity-recording-controls-template').html();
    $panel.find('.js-record-box').html(template);
    self.setupMediaButtons();
    self.recordingUIIsActive = true;
  }

  function cleanupRecordingUI() {
    $('.js-record-box').html();
    self.recordingUIIsActive = false;
  }

  function showRecordingStep(step) {
    if (!self.recordingUIIsActive) {
      setupRecordingUI();
    }
    var $panel = getConversationPanel(getCurrentConversationId());
    $(ui.mediaRecordingStep, $panel).removeClass(ui.isHidden);
    var $timer = $panel.find(ui.recordingTimer);
    var $submittedBox = $panel.find(ui.submittedBox);
    let $portfolioBtn = $('.js-export-portfolio-btn');
    let portfolioPreferenceElm = document.querySelector('.js-auto-export-portfolio');
    var $noRecordText = $panel.find(ui.notRecordingText);

    switch (step) {
      case 'initial':
        setState('hide', [$timer]);
        if(self.recordingUIIsActive) {
          self.reviewBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
          self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
          self.recordBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
        }
        break;

      case 'recording':
        setState('show', [$timer, $noRecordText]);

        if(self.recordingUIIsActive) {
          self.recordBtn.state = VHL.Music.V1.MediaButton.states.ACTIVE;
        }
        break;

      case 'done-rec':
        setState('hide', [$timer, $noRecordText]);
        if(self.recordingUIIsActive) {
          self.recordBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
          self.reviewBtn.state = VHL.Music.V1.MediaButton.states.LOADING;
        }
        break;

      case 'video-available':
        if(self.recordingUIIsActive) {
          self.reviewBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
          self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
        }
        break;

      case 'playing':
        self.reviewBtn.state = VHL.Music.V1.MediaButton.states.ACTIVE;
        enableAudioAndVideoButtons(false);
        self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
        break;

      case 'done-play':
        self.reviewBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
        enableAudioAndVideoButtons(true);
        self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
        break;

      case 'submitted':
        let isExportDone = portfolioPreferenceElm?.value === 'true';
        $portfolioBtn.attr('disabled', isExportDone);
        setState('show', [$submittedBox, $portfolioBtn]);
        self.reviewBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
        self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
        //After submit, if is a partner chat video call, remove the event to
        //alert users if it tries to leave the page
        if(self.config.usePartnerChatActivityStyle) {
          window.removeEventListener('beforeunload', self.alertOnPchatLeave);
        }
        break;

    }

    self.currentConversation.recordingStep = step;
  }

  /**
   * Post an informational msg to the chat log (e.g., 'You ended the call.')
   * @param  {string} message - Text of message to be posted.
   */
  function postFeedbackMessage(message, $conversation) {
    var sysMessage = '<li class="c-system-message">' + message + '</li>';
    $conversation.append(sysMessage);
  }


  /**
   * Re-draw the roster and add new conversations and
   * messages. Set the state of the media chat UI and post
   * feedback messages to the chat log.
   *
   * @param  {object} options - various items forwarded from update().
   *                    .data - presence & conversation data
   *                    .feedback - system message to post
   *                    .mediaStep - switch UI steps in the chat process.
   *                    .preRenderAction - callback before rendering.
   *                    .postRenderAction - callback after rendering.
   */
  function render(options) {
    var newData;
    var $panel;
    var $scroller;
    var $conversation;
    var newConvos;
    var newMessages;

    if (options.preRenderAction) { options.preRenderAction(); }

    if (options.data) {
      newData = options.data;
      // Reflect roster changes in the DOM:
      $(ui.roster).html(VHL.Templater.get(newData, self.rosterTemplate));

      // Get convo/message diffs between new & previous data:
      newConvos = VHL.Chat.Differ.getNewConversations(newData, dataCache);
      newMessages = VHL.Chat.Differ.getNewMessages(newData, dataCache);
      // Update the DOM with new convos & messages:
      addNewConversations(newConvos);
      addNewMessages(newMessages);

      // Register the disclosures in roster panel.
      registerDisclosure();
    }

    if (options.mediaStep) {
      showMediaStep(options.mediaStep);
      enableNavigation(options.mediaStep === 'initial');
    }

    if (options.feedback) {
      $panel = getConversationPanel(getCurrentConversationId());
      $scroller = $panel.find(ui.conversationScroller);
      $conversation = $panel.find(ui.conversation);
      postFeedbackMessage(options.feedback, $conversation);
      scrollToEnd($scroller);
    }

    if (options.postRenderAction) { options.postRenderAction(); }

      populateUnreadMessages();
  }

  /* ==== 10. User Events ================================= */

  /**
   * attachEventHandlers - set up actions in response to user-triggered UI events.
   * What goes here:
   *     * Calls to public chat controller
   *     * Calls to update() when rendering is required.
   *     * Simple state changes like opening chat widget.
   */
  function attachEventHandlers() {
    const mobileTabsView = getMobileTabsView();

    /*
      Note on event delegation:

      Most events here are delegated via an ancestor element, to enable
      automatic attaching/detaching of events as the elements are added/removed
      from the DOM.
     */
    $(ui.chatWidget)
      // Click 'Hide' button:
      .on('click', ui.closeChatButton, function(evt) {
        exitChatWindow();
      })
      // Click 'Hide' button on mobile view:
      .on('click', ui.closeMobileChatButton, (evt) => {
        exitMobileChatWindow();
      })

      // Click on a user in the roster:
      .on('click', ui.rosterUser, function(evt) {
        evt.stopImmediatePropagation();
        if (!self.is_group_chat) {
          var $btn = $(this);
          var userId = String($btn.data('otheruserid'));
          var sectionId = String($btn.data('sectionid'));

          setCurrentConversation(userId, sectionId);
          // grab history when click on user name
          self.controller.retrieveMessageHistoryFor(userId, sectionId);
          activateConversation(getCurrentConversationId());
        }
      })

      /* Conversation header events */
      // Back button:
      .on('click', ui.backToRosterButton, (evt) => {
        backToRoster();
        localStorage.removeItem('chatCurrentConversation');

        // Set pchat mobile view to roster pane
        // which has Mobile Tabs View component's tabset hidden and shows primary content.
        if (mobileTabsView) {
          mobileTabsView.setState("TABSET_HIDDEN");
          mobileTabsView.setActiveTab("PRIMARY");
        }
      })

      // Exit chat window on clicking ESC key.
      .on('keyup', function(evt) {
        if ( evt.keyCode === VHL.UI.Keys.ESC ) {
          exitChatWindow();
        }
      })

      /**
       * On click of start call button, initiate a call.
       * For the group chat, call will be initiated from roster view instead:
       */
      .on('click', self.startCallButton, function(evt) {
        if (!VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
          const $panel = getConversationPanel(getCurrentConversationId());
          const recipientSectionId = $panel.find(ui.sendForm).data('section-id');
          self.controller.startCall(self.currentConversation.otherUserId,
                                    recipientSectionId,
                                    self.config.courseId);
          self.update({ event: 'i-invite', invitee: $(this).data('username') });
        }
      })
      /**
       * Cancel call (revoke invitation):
       */
      .on('click', ui.cancelCallButton, (evt) => {
        self.controller.revokeCall();
        self.update({ event: 'i-revoke' });

        // Set pchat mobile view to roster pane or conversation pane view
        // which has Mobile Tabs View component's tabset hidden and shows primary content.
        if (mobileTabsView) {
          mobileTabsView.setState("TABSET_HIDDEN");
          mobileTabsView.setActiveTab("PRIMARY");
        }
      })

    /* Call controls events */
      // End call (hangup):
      .on('click', ui.endCallButton, function(evt) {
        self.controller.endCall();
        /* If the user hangs up after the activity has been submitted,
         * Don't reset the UI. The page is in the process of reloading
         * to show the submitted view.
         */
        if(!self.controller.get_activitySubmitted()) {
          self.update({ event: 'i-hangup' });
        }
      })
      /**
       * Toggle video:
       */
      .on('click', ui.toggleVideoButton, function(evt) {
        self.setVideoSharing(!self.videoOn);
      })
      /**
       * Toggle audio:
       */
      .on('click', ui.toggleAudioButton, function(evt) {
        self.audioOn = !self.audioOn;
        self.controller.enableAudio(self.audioOn);
        updateAudioButton(self.audioOn);
      })

    /**
     * Chat Availability switch
     *
     * The listener is on the label b/c the actual checkbox is hidden.
     */
      .on('change', ui.chatAvailability, function(evt) {
        let newState = $(evt.currentTarget).prop('checked');
        let oldState = !newState;

        self.controller.setAvailability(
          newState,
          function success() {
            // Commit the state:
            self.available = newState;
            self.updateAvailabilityUI(newState);
            localStorage.setItem('toggleAvailability', newState);
          },
          function failure() {
            console.log("Updating availability failed");
            // If the transaction failed, revert the UI change:
            self.available = oldState;
            self.updateAvailabilityUI(oldState);
          }
        );
        // User sets the state to 'unavailable'. Show message
        // that user needs to change the available status
        // in order to send messages:
        if (!newState) {
          // Only show this alert message once per page load.
          // This is a workaround for https://vistahl.atlassian.net/browse/MAE-42618
          if(!this.once) {
            this.once = true;
            alert("You have turned off your chat availability. Your status needs to be 'available' to send messages.");
          }
        }
      })

      // Submit new message:
      .on('submit', ui.sendForm, function(evt) {
        var $form = $(this);
        var $messageField = $form.find(ui.newChatMessage);
        evt.preventDefault();

        // Only allow messages that are not 100% whitespace:
        if (String($messageField.val()).trim() !== '') {
          const cbSuccess = () => {
            console.log('Message send succeeded!');
            $messageField.val('');
          }
          const cbFailure = () => {
            console.log('Message send failed!');
          }
          if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
            self.controller.sendGroupMessage(
              self.currentConversation.otherUserId,
              self.currentConversation.sectionId,
              $messageField.val(),
              cbSuccess,
              cbFailure
            );
          } else {
            self.controller.sendMessage(
              self.currentConversation.otherUserId,
              self.currentConversation.sectionId,
              $messageField.val(),
              cbSuccess,
              cbFailure
            );
          }
        }
      })

      .on('click', ui.loadMoreMsgLink, function(evt) {
        evt.preventDefault();
        self.controller.retrieveMessageHistoryFor(self.currentConversation.otherUserId,
                                                         self.currentConversation.sectionId);
      })

    // If the user logs out of m3, explicitly log them out of chat.
    $('.js-logout-link').click(function() {
      localStorage.setItem('logout', true);
      VHL.Msg.ClientWrapper.cleanup();
      localStorage.clear();
      closeChatWidget();
    });

    /* Invitation Events */
    $(ui.invitationChatWrapper)
      .on('click', '.js-accept-invitation', function() {
        localStorage.setItem('chatInvitation', 'accepted'); // Notify other tabs.
        // Get value of enable-video checkbox and assign it to config.
        self.config.enableVideo = document.querySelector('.js-share-video-on-accept').checked;

        // If we are not accepting in a new tab, this is
        // a Live Chat. Update the current Tab.
         self.controller.beginPartnerChatSession(VHL.Msg.pChatEventHandler(self.controller, self.is_group_chat));
        if (!self.controller.get_acceptOnNewTab()) {
          openChatWidget();
          var pchatEventHandler = VHL.Msg.pChatEventHandler(self.controller, self.is_group_chat);
          if (self.is_group_chat) {
            self.initConversationsForGroupChat();
            self.controller.renderView({
              event: 'i-accept',
              conversationId: getCurrentConversationId(),
            })
          } else {
            var $invite = $(this).parent('.js-invitation');
            setCurrentConversation(
              String($invite.data('from-user')),
              String($invite.data('from-section'))
            );
            self.update({
              event: 'i-accept',
              conversationId: getCurrentConversationId(),
            });
          }
        } else {
          // We are opening a new tab to join the chat (pchat).
          // Dismiss invitation on current tab.
          self.update({
            event: 'i-accept-pchat'
          });
        }
        self.controller.acceptInvitation();
      })

      .on('click', '.js-decline-invitation', function() {
        localStorage.setItem('chatInvitation', 'rejected'); // Notify other tabs.
        const sessionData = self.controller.get_pChatAdapter().getSessionData();
        const isGroupChat = sessionData.invite_metadata.isGroupChat;
        const inviteType = isGroupChat ? VHL.Msg.Types.GROUP_CHAT_INVITE : VHL.Msg.Types.PARTNER_CHAT_INVITE;

        self.controller.declineInvitation(inviteType);
        self.update({ event: 'i-reject' });
      });

    /* Bind on to the standard submit button and when it's clicked,
       reset the UI: */
    $(ui.submitPChatActivity).on('click', function (evt) {
      showRecordingStep('initial');
    })

    $(ui.chatTab)
      // Click 'open' button:
      .on('click', ui.openChatButton, function(evt) {
        if ($(ui.chatWidget).hasClass(ui.isOpen)) {
          closeChatWidget();
        } else {
          openChatWidget();
        }
        evt.stopPropagation();
      });

    if (!['group_chat', 'partner_chat'].includes(VHL.Chat.CONFIG.activityType)) {
      $('body').on('mouseup', handleBodyMouseUp);
    }

    /**
     * Live chat widget is position fixed after masthead navbar.
     * On window scroll, when masthead scrolled out of view,
     * set the top of chat widget to 0 to fill up the hollow space.
     */
    $(window).scroll(() => {
      let scrollTop = $(window).scrollTop();
      let mastHeadHeight = $('.js-navbar--account').height();

      // Half of masthead height is considered for smooth transition.
      let chatWidgetTopZero = (scrollTop >= (mastHeadHeight / 2))
      $('.js-chat-widget').toggleClass('c-chat-widget--top-0', chatWidgetTopZero);
    });

    self.avCheck.attachEventHandlers();
  }

  /* ===================================================== *
       Prototype Functions (Public)

  /* ==== 11. Update the View (Public API) =============== */

  /**
   * Respond to all events that require UI rendering. User actions
   * that don't require the render function do their stuff in the event handlers.
   *
   * @param  {object} options - data needed per event:
   * @param  {string} options.event - Event type.
   * @param  {object} options.data - Roster & conversation details to be rendered (optional).
   * @param  {string} options.fromUuid - User ID (optional)
   * @param  {string} options.inviterName - User name  (optional)
   *
   * Note: those last two are event-specific.
   */
  View.prototype.update = function(options) {
    var renderOptions = {};
    if (options.event) {
      // Events that don't need special handling here (render() takes care of them):
      // * new-message

      switch (options.event) {
      case 'i-invite':
        renderOptions.mediaStep = 'calling';
        if (self.is_group_chat) {
          let group_chat_view = new GroupChatView();
          renderOptions.feedback = 'You started a call with ' + group_chat_view.selected_usernames.join(',') + '.';
        } else {
          renderOptions.feedback = 'You started a call to ' + options.invitee + '.';
        }
        break;

      case 'they-invite':
        let forActivityMsg = '';
        let activityTitle = '';
        if (options.isGroupChat) {
          activityTitle = options.activityTitle ;
          forActivityMsg = ' for " ' +  activityTitle + '". A group-chat activity';
        } else if(options.isPartnerChat) {
          activityTitle = options.activityTitle ;
          forActivityMsg = ' for " ' +  activityTitle + '". A partner-chat activity';
        }

        renderOptions.postRenderAction = showInvitation.bind(
          null,
          options.inviterName,
          options.inviterUserId,
          options.inviterSectionId,
          `is calling you ${forActivityMsg}.\nWant to answer?`,
          options
        );
        break;

      case 'i-accept':
        renderOptions.mediaStep = 'chatting';
        renderOptions.feedback = 'Your call has started.';
        renderOptions.preRenderAction = dismissInvitation;
        renderOptions.postRenderAction = startMediaChat.bind(
          null, 'chat', options.conversationId
        );
        break;

      case 'i-accept-pchat':
        renderOptions.preRenderAction = dismissInvitation;
        break;

      // This event is fired when joining pchat on a newly opened tab.
      case 'i-join-pchat':
        renderOptions.mediaStep = 'chatting';
        renderOptions.feedback = 'Your partner chat has started.';
        var currentConversationId = getCurrentConversationId();
        renderOptions.postRenderAction = startMediaChat.bind(
          null, 'chat', currentConversationId
        );
        break;

      case 'they-accept':
        renderOptions.mediaStep = 'chatting';
        //TODO options.invitedName is undfined.
        //renderOptions.feedback = options.invitedName + ' has accepted your call.';
        renderOptions.postRenderAction = startMediaChat.bind(
          null, 'chat', options.conversationId
        );
        break;

      case 'they-accept-pchat':
        renderOptions.mediaStep = 'chatting';
        //TODO options.invitedName is undfined.
        //renderOptions.feedback = options.invitedName + ' has accepted your partner chat invitation.';
        renderOptions.postRenderAction = startMediaChat.bind(
          null, 'chat', options.conversationId
        );
        break;

        case 'i-reject':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'You declined the call.';
        renderOptions.preRenderAction = dismissInvitation;
        break;

      case 'they-reject':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'The call was declined.';
        renderOptions.postRenderAction = cancelInviteRenderCallback;
        break;

      case 'i-reject-livechat':
        localStorage.setItem('chatInvitation', 'rejected');
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'Live chat invitation rejected. Not available in partner chat activities';
        renderOptions.postRenderAction = putAwayVideo;
        break;

      case 'i-revoke':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'You cancelled the call.';
        renderOptions.postRenderAction = cancelInviteRenderCallback;
        break;

      case 'they-revoke':
        renderOptions.feedback = 'The sender has cancelled the invitation.';
        renderOptions.postRenderAction = dismissInvitation;
        break;

      case 'invite-timeout':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'The invitation timed out.';
        renderOptions.postRenderAction = inviteTimeoutRenderCallback;
        break;

      case 'paired':
        renderOptions.mediaStep = 'chatting';
        renderOptions.feedback = 'Your call has started.';
        renderOptions.postRenderAction = startMediaChat.bind(
          null, 'chat', options.conversationId);
        break;

      case 'audio-level':
        if (self.currentConversation.recordingStep === 'recording') {
          self.audioLevel = options.level * 128;
        }
        break;

      case 'i-hangup':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = 'You have ended the call.';
        renderOptions.postRenderAction = hangupRenderCallback;
        break;

      case 'they-hangup':
        renderOptions.mediaStep = 'initial';
        renderOptions.feedback = otherUserName() + ' has ended the call.';
        renderOptions.postRenderAction = hangupRenderCallback;
        break;

      case 'they-busy':
        renderOptions.postRenderAction = setStartCallButtonDisabledState(true);
        break;

      case 'they-available':
        renderOptions.postRenderAction = setStartCallButtonDisabledState(false);
        break;

      case 'they-unavailable':
        renderOptions.postRenderAction = setStartCallButtonDisabledState(true);
        break;

      case 'i-available':
        self.updateAvailabilityUI(true);
        break;

      case 'i-unavailable':
        self.updateAvailabilityUI(false);
        break;

      case 'they-leave':
        renderOptions.postRenderAction = setStartCallButtonDisabledState(true);
        break;

      case 'someone-leaves':
        let groupChatViewInstance = new GroupChatView();
        groupChatViewInstance.removePartnerFromGroupNames(options.fromUuid);
        let whoLeft = groupChatViewInstance.getPartnerNameById(options.fromUuid);
        renderOptions.feedback = `${whoLeft} has left the call.`;
        break;

      case 'they-join':
        renderOptions.postRenderAction = setStartCallButtonDisabledState(false);
        break;

      case 'they-start-rec':
        renderOptions.feedback = 'Your partner has started recording.';
        showRecordingStep('recording');
        break;

      case 'they-stop-rec':
        renderOptions.feedback = 'Your partner has stopped recording.';
        showRecordingStep('done-rec');
        break;

      case 'video-combine-complete':
        showRecordingStep('video-available');
        break;

      case 'i-play-recording':
        showPlaybackVideoContainer();
        showRecordingStep('playing');
        break;

      case 'they-play-recording':
        showPlaybackVideoContainer();
        showRecordingStep('playing');
        break;

      case 'i-stop-playback':
        showRecordingStep('done-play');
        break;

      case 'they-stop-playback':
        showRecordingStep('done-play');
        break;

      case 'playback-complete':
        showRecordingStep('done-play');
        break;

      case 'they-redo':
        showRecordingStep('initial');
        break;

      case 'submitted':
        showRecordingStep('submitted');
        break;

      }
    } // end if (options.event)

    if (options.data) {
      renderOptions.data = options.data;
    }

    // Update the UI:
    render(renderOptions);

    self.handleEventsForMobileTabsView(options.event);
    self.handleEventsForTimeoutDialog(options.event);

    // Cache the current data for diffing:
    if (options.data) {
      dataCache = options.data;
    }

    var textElements = document.querySelectorAll('.js-new-message');

    [...textElements].forEach((textElement) => {
        if (self.accentBar) self.accentBar.register(textElement);
    });
  };

  /**
   * This method calculates other user ids in a group chat session and then creates
   * a group chat conversation model and adds it to conversations list.
   */
  View.prototype.initConversationsForGroupChat = function() {
    const sessionData = self.controller.get_pChatAdapter().getSessionData();
    const invitedUuid = sessionData.invited.uuid;
    const sectionId = sessionData.invited.section_id;
    const otherUserIds = getOtherUserIdsFromSession(sessionData);
    const groupChatView = new GroupChatView();
    groupChatView.selected_student_ids = Array.isArray(invitedUuid) ? invitedUuid : [invitedUuid];
    const channelId = groupChatView.group_chat_channel_id();
    self.controller.initConversationDataForGroupChat(otherUserIds, sectionId, channelId);
    self.setCurrentConversationGroupChat(
      groupChatView.selected_student_ids,
      channelId
    );
  }

  /**
   * Respond to all events that trigger UI changes in mobile view.
   * @param  {string} chatEvent - Event type.
   */
  View.prototype.handleEventsForMobileTabsView = function(chatEvent) {
    const mobileTabsView = getMobileTabsView();

    switch (chatEvent) {
      case 'i-accept':
      case 'i-accept-pchat':
      case 'they-accept':
      case 'they-accept-pchat':

        // Set pchat chat mobile view to call connected screen
        // which has Mobile Tabs View component's tabset visible and shows primary content.
        if (mobileTabsView) {
          mobileTabsView.setState("TABSET_VISIBLE");
          mobileTabsView.setActiveTab("PRIMARY");
        }

        //removing class as here may come directly from start page.
        $(".js-mobile-tabs-view").removeClass("c-mobile-chat-activity-landing-page");
        $(".js-mobile-tabs-view").addClass("c-chat-call-ongoing");
        break;
      case 'i-hangup':
      case 'they-hangup':

        // Set pchat mobile view to roster pane or conversation pane view
        // which has Mobile Tabs View component's tabset hidden and shows primary content.
        if (mobileTabsView) {
          mobileTabsView.setState("TABSET_HIDDEN");
          mobileTabsView.setActiveTab("PRIMARY");
        }

        // Hide footer only if activity is submitted
        if (self.controller.get_activitySubmitted()) {
          $(".js-mobile-tabs-view").removeClass("c-mobile-chat-activity-show-footer");
        }

        $(".js-mobile-tabs-view").removeClass("c-chat-call-ongoing");
        break;
      case 'video-combine-complete':
        /* If the "practice" flag has been set in the DOM,
         *   then submit buttons do not get enabled.
         */
        if ($('#practice').val() != 'yes') {
          $(".js-mobile-tabs-view").addClass("c-mobile-chat-activity-show-footer");
        }
        break;
      case 'submitted':
        $(".js-mobile-tabs-view").removeClass("c-mobile-chat-activity-show-footer");
        break;
      case 'i-join-pchat':

        // Set pchat mobile view which has Mobile Tabs View component's tabset visible and shows primary content.
        if (mobileTabsView) {
          mobileTabsView.setState("TABSET_VISIBLE");
          mobileTabsView.setActiveTab("PRIMARY");
        }

        // To override if landing page state already initialized, eg. when launched in new window
        $(".js-mobile-tabs-view").removeClass("c-mobile-chat-activity-landing-page");
        $(".js-mobile-tabs-view").addClass("c-chat-call-ongoing");
        break;
      default:
        break;
    }
  };

  /**
   * Respond to all events that trigger user state change concerning idle timeout dialog.
   * Var callInvitationSide contains value 'invited' or 'inviting'
   * when user is connected to a chat call.
   * @param  {string} chatEvent - Event type.
   */
   View.prototype.handleEventsForTimeoutDialog = function(chatEvent) {
    switch (chatEvent) {
      case 'i-invite':
      case 'i-accept':
      case 'i-accept-pchat':
      case 'they-accept':
      case 'they-accept-pchat':
      case 'i-join-pchat':
        const sessionData = self.controller.get_pChatAdapter().getSessionData();
        const side = sessionData.inviting.uuid === self.controller.myUuid ? VHL.Chat.GlobalState.INVITING : VHL.Chat.GlobalState.INVITED;
        VHL.Chat.GlobalState.callInvitationSide = side;
        break;
      case 'i-hangup':
      case 'they-hangup':
        VHL.Chat.GlobalState.callInvitationSide = '';
        break;
      default:
        break;
    }
  };

   /**
   * Set some UI state depending on my current availability setting.
   */
  View.prototype.updateAvailabilityUI = function(newState) {
    // Set disabled of 'start call' btn
    $(self.startCallButton).prop('disabled', !newState);
    // Set disabled of new message field and send button:
    $(ui.newChatMessage).prop('disabled', !newState);
    $(ui.sendButton).prop('disabled', !newState);
    $(ui.chatAvailability).attr('checked', newState);
    // For styling purpose of chat availability status.
    $(ui.openChatButton).toggleClass('available', newState).attr("aria-label", newState ? "Available" : "Unavailable");
    const hasUnreadMessages = self.unreadConversations.length > 0;
    let iconName;
    if (hasUnreadMessages) {
      iconName = newState ? 'chat-unread-message' : 'chat-unavailable-unread-message';
    } else {
      iconName = newState ? 'chat-available' : 'chat-unavailable';
    }
    $(ui.chatButtonIcon).attr('name', iconName);
  };

  View.prototype.getCurrentConversationId = function() {
    return getCurrentConversationId();
  };

  View.prototype.getGroupChatTemplate = function() {
    return document.getElementById(ui.groupChatConversationTemplateId).innerHTML;
  };

  View.prototype.setVideoSharing = function(newState) {
    self.videoOn = newState;
    self.controller.enableVideo(newState);
    updateVideoButton(newState);
  };

  /* Show the given info-gap reference. Expected values are
   *   'a' for the first reference and 'b' for the second.
   */
  View.prototype.assignInfoGapReference = function(label) {
    if (self.userIsInstructor) {
      self.references[label].addClass(ui.highlightedReference);
    } else {
      self.references[label].removeClass(ui.isHidden);
    }
  };

  /**
   * Disable the submit button.
   */
  View.prototype.disableSubmit = function() {
    const submitBtn = document.querySelector('.js-activity-submit');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.classList.add('is-disabled');
    }
  }

  /**
   * This method enables the submit button on chat activities for non-practice usecase.
   */
  View.prototype.enableSubmit = function() {
    const practiceField = document.querySelector('#practice');
    if (practiceField?.value === 'yes') return;

    const submitBtn = document.querySelector('.js-activity-submit');
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.classList.remove('is-disabled');
    }
  }

  View.prototype.setupMediaButtons = function() {
    let $panel = getConversationPanel(getCurrentConversationId());

    // Initialize Record media button
    this.recordBtn = this.setupRecordMediaButton($panel);
    this.recordBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;

    // Initialize Review media button
    this.reviewBtn = this.setupReviewMediaButton($panel);
    this.reviewBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;

    // Initialize Redo media button
    this.redoRecordBtn = this.setupRedoMediaButton($panel);
    this.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DISABLED;
  }

  View.prototype.setupRecordMediaButton = function($panel) {
    const volumeCallback = () => {
      return self.audioLevel;
    };

    let $recordBtn = $panel.find(ui.recordBtn);
    return new VHL.Music.V1.MediaButton({
      $button: $recordBtn,
      activate: this._recordButtonPlayHandler.bind(this),
      deactivate: this._recordButtonStopHandler.bind(this),
      volume: volumeCallback,
    });
  };

  View.prototype.setupReviewMediaButton = function($panel) {
    let $reviewBtn = $panel.find(ui.reviewBtn);
    return new VHL.Music.V1.MediaButton({
      $button: $reviewBtn,
      activate: this._reviewButtonPlayHandler.bind(this),
      deactivate: this._reviewButtonStopHandler.bind(this),
    });
  };

  View.prototype.setupRedoMediaButton = function($panel) {
    let $redoRecordBtn = $panel.find(ui.redoRecordBtn);
    return new VHL.Music.V1.MediaButton({
      $button: $redoRecordBtn,
      activate: this._redoButtonPlayHandler.bind(this),
    });
  };

  View.prototype._recordButtonPlayHandler = (newState) => {
    self.controller.startRecording();
    showRecordingStep('recording');
  };

  View.prototype._recordButtonStopHandler = (newState) => {
    self.controller.stopRecording();
    showRecordingStep('done-rec');
  };

  View.prototype._reviewButtonPlayHandler = (newState) => {
    self.disableSubmit();
    self.controller.syncPlayback();
    showRecordingStep('playing');
  };

  View.prototype._reviewButtonStopHandler = (newState) => {
    self.controller.syncStopPlayback();
    self.enableSubmit();
  };

  View.prototype._redoButtonPlayHandler = (newState) => {
    const msg = `If you record again, your previous recording will be discarded. Do you want to continue?`;
    const confirmResult = window.confirm(msg)
    if (confirmResult) {
      self.disableSubmit();
      showRecordingStep('initial');
      self.controller.redoRecordSync();
    } else {
      self.redoRecordBtn.state = VHL.Music.V1.MediaButton.states.DEFAULT;
    }
  };

  View.prototype.setCurrentConversationGroupChat = (userId, sectionId) => {
    setCurrentConversation(userId, sectionId);
  };

  View.prototype.activateConversationGroupChat = (selected_student_data, conversation_template, conversation_id) => {
    const mobileTabbedViewElm = document.querySelector('.js-mobile-tabs-view');
    var $widget = $(ui.chatWidget);
    var $panel = getConversationPanel(conversation_id);
    if($panel.length === 0) {
      let parsed_template = VHL.Templater.get(selected_student_data, conversation_template);
      let uiPanel = document.querySelector(ui.panelContainer);
      if(uiPanel) {
        uiPanel.innerHTML += parsed_template;
      }
      $panel = getConversationPanel(conversation_id);
    }
    var $scroller = $panel.find(ui.conversationScroller);

    // Hide all conversations:
    $(ui.conversationPanel).addClass(ui.isHidden);
    // Show the current one:
    $panel.removeClass(ui.isHidden);
    // Slide the conversation panel into view:
    $widget.addClass(ui.hasConversation);
    mobileTabbedViewElm?.classList.add(ui.chatWidgetHasConversation);

    // Hide roster panel.
    $(ui.rosterPanel).addClass(ui.isHidden);
    // Wait for slide to end:
    $widget.on('transitionend', function() {
      // Scroll down to make sure most recent messages are visible:
      scrollToEnd($scroller);
      $widget.off('transitionend');
    });
    // Show appropriate 'start chat' button:
    $(self.config.startCallButton).removeClass(ui.isHidden);

    self.controller.setLastOpenedTime(conversation_id);
    localStorage.setItem('chatCurrentConversation', conversation_id);
  }

  /**
   * This method disables text chat by hiding
   * the chat input textbox and send button. This is used to disable
   * text chat feature unless all users are connected via call.
   * @param {boolean} bDisableChat - Whether to disable the chat.
   */
  View.prototype.disableTextGroupChatUI = function(bDisableChat) {
    const $panel = getConversationPanel(getCurrentConversationId());
    const panelElm = $panel[0];
    const inputFormElm = panelElm.querySelector(`${ui.sendForm}`);
    if (bDisableChat) {
      inputFormElm.classList.add(ui.isHidden);
    } else {
      inputFormElm.classList.remove(ui.isHidden);
    }
  };

  // Return the Constructor:
  return View;
})();
