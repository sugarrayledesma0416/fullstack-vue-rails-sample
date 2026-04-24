VHL.Chat.Differ = (function(){

  /* Private functions */

  /**
   * Grab a conversation from a collection by its id.
   * @param  {Array} conversations - Collection of conversations.
   * @param  {Number} id             The id to search for.
   * @return {Object}                The matching conversation.
   */
  function findConversationById(conversations, id) {
    return _.findWhere(conversations, { conversationId: id });
  }

  /* Public functions */

  /**
   * Get any conversations that weren't present in the previous data payload.
   * @param  {Object} data - The latest view data.
   */
  function getNewConversations(data, dataCache) {
    // Filter out conversations that already exist in the cache:
    if (dataCache.conversations) {
      return _.reject(data.conversations, function(convo) {
        return findConversationById(dataCache.conversations, convo.conversationId);
      });
    } else {
      return data.conversations;
    }
  }

  /**
   * In already existing conversations, find the new messages.
   * @param {Object} data  The latest view data.
   */
  function getNewMessages(data, dataCache) {
    var changedConvos = [];
    // Loop through the old conversation data...
    if (dataCache.conversations) {
      _.each(dataCache.conversations, function(cachedConvo) {
        // Grab the updated version:
        var updatedConvo = findConversationById(data.conversations, cachedConvo.conversationId);

        if(updatedConvo) {
          // Get the message diff, then sort chronologically.
          // We need to do a set operation here, so _.without won't work. This will also improve
          // the performance for a chat with a big amount of conversations.
          var newMessages = _.difference(updatedConvo.messages, cachedConvo.messages);

          if (newMessages.length != 0) {
            changedConvos.push({
              conversationId: updatedConvo.conversationId,
              isGroupChat: updatedConvo.isGroupChat,
              messages: _.sortBy(newMessages, 'time')
            });
          }
        }
      });
    }
    return changedConvos;
  }

  return {
    getNewMessages: getNewMessages,
    getNewConversations: getNewConversations
  };
})();
