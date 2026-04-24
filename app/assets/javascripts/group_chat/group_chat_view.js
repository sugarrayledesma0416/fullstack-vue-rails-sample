var VHL = VHL || {};
VHL.GroupChatViewInstance = null;

class GroupChatView {

  constructor() {
    if (!VHL.GroupChatViewInstance) {
      this.group_minimum = parseInt(VHL.Common.metaTagContent('VHL.group_chat_group_minimum'));
      this.group_maximum = parseInt(VHL.Common.metaTagContent('VHL.group_chat_group_maximum'));
      this.selected_student_ids = []; 
      this.selected_section_id = null;
      this._chat_view = null;
      this.pubnubClient = null;
      VHL.GroupChatViewInstance = this;

      const activityContainer = $('.js-group-chat-activity-container');
      activityContainer.removeClass('js-pchat-activity-container');
      this.video_container = $('.js-group-chat-widget-wrapper').detach();
      const testConnectionElm = document.querySelector('.js-open-av-check-on-roster');
      testConnectionElm.classList.remove('u-hidden');
    }
    return VHL.GroupChatViewInstance;
  }

  set chat_view(view) {
    this._chat_view = view;
    this._chat_view.is_group_chat = true;
    // This should be moved to a better place but I need to check where
    this.pubnubClient = this._pubnubClient();
  }
  
  get chat_view() {
    return this._chat_view;
  }

  get chat_controller() {
    let chat_ctrl = null;
    if(this.chat_view) {
      chat_ctrl = this.chat_view.controller;
    }
    return chat_ctrl;
  }

  init_invite_checkboxes() {
    this._selected_students_checkboxes().forEach( item => {
      item.checked = false;
      item.addEventListener('click', event => {
        this._check_students_selected();
      });
    });
  }

  init_invite_button() {
    this.refreshInviteButtonElm();
    this.invite_button = document.querySelector('.js-group-chat-invite-btn');
    this.invite_button.disabled = (this._selected_students_checkboxes(':checked').length === 0);
    this.invite_button.addEventListener('click', (event) => {
      this.selected_section_id = null;
      this.selected_usernames = [];
      this.selected_student_ids = [...this._selected_students_checkboxes(':checked')].map( item => {
        // Use the section_id of the first selected user.
        if(!this.selected_section_id) {
          this.selected_section_id = item.dataset.sectionId;
        }
        this.selected_usernames.push(document.getElementById(item.getAttribute('aria-labelledby')).innerText);
        return item.dataset.userId;
      });
      let channel_id = this.group_chat_channel_id();
      const otherUserIds = [...this.selected_student_ids];
      this.chat_controller.initConversationDataForGroupChat(otherUserIds, this.selected_section_id, channel_id);
      this.chat_view.setCurrentConversationGroupChat(this.selected_student_ids, channel_id);
      const conversationData = {
        conversationId: channel_id,
        messages: [],
        userNames: this.getGroupUserNames(),
        sectionId: this.selected_section_id
      };
      this.chat_view.activateConversationGroupChat(conversationData, this.chat_view.getGroupChatTemplate(), channel_id);
      this.chat_view.updateAvailabilityUI(this.chat_view.available);

      const cAdapter = this.chat_controller.get_cAdapter();
      cAdapter.authorizePubnubChannel(channel_id);

      this._send_invitees_info(channel_id, this.selected_section_id, this.selected_student_ids);
    })
  }
  
  /**
   * This method returns display names for all the other users in a group chat
   * for the current conversation. 
   * @return {string} - User names
   */
  getGroupUserNames() {
    const convoViewData = this.getConvoData();
    return convoViewData.userNames;
  }

  getConvoData() {
    const conversationId = this.chat_view.getCurrentConversationId();
    const convo = this.chat_controller.findGroupConversationById(conversationId);
    const convoData = convo.getViewData();
    return convoData
  }

  getPartnerNameById(userId) {
    let convoData = this.getConvoData();
    let users = convoData.user
    let user = users.find(obj => {
      return obj.uuid === userId
    });
    return user.firstName + ' ' + user.lastName
  }

