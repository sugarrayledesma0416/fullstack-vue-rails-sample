// Handlebar helper registration is in a doc ready to make that this happens after all
// libraries are loaded, including multiple versions of Handlebars loaded via gems.
$(document).ready(function() {
  Handlebars.registerHelper('totalUnread', function(new_message_count) {
    return new_message_count + ' unread';
  });

  Handlebars.registerHelper('courseAndSectionName', function(courseName, sectionName) {
    return courseName + ': ' + sectionName;
  });

  Handlebars.registerHelper('isCurrentUser', function(fromMe) {
    return (fromMe) ? 'is-current-user' : '';
  });

  Handlebars.registerHelper('callButtonDisableState', function(state) {
    return (state === 'available') ? '' : 'disabled';
  });

  Handlebars.registerHelper('ifChatActivityShowCurrentProgramOnly', function(programId) {
    if(VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType)) {
      return programId == VHL.Chat.CONFIG.currentProgram;
    } else {
      return true;
    }
  });

  Handlebars.registerHelper('showCourseInRoster', function(chat_level) {
    /*
     * possible values for chat level are:
     * "partner_chat", "partner_chat_and_live_chat","disabled"
     */
    if(chat_level === 'disabled') {
      return false; //If chat is disabled, don't show this a pchat or live chat roster.
    } else if((VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType)) ||
              (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType))) {
      return chat_level != 'disabled'; //If chat is not disabled, show this course in pchat roster
    } else {
      // Only show this course in live chat roster if live chat is explicitly enabled.
      return chat_level === 'partner_chat_and_live_chat';
    }
  });

  Handlebars.registerHelper('chatLevelToolTipMsg', function() {
    /* These tooltips should be used when `showCourseInRoster == false` in _roster.html.erb */

    /* "This course does not have Live Chat enabled" will show up when all of the following are true:
     * 1) The user is a student
     * 2) The student is enrolled in a course that has live chat enabled
     * 3) The student is enrolled in a course that has partner chat only enabled
     */
    if (VHL.Chat.CONFIG.instructorUser == false) {
      return "This course does not have Live Chat enabled";
    }
    /* For instructors, show a tooltip that is context sensitive of live chat vs partner chat */
    if (VHL.Chat.isPartnerChatActivity(VHL.Chat.CONFIG.activityType)) {
      return "This course does not have Partner Chat enabled. You may edit the Course Content Settings to change this.";
    } else {
      return "This course does not have Live Chat enabled. You may edit the Course Content Settings to change this.";
    };
  });

});
