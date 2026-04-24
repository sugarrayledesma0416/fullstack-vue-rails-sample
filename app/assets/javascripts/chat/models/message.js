/** Message
 * @constructor
 * @param {String} fromUuid - The uuid of the user who sent this message.
 * @param {String} body - The text to display for this message.
 * @param {Boolean} fromMe - Is true if I sent this message.
 **/
VHL.Chat.Message = (function() {
  function Message(message, fromMe) {
    this.fromUuid = message.from.uuid;
    this.body = message.text;
    this.type = "text"; //TODO make constants for message types
    this.read = false; //TODO: call Message.prototype.markAsRead() when message has been read.
    this.fromFirst = message.from.first_name;
    this.fromLast = message.from.last_name;
    this.fromMe = fromMe;
    this.messageFrom = fromMe ?  "You said" : `${message.from.first_name} ${message.from.last_name} said` ;

    /** The PubNub timetoken has 17-digit precision.
     *    Divide by 10^4 to get millisecond precision.
     */
    var timestampInMilliseconds = Math.round(message.timetoken / 10000);
    this.sentTime = timestampInMilliseconds; // Stored as integer.
  };

  /** User prototype functions */
  Message.prototype.markAsRead = function() {
    this.read = true; // TODO un-hardcode this
  };

  Message.prototype.getViewData = function() {
    return {
      fromUuid: this.fromUuid,
      fromFirst:this.fromFirst,
      fromLast: this.fromLast,
      messageFrom: this.messageFrom,
      body: this.body,
      time: this.sentTime,
      type: this.type,
      read: this.read,
      fromMe: this.fromMe
    };
  };

  return Message;
})();
