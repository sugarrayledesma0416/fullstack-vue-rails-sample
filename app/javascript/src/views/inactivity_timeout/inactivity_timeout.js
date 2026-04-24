import { reactive } from 'vue';
import { metaTagContent } from 'shared/utils.js';
import * as ajaxUtils from 'shared/ajax_utils';

/**
 * This class handles session timeout due to long inactivity.
 * It polls the server based on various configurations.
 */
export default class InactivityTimeout {
  /**
   * Set initial configuration and constants for inactivity timeout.
   * @constructor
   */
  constructor({
      currentSchoolId,
      enabledInSelectedSchool,
      enabledInAnySchool,
      timeoutDuration,
      secondsBeforeWarning,
      secondsBetweenChecks
    }) {
    this.currentSchoolId = currentSchoolId;
    this.lastServerRequestTime = null;
    this.setLastActivityEpochTime();
    this.shouldHandleTabFocus = false;
    this.shouldHandleDialogConfirm = false;
    this.dialogData = reactive({
      remainingTime: 0,
      show: false,
    });
    // Some of the timeout configuration values are set by settings at server.
    this.timeoutConfig = {
      // Minimum interval in ms between mouse moves
      // used for throttling of mousemove handler
      mouseMoveThrottleInMilliSec: 500,
      // Time before potential logout in seconds, when warning dialog would be shown.
      secondsBeforeWarning: secondsBeforeWarning,
      // Time interval in seconds, to continuously calculate whether to poll the server.
      secondsBetweenChecks: secondsBetweenChecks,
      // Time interval between server requests in seconds. This interval,
      // with some exceptions, is used to minimize server request counts.
      secondsBetweenServerChecks: timeoutDuration / 4,
      // Maximum allowed inactivity duration in seconds after which user would be logged out.
      timeoutDurationInSeconds: timeoutDuration,
    };

    // setup event handlers and start polling the server for session logout.
    if (enabledInAnySchool) {
      this.addEventHandlers();
      this.setIntervalId = window.setInterval(
        this.checkInactivityTimeout.bind(this),
        this.timeoutConfig.secondsBetweenChecks * 1000
      );
    }
  }

  /**
   * Getter for lastActivityEpochTime (epoch time in ms) value in local storage.
   * @return {number}
   */
  get lastActivityEpochTimeInLS() {
    return parseInt(localStorage.getItem('lastActivityEpochTime'));
  }

  /**
   * Bind various user action events to update last recorded time for user activity.
   * For optimization, throttle the 'mousemove' event handler.
   * Handle 'visibilitychange' event to detect when a browser tab returns to focus.
   */
  addEventHandlers() {
    ['click', 'keydown', 'scroll', 'touchend'].forEach((evtName) => {
      document.addEventListener(evtName, (evt) => {
        this.handleUserActionEvent(evtName, evt);
      }, false);
    });

    let shouldWaitForThrottle = false;
    ['mousemove'].forEach((evtName) => {
      document.addEventListener(evtName, (evt) => {
        if (!shouldWaitForThrottle) {
          this.handleUserActionEvent(evtName, evt);
          shouldWaitForThrottle = true;
          setTimeout(() => {
            shouldWaitForThrottle = false;
          }, this.timeoutConfig.mouseMoveThrottleInMilliSec);
        }
      }, false);
    });

    document.addEventListener('visibilitychange', () => {
      this.handleVisibilitychangeEvent();
    });
  }

  /**
   * This method runs on a fixed interval. This conditionally updates the
   * server about last activity time on frontend and polls the server about
   * whether user should be logged out due to long inactivity.
   *
   * To optimize server call counts, last activity time is maintained at frontend as well.
   * Server is requested when signout or warning dialog condition is detected
   * based on front end data.
   * Besides, server is requested in regular larger intervals (secondsBetweenServerChecks)
   * to update the server with current stored last activity time at frontend.
   *
   * This method updates lastActivityEpochTime in local storage if needed.
   */
  checkInactivityTimeout() {
    this.syncLastActivityEpochTimeInLS();
    const secondsSinceLastServerReq = Math.floor((Date.now() - this.lastServerRequestTime)/1000);
    if (secondsSinceLastServerReq > this.timeoutConfig.secondsBetweenServerChecks ||
      this.shouldRequestServer()) {
      this.checkServerSessionTimeout();
    }
  }

  /**
   * Poll the server to fetch remaining time for logout.
   * Reset the tab focus and dialog confirmation related flags,
   * once last activity time to be sent to server is finalized.
   * Based on the server response, show warning dialog
   * or logout the user if applicable.
   */
  checkServerSessionTimeout() {
    const lastActivityTimeInSeconds = Math.floor(this.lastActivityEpochTime/1000);
    if (this.shouldHandleTabFocus) {
      this.shouldHandleTabFocus = false;
    }
    if (this.shouldHandleDialogConfirm) {
      this.shouldHandleDialogConfirm = false;
    }
    this.lastServerRequestTime = Date.now();
    ajaxUtils.putToEndpoint(
      '/inactivity_timeouts/update_session',
      {
        school_id: this.currentSchoolId,
        last_activity_time_epoch: lastActivityTimeInSeconds
      },
      async (response) => {
        const secondsUntilTimeout = response.ttl_to_timeout;
        if (secondsUntilTimeout !== null) {
          if (secondsUntilTimeout <= 0) {
            this.ensureLogOut();
          } else if (secondsUntilTimeout > 0 &&
            secondsUntilTimeout < this.timeoutConfig.secondsBeforeWarning) {
            this.showWarningDialog(secondsUntilTimeout);
          } else if (secondsUntilTimeout > 0 &&
            secondsUntilTimeout >= this.timeoutConfig.secondsBeforeWarning) {
            this.hideWarningDialog();
          }
        }
      }
    );
  }

