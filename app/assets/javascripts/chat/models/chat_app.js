/** ChatApp - Describes the state of the chat application.
 * @constructor
 * @param {Object} roster_structure - The roster structure from VHL.Chat.session object.
 * @param {String} myUuid - current user's uuid.
 * @property {Array} conversations - An array of Conversation objects.
 */
VHL.Chat.ChatApp = (function() {
  function ChatApp(roster_structure, myUuid){
    this.roster = roster_structure;
    this.myUuid = myUuid;
    this.conversations = [];
  };

  /** ChatApp private functions */

   /**
    * makeCourses - returns an array of Course objects
    * @param {roster_structure} - The roster structure from VHL.Chat.session object.
    */
  function makeCourses(roster_structure) {
    return _.map(roster_structure, function(course) {
      return new VHL.Chat.Course(course.name, course.id, course.sections);
    });
  };

  /**
   * filterCoursesByUserType - set the list of courses depending on the user type
   * @param {courses} - The course list the user is associed with
   */
  function filterCoursesByUserType(courses) {
    let filtered_courses = [];

    if (VHL.Chat.CONFIG.instructorUser) {
      /**
       * For the instructor user we don't have an specific course to check
       * so we will get all the course related to the instructor filtered
       * by the current program.
       */
      filtered_courses = courses.filter((course) => {
        return course.program_id === VHL.Chat.CONFIG.currentProgram;
      });
    } else {
      filtered_courses = courses.filter((course) => {
        return course.id === `course_${VHL.Chat.CONFIG.courseId}`;
      });
    }

    return filtered_courses;
  }

  /** ChatApp prototype functions */
  ChatApp.prototype.userAdd = function(user) {
    this.users.push(user);
  };

  ChatApp.prototype.findConversation = function(uuid, sectionId) {
    return _.find(this.conversations, function(convo) {
      return uuid === convo.user.uuid && convo.user.sectionId === sectionId;
    });
  };

  /**
   * This returns a group chat conversation by conversation id
   * @param {string} conversationId - Group chat conversation id
   * @return {VHL.Chat.Conversation} - conversation instance
   */
  ChatApp.prototype.findGroupConversationById = function(conversationId) {
    return _.find(this.conversations, function(convo) {
      return convo.isGroupChat && conversationId === convo.id;
    });
  };

  /**
   * This returns user objects for a given userIds list.
   * Users data is picked from non-group conversation array
   * which had been filled by roster data.
   * @param {Array<string>} userIds - UserIds list
   * @param {string} sectionId
   * @return {Array<VHL.Chat.User>}
   */
  ChatApp.prototype.getConversationUsersByIds = function(userIds, sectionId) {
    const filteredConvs = this.conversations.filter(
      (conv) => {
        return !conv.isGroupChat &&
        userIds.includes(conv.user.uuid) &&
        conv.user.sectionId === sectionId
      }) ?? [];
    return filteredConvs.map(conv => conv.user)
  };

  /** removeConversation
   *  @param {String} uuid, The uuid of the Conversations's User to be removed.
   *  @param {String} sectionId, The sectionId of the Conversation's User to be removed.
   */

  ChatApp.prototype.removeConversation = function(uuid, sectionId) {
    var convo = this.findConversation.call(this, uuid, sectionId);
    this.conversations = _.without(this.conversations, convo);
  };

  /** addMessage - Adds a new message to the model.
   * Message is added in conversation model. Group chat conversations are found by
   * conversation id and other conversations are found by section id and user id.
   * Messages from other users and from me are rendered on a callback
   * from incoming Pubnub events. If the message is from me, it is added to
   * the conversation for the toUuid. If the message is from another user,
   * it is added to the conversation for the from Uuid.
   *
   * We also need to know if we need to prepend or push a message to a conversation.
   * A message is prepended, if and only if, is a message retrieved from the chat history.
   * @param {string} groupId - An identifier for unique group / sections.
   * @param {Object.<string, object>} message
   * @param {Boolean} is_history_message - Boolean to know if the message has been retrieved from
   * the history.
   */

  ChatApp.prototype.addMessage = function(groupId, message, is_history_message) {
    const fromMe = message.from.uuid === this.myUuid;
    let conversation;
    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      conversation = this.findGroupConversationById(groupId);
    } else {
      if (fromMe) {
        conversation = _.find(this.conversations, function(convo) {
          return message.to.uuid === convo.user.uuid && groupId === convo.user.sectionId;
        });
      } else {
        conversation = _.find(this.conversations, function(convo) {
          return message.from.uuid === convo.user.uuid && groupId === convo.user.sectionId;
        });
      }
    }

    if(is_history_message) {
      conversation.messages.unshift(new VHL.Chat.Message(message, fromMe));
    } else {
      conversation.messages.push(new VHL.Chat.Message(message, fromMe));
    }
  };

  /* getViewData - Returns a payload for the view to consume:
   {
     connected_users: 0,
     conversations: [{ conversationId: "sectionId-uuid",
                       user: {
                              uuid: "23",
                               firstName: "Dirt",
                               lastName: "Driver",
                              },
                       messages: [{
                                    fromUuid: "23"
                                    body: "hi there",
                                    time: TBD,
                                    type: "text",
                                    read: false,
                                    fromMe: false
                                 }],
                      }],
       {
         courses:[
                    {
                     courseId: "id",
                      name: "name",
                      sections: [
                                  {
                                    sectionId: "id",
                                    name: "name",
                                    users: [
                                             {
                                               uuid: "24",
                                               firstName: "Brando",
                                               lastName: "Kunde",
                                               username: "vhl_1_student"
                                               state: "busy"
                                            }
                                           ]
                                  }
                                ]
                    }
                  ]
       }
     }
   */
  ChatApp.prototype.getViewData = function() {
    var conversations = this.conversations;
    /* Build a hash of Users by their section */
    var usersBySection = {};

    if (VHL.Chat.isGroupChatActivity(VHL.Chat.CONFIG.activityType)) {
      this.roster.courses = filterCoursesByUserType(this.roster.courses);

      if (!VHL.Chat.CONFIG.instructorUser) {
        const sections = this.roster.courses[0].sections.filter((section) => {
          return section.id === `section_${VHL.Chat.CONFIG.sectionId}`;
        });
        this.roster.courses[0].sections = sections;
      }
    }

    _.each(this.roster.courses, function(course) {
      _.each(course.sections, function(section) {
        var convosForSection = _.filter(conversations, function(convo) {
          return convo.user.sectionId === section.id;
        });
        var users = _.map(convosForSection, function(convo) {
          return convo.user.getViewData();
        });
        usersBySection[section.id] = users;
      });
    });

    var viewData = {
      connected_users: 0,
      conversations: _.map(this.conversations, function(convo) {
        return convo.getViewData();
      }),
      courses: _.map(this.roster.courses, function(course) {
        return {
          courseId: course.id,
          programId: course.program_id,
          name: course.name,
          chat_level: course.chat_level,
          sections: _.map(course.sections, function(section) {
            return {
              name: section.name,
              sectionId: section.id,
              users: usersBySection[section.id]
            };
          })
        };
      })
    };
    console.log(viewData);
    return viewData;
  };

  return ChatApp;
})();
