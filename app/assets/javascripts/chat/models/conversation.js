/** Conversation class having information about other users as well as message thread in it.
 * @constructor
 * @param {string} uuid - user id.
 * @param {null|string} groupChatConversationId - Group chat conversation Id (optional).
 * @property {string} id - Composed of sectionId and uuid to guarantee uniqueness across sections.
 * @property {VHL.Chat.User|Array<VHL.Chat.User>} user - Its a user object for partner chat
 * and a list of users for group chat.
 * @property {boolean} isGroupChat - Whether this model represents a group chat conversation.
 * @property {Array} messages  - Array of Message objects.
 **/
VHL.Chat.Conversation = (function() {
  function Conversation(user, groupChatConversationId) {
    if (groupChatConversationId) {
      this.id = groupChatConversationId;
      this.isGroupChat = true;
    } else {
      this.id = user.sectionId + "-" + user.uuid;
    }
    this.user = user;
    this.messages = [];
  };

  /** Conversation prototype functions */

  Conversation.prototype.getViewData = function() {
    const users = this.isGroupChat? this.user : [this.user];
    let userNames = users.map((user) => `${user.firstName} ${user.lastName}`).join(', ') ?? '';
    userNames = userNames.replace(/,([^,]*)$/, ' and $1');
    const convoViewData = {
      conversationId: this.id,
      isGroupChat: this.isGroupChat,
      user: this.isGroupChat? this.user.map((user) => user.getViewData())  : this.user.getViewData(),
      userNames,
    };
    convoViewData.messages = _.map(this.messages, function(msg) {
      return msg.getViewData();
    });

    return convoViewData;
  };

  return Conversation;
})();
