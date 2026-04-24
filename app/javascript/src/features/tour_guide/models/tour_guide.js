import TourGuideEventTrigger from './tour_guide_event_trigger';
/**
 * @typedef {Object} User
 * @property {String} guid - user's guid
 * @property {String} role - user's instructor role
 * @property {String} hasTrialAccess - whether user has trial access for given programId
 */

/**
 * @typedef {Object} CustomTrigger
 * @property {String} stepChildId - id of the associated appcues flow step child
 * @property {String} stepId - id of the associated appues flow step
 * @property {String} flowId - id of the associated appcues flow
 * @property {String} eventType - event to trigger after appcues event
 * @property {String} selector - selector to locate element to perform event on
 * @property {String} tourGuideEventType - appcues event type to listen for
 * @property {Number} delay - delay to wait after appcues event
 */

/**
  * Connects and interacts with our chosen tour guide partner's api (currently appcues)
*/
class TourGuide {
  /**
   * @constructor
   * @param {User} user
   * @param {String} programId
   * @param {CustomTrigger[]} customTriggers
   */
  constructor(user, programId, customTriggers) {
    this.user = user;
    this.programId = programId;
    this.customTriggers = customTriggers;
  }

  /**
   * Set up connection and custom triggers for tour guide
   */
  initialize() {
    this.connect();
    this.transformTriggers();
  }

  /**
   * Connect to appcues and identify current user
   */
  connect() {
    window.Appcues.identify(this.user.guid, this.userProperties());
  }

  /**
   * @param {CustomTrigger} trigger
   * Create appcues event listener
   */
  createListener(trigger) {
    window.Appcues.on(trigger.tourGuideEventType, (event) => trigger.dispatch(event));
  }

  /**
   * Transform triggers into proper trigger objects
   */
  transformTriggers() {
    this.customTriggers.forEach((trigger) => {
      const transformedTrigger = new TourGuideEventTrigger(trigger);
      this.createListener(transformedTrigger);
    });
  }
  /**
   * Properties to pass to appcues
   * @return {User}
   */
  userProperties() {
    return {
      hasTrialAccess: this.user.hasTrialAccess,
      role: this.user.role,
      programId: this.programId,
      createdAt: this.user.createdAt,
    };
  }
}

export default TourGuide;
