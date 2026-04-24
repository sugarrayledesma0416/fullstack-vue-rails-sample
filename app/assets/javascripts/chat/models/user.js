/** User
 * @constructor
 * @param {String} uuid - The user uuid.
   @param {Converstaion} conversation - a conversation object with no messages.
 * @property {Array} - Array of Course objects for courses my user is enrolled in.
 **/

VHL.Chat.User = (function() {
  function User(uuid, firstName, lastName, username, sectionId, state, completedActivity) {
    this.uuid = uuid;
    this.firstName = firstName;
    this.lastName = lastName;
    this.username = username;
    this.sectionId = sectionId;
    // Available by default.
    this.state = state || 'available';
    this.completedActivity = completedActivity || false;
  };

  /** User prototype functions */
  User.prototype.getViewData = function() {
    return {
      uuid: this.uuid,
      firstName: this.firstName,
      lastName: this.lastName,
      sectionId: this.sectionId,
      state: this.state,
      completedActivity: this.completedActivity
    };
  };

  return User;
})();