  removePartnerFromGroupNames(id) {
    const re = /\b( and )\b/
    const formatter = new Intl.ListFormat('en', { style: 'long', type: 'conjunction'  });
    const partnerName = this.getPartnerNameById(id);
    const namesNodeList = document.querySelectorAll('.c-conversation__other-username');
    const otherUsersHeader = namesNodeList[namesNodeList.length-1]
    let otherUsersString = otherUsersHeader.innerText.trim().replace(re,",");
    let otherUsersList = otherUsersString.split(",")
      .map(function(element){
        element.trim();
        return element
      })
      .filter(function(element){
        return element != partnerName 
      });
    otherUsersHeader.innerText = formatter.format(otherUsersList);
  }

  refreshInviteButtonElm() {
    const inviteBtn = document.querySelector('.js-group-chat-invite-btn');
    const inviteBtnClone = inviteBtn.cloneNode(true);
    inviteBtn.parentNode.replaceChild(inviteBtnClone, inviteBtn);
  }

  group_chat_channel_id() {
    let pubnub_channel_id = null;
    if(this.selected_student_ids.length > 0) {
      pubnub_channel_id = window.Packs['activities/group_chat'].JSum.digest(this.sorted_student_ids(), 'SHA256', 'hex') + '_group_chat';
    }
    return pubnub_channel_id;
  }

  sorted_student_ids() {
    return this.selected_student_ids.sort();
  }

  enable_available_students() {
    this._selected_students_checkboxes(':not(:checked):not(:disabled)')
  }

  _selected_students_checkboxes(additional_selector = '') {
    let query_string = '.js-student-select-checkbox';
    if (additional_selector.length > 0) {
      query_string += additional_selector;
    }
    return document.querySelectorAll(query_string);
  }

  _check_students_selected() {
    let selected_students = this._selected_students_checkboxes(':checked').length;
    if (selected_students >= this.group_minimum) {
      this.invite_button.disabled = false;
      if (selected_students === this.group_maximum) {
        //disable the students that are available, when the max selected students have been reached.
        this._selected_students_checkboxes(':not(:checked):not(:disabled)').forEach( item => {
          item.disabled = true;
        });
      } else {
        document.querySelectorAll('group-chat-label-student.c-roster__username--available').forEach( item => {
          let label_target = item.current_label_target();
          if (label_target.disabled) {
            label_target.disabled = false;
          }
        });
      }
    } else {
      this.invite_button.disabled = true;
    }
  }

  _pubnubClient() {
      const cAdapter = this.chat_controller.get_cAdapter();
      return cAdapter.getPubNubClient();
  }

  _send_invitees_info(channelId, sectionId, selectedUsers) {
      this.pubnubClient.publish({
        message: {
          groupChatAuth: true,
          groupChatChannel: channelId,
          selectedUsers,
        },
        channel: sectionId,
      }).then(response => {
        console.log('group chat publish result: ', response);
        this.chat_view.controller.startGroupCall(
          selectedUsers,
          sectionId,
          this.chat_view.config.courseId
        );
        const { first_name, last_name } = VHL.Chat.CONFIG.session.user;
        const inviteeName = first_name + last_name;
        this.chat_view.update({ event: 'i-invite', invitee: inviteeName });
      });
  }

  _subscribe_user(user_id) {
      $.post('/pubnub_user_info', {user_id: 26}, function(data) {
          console.log(data);
          const pubnubConfig = {};

          pubnubConfig.publishKey = data.pubnub.publish_key;
          pubnubConfig.subscribeKey = data.pubnub.subscribe_key;
          pubnubConfig.authKey = data.auth_token;
          pubnubConfig.uuid = `${data.user.uuid}:237201`;
          pubnubConfig.restore = false;
          console.log('pubnubConfig:', pubnubConfig);

          const inviteePubnubClient = new PubNub(pubnubConfig);
          inviteePubnubClient.subscribe({ channels: [group_chat_channel_name[0]] });
          console.log('inviteeClient:', inviteePubnubClient);
      }, 'json');

      $.post('/pubnub_user_info', {user_id: 27}, function(data) {
          console.log(data);
          const pubnubConfig = {};

          pubnubConfig.publishKey = data.pubnub.publish_key;
          pubnubConfig.subscribeKey = data.pubnub.subscribe_key;
          pubnubConfig.authKey = data.auth_token;
          pubnubConfig.uuid = `${data.user.uuid}:231448`;
          pubnubConfig.restore = false;
          console.log('pubnubConfig invitee 2:', pubnubConfig);

          const inviteePubnubClient = new PubNub(pubnubConfig);
          inviteePubnubClient.subscribe({ channels: [group_chat_channel_name[0]] });
          console.log('inviteeClient invitee 2:', inviteePubnubClient);
      }, 'json');
  }
}
