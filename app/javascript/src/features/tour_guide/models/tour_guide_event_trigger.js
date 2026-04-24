import { snakeCase } from 'snake-case';

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

/** Class representing a post-appcues event trigger model. */
class TourGuideEventTrigger {
  /**
   * Instantiate the TourGuideEventTrigger class.
   * @constructor
   * @param { CustomTrigger } triggerAttributes - Attributes of the given trigger:
   *  Required:
   *    - tourGuideEventType to follow
   *    - eventType to trigger following the appcues event
   *    - appcues stepChildId, stepId, or flowId
   *    - element selector for identifying targeted element
   *
   *  Optional:
   *    - delay: integer of milliseconds for delaying dispatching event
   */
  constructor(triggerAttributes) {
    this._triggerAttributes = triggerAttributes;
    this.tourGuideEventType = triggerAttributes.tourGuideEventType;
    this.eventType = triggerAttributes.eventType;
    this.delay = {}.hasOwnProperty.call(triggerAttributes, 'delay') ? triggerAttributes.delay : 0;
    this.idName = this.idName(triggerAttributes);
    if (!this.validEventType()) {
      console.error('tourGuideEventType and provided id type do not match');
    }

    this.targetedElement = this.targetedElement(triggerAttributes.selector);
  }

  /**
   * Dispatch triggered event when the trigger's appcues id matches the
   *  listened event's appcues id
   * @param { Event } event - event returned from appcues listener
   */
  dispatch(event) {
    if (this.targetsEventResource(event)) {
      const triggeredEvent = new Event(this.eventType, { bubbles: true });
      setTimeout(() => {
        this.targetedElement.dispatchEvent(triggeredEvent);
      }, this.delay);
    }
  }

  /**
   * @private
   * Check for appropriately named event type based upon idName
   * @return { Boolean }
   */
  validEventType() {
    const eventPrefix = snakeCase(this.idName.replace('Id', ''));
    return this.tourGuideEventType.includes(eventPrefix);
  }

  /**
   * @private
   * Get id for trigger's appcues resource
   * @return { Integer } appcues trigger resource id
   */
  id() {
    return this._triggerAttributes[this.idName];
  }

  /**
   * @private
   * Checks event for matching stepId or flowId
   * @param { Event } event - appcues event
   * @return { Integer } appcues trigger resource id
   */
  targetsEventResource(event) {
    return event[this.idName] === this.id();
  }

  /**
   * @private
   * Determines if id type is stepId or flowId
   * @param { Object }  attrs - trigger attributes
   * @return { String|null } id type name or null
   */
  idName(attrs) {
    if ({}.hasOwnProperty.call(attrs, 'stepChildId')) {
      return 'stepChildId';
    } else if ({}.hasOwnProperty.call(attrs, 'stepId')) {
      return 'stepId';
    } else if ({}.hasOwnProperty.call(attrs, 'flowId')) {
      return 'flowId';
    } else {
      return null;
    }
  }

  /**
   * @private
   * Finds targeted element based off of given selector
   * @param { String }  selector - id or css selector
   * @return { HTMLElement } element matching selector
   */
  targetedElement(selector) {
    if (selector.includes('#')) {
      return document.getElementById(selector.replace('#', ''));
    } else {
      return document.querySelector(selector);
    }
  }
}

export default TourGuideEventTrigger;