  /**
   * Hide warning dialog and immediately send polling request
   * with updated value of user's last activity time.
   * Update last activity time here separately because we
   * are ignoring event handlers to update last activity time
   * when dialog is open.
   */
  confirmUserActivity() {
    this.dialogData.show = false;
    this.resetLastActivityTime();
    this.shouldHandleDialogConfirm = true;
    this.immediatelyPollAndResetInterval();
  }

  /**
   * Ensure to log user out.
   * Set a global flag to prevent additional warning dialog
   * (eg. unsaved data warnings or confirmation dialogs) after timeout.
   */
  ensureLogOut() {
    VHL.Common.preventWarningsAfterTimeout(true);
    window.location.href = '/inactivity_timeouts/log_out';
  }

  /**
   * Update lastActivityEpochTime variable with timestamp of a user action event
   * except following conditions:
   * - When user just switched to current browser tab, then avoid this updation till
   *   its confirmed via polling whether user should be logged out due to inactivity.
   * - Avoid updation if warning dialog is open.
   */
  handleUserActionEvent() {
    if (!this.shouldHandleTabFocus && !this.dialogData.show) {
      this.lastActivityEpochTime = Date.now();
    }
  }

  /**
   * If user just switched to current tab (ie. current tab was inactive
   * for some time), then set shouldHandleTabFocus flag so further
   * user activities are not recorded till its confirmed via polling
   * whether user should be logged out due to inactivity.
   * Also call the polling method immediately to minimize the time window for
   * handling shouldHandleTabFocus. And reset setInterval for further polling.
   */
  handleVisibilitychangeEvent() {
    if (document.visibilityState === 'visible') {
      this.shouldHandleTabFocus = true;
      this.immediatelyPollAndResetInterval();
    }
  }

  /**
   * Update warning dialog related data to hide warning dialog in vue app.
   */
  hideWarningDialog() {
    this.dialogData.show = false;
  }

  /**
   * Call the polling method immediately to minimize the time window for
   * handling shouldHandleTabFocus or shouldHandleDialogConfirm flags.
   * And reset setInterval for further polling.
   */
  immediatelyPollAndResetInterval() {
    window.clearInterval(this.setIntervalId);
    this.checkInactivityTimeout();
    this.setIntervalId = window.setInterval(
      this.checkInactivityTimeout.bind(this),
      this.timeoutConfig.secondsBetweenChecks * 1000
    );
  }

  /**
   * Reset last activity time to current time value.
   */
  resetLastActivityTime() {
    this.lastActivityEpochTime = Date.now();
  }

  /**
   * Set last activity epoch time with current time
   * in variable and local storage.
   */
  setLastActivityEpochTime() {
    this.lastActivityEpochTime = Date.now();
    localStorage.setItem('lastActivityEpochTime', this.lastActivityEpochTime);
  }

  /**
   * Hide the warning dialog and log user out.
   */
  signOutUser() {
    this.dialogData.show = false;
    this.ensureLogOut();
  }

  /**
   * Return whether server request is required besides regular
   * server check intervals (ie. secondsBetweenServerChecks).
   * Ruleset:
   * - If inactivity time stored at client suggests to open warning dialog.
   * - If inactivity time stored at client suggests to log the user out.
   * - If user just returned to an inactive tab.
   * - If user just confirmed on Inactivity Warning dialog.
   * @return {boolean}
   */
  shouldRequestServer() {
    const secondsSinceActive = Math.floor((Date.now() - this.lastActivityEpochTimeInLS)/1000);
    const secondsUntilTimeout = this.timeoutConfig.timeoutDurationInSeconds - secondsSinceActive;
    let checkForWarning = false;
    let checkForSignout = false;
    if (secondsUntilTimeout <= 0) {
      checkForSignout = true;
    } else if (secondsUntilTimeout < this.timeoutConfig.secondsBeforeWarning) {
      checkForWarning = !this.dialogData.show;
    } else if (secondsUntilTimeout >= this.timeoutConfig.secondsBeforeWarning) {
      this.hideWarningDialog();
    }
    return this.shouldHandleTabFocus ||
      this.shouldHandleDialogConfirm ||
      checkForWarning ||
      checkForSignout;
  }

  /**
   * Update warning dialog related data to display warning dialog
   * in vue app with correct timer info.
   * @param {number} secondsUntilTimeout
   */
  showWarningDialog(secondsUntilTimeout) {
    this.dialogData.remainingTime = secondsUntilTimeout;
    this.dialogData.show = true;
  }

  /**
   * Sync lastActivityEpochTime value with local storage value.
   * We periodically update local storage for multitab scenario.
   */
  syncLastActivityEpochTimeInLS() {
    if (this.lastActivityEpochTime > this.lastActivityEpochTimeInLS) {
      localStorage.setItem('lastActivityEpochTime', this.lastActivityEpochTime);
    } else {
      this.lastActivityEpochTime = this.lastActivityEpochTimeInLS;
    }
  }
}
