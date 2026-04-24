import InactivityTimeout from 'views/inactivity_timeout/inactivity_timeout';
import fetchMock from 'fetch-mock';
import * as ajaxUtils from 'shared/ajax_utils';

window.VHL = { Common: { preventWarningsAfterTimeout: jest.fn() }};

let inactivityTimeout;
let inactivityTimeoutParams = {
  currentSchoolId: 106,
  enabledInSelectedSchool: true,
  enabledInAnySchool: true,
  timeoutDuration: 100,
  secondsBeforeWarning: 50,
  secondsBetweenChecks: 10
};

/**
 * Prepare Mock Meta Data embedded to the document.
 */
function mockMetaData() {
  const meta = document.createElement('meta');
  meta.name = 'VHL.current_school';
  meta.content = '106';
  document.head.appendChild(meta);
}

/**
 * Prepare Mock Request.
 * @param {number} ttlToTimeout
 */
function mockRequest(ttlToTimeout) {
  const lastActivityTimeInSeconds = Math.floor(inactivityTimeout.lastActivityEpochTime/1000);
  spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
  fetchMock.mock(
    '/inactivity_timeouts/update_session',
    {
      ttl_to_timeout: ttlToTimeout,
      school_id: '106'
    }
  );
}

describe('InactivityTimeout', () => {
  describe('initialise inactivity timeout class', () => {
    beforeAll(() => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
    });

    it('sets lastActivityEpochTime to the localStorage.', () => {
      expect(localStorage.getItem('lastActivityEpochTime')).not.toBeFalsy();
    });

    it('gets the stored localStorage from lastActivityEpochTimeInLS method', () => {
      expect(typeof inactivityTimeout.lastActivityEpochTimeInLS).toEqual('number');
    });

    it('calls hideWarningDialog to hide the warning dialog', () => {
      expect(inactivityTimeout.dialogData.show).toBeFalsy();
    });

    it('calls resetLastActivityTime to reset the lastActivityEpochTime.', () => {
      const oldLastActivityTime = inactivityTimeout.lastActivityEpochTime;
      inactivityTimeout.resetLastActivityTime();

      expect(
        inactivityTimeout.lastActivityEpochTime
      ).not.toEqual(oldLastActivityTime);
    });
  });

  describe('showWarningDialog', () => {
    beforeAll(() => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      const testSecondsUntilTimeout = 5;
      inactivityTimeout.showWarningDialog(testSecondsUntilTimeout);
    });

    it('calls makes the warning dialog visible', () => {
      expect(inactivityTimeout.dialogData.show).toBeTruthy();
    });
  });

  describe('signOutUser', () => {
    beforeAll(() => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      delete window.location;
      window.location = { href: jest.fn() };
      inactivityTimeout.signOutUser();
    });

    it('calls signOutUser to logout the user', () => {
      expect(window.location.href).toEqual('/inactivity_timeouts/log_out');
    });
  });

  describe('syncLastActivityEpochTimeInLS', () => {
    beforeAll(async () => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
    });

    it('sets lastActivityEpochTime equals to lastActivityEpochTimeInLS', () => {
      inactivityTimeout.syncLastActivityEpochTimeInLS();
      expect(inactivityTimeout.lastActivityEpochTime).toEqual(
        inactivityTimeout.lastActivityEpochTimeInLS
      );
    });

    it('sets the lastActivityEpochTime in localStorage', () => {
      inactivityTimeout.lastActivityEpochTime = inactivityTimeout.lastActivityEpochTimeInLS + 5;
      inactivityTimeout.syncLastActivityEpochTimeInLS();
      expect(localStorage.getItem('lastActivityEpochTime')).toEqual(
        inactivityTimeout.lastActivityEpochTime.toString()
      );
    });
  });

  describe('checkServerSessionTimeout with ttl less than secondsBeforeWarning', () => {
    beforeAll(async () => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      mockRequest(10);

      await inactivityTimeout.checkServerSessionTimeout();
    });

    afterEach(() => fetchMock.restore());

    it('shows warning dialog', () => {
      expect(inactivityTimeout.dialogData.show).toBeTruthy();
    });

    it('sets the dialog remaining time as ttl_to_timeout', () => {
      expect(inactivityTimeout.dialogData.remainingTime).toEqual(10);
    });
  });

  describe('checkServerSessionTimeout with ttl more than secondsBeforeWarning', () => {
    beforeAll(async () => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      mockRequest(500);

      await inactivityTimeout.checkServerSessionTimeout();
    });

    afterEach(() => fetchMock.restore());

    it('hides the warning dialog', () => {
      expect(inactivityTimeout.dialogData.show).toBeFalsy();
    });
  });

  describe('checkServerSessionTimeout with ttl as negative', () => {
    beforeAll(async () => {
      mockMetaData();
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      mockRequest(-2);
      delete window.location;
      window.location = { href: jest.fn() };

      await inactivityTimeout.checkServerSessionTimeout();
    });

    afterEach(() => fetchMock.restore());

    it('sets user logout and session is destroyed', () => {
      expect(window.location.href).toEqual('/inactivity_timeouts/log_out');
    });
  });

  describe('immediatelyPollAndResetInterval', () => {
    beforeEach(() => {
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      inactivityTimeout.checkInactivityTimeout = jest.fn();
      inactivityTimeout.setIntervalId = 123;
      jest.useFakeTimers();

      inactivityTimeout.immediatelyPollAndResetInterval();
    });

    afterEach(() => {
      jest.clearAllTimers();
    });

    it('should clear existing interval', () => {
      expect(window.clearInterval).toHaveBeenCalledWith(123);
    });

    it('should invoke checkInactivityTimeout', () => {
      expect(inactivityTimeout.checkInactivityTimeout).toHaveBeenCalled();
    });
  });

  describe('shouldRequestServer', () => {
    beforeEach(() => {
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);

      localStorage.setItem('lastActivityEpochTime', Date.now());
      inactivityTimeout.timeoutConfig = {
        timeoutDurationInSeconds: 60,
        secondsBeforeWarning: 10,
      };
    });

    it('returns true if shouldHandleTabFocus is set as true', () => {
      inactivityTimeout.shouldHandleTabFocus = true;
      expect(inactivityTimeout.shouldRequestServer()).toBeTruthy();
    });

    it('returns true if shouldHandleDialogConfirm set as true', () => {
      inactivityTimeout.shouldHandleDialogConfirm = true;
      expect(inactivityTimeout.shouldRequestServer()).toBeTruthy();
    });

    it('returns false for rest of the scenarios', () => {
      inactivityTimeout.dialogData.show = true;
      expect(inactivityTimeout.shouldRequestServer()).toBeFalsy();
    });
  });

  describe('checkInactivityTimeout', () => {
    beforeEach(() => {
      inactivityTimeout = new InactivityTimeout(inactivityTimeoutParams);
      inactivityTimeout.syncLastActivityEpochTimeInLS = jest.fn();
      inactivityTimeout.checkServerSessionTimeout = jest.fn();
      inactivityTimeout.timeoutConfig = {
        secondsBetweenServerChecks: 20,
      };
      inactivityTimeout.lastServerRequestTime = Date.now() - 70000;
    });

    describe('when secondsSinceLastServerReq is greater than secondsBetweenServerChecks', () => {
      beforeEach(() => {
        inactivityTimeout.shouldRequestServer = jest.fn().mockReturnValue(true);
        inactivityTimeout.checkInactivityTimeout();
      });

      it('should not invoke shouldRequestServer', () => {
        expect(inactivityTimeout.shouldRequestServer).not.toHaveBeenCalled();
      });

      it('should invoke checkServerSessionTimeout', () => {
        expect(inactivityTimeout.checkServerSessionTimeout).toHaveBeenCalled();
      });
    });

    describe('when secondsSinceLastServerReq is smaller than secondsBetweenServerChecks and' +
      'shouldRequestServer turns false', () => {
      beforeEach(() => {
        inactivityTimeout.shouldRequestServer = jest.fn().mockReturnValue(false);
        inactivityTimeout.timeoutConfig = {
          secondsBetweenServerChecks: 100,
        };
        inactivityTimeout.checkInactivityTimeout();
      });

      it('should invoke shouldRequestServer', () => {
        expect(inactivityTimeout.shouldRequestServer).toHaveBeenCalled();
      });

      it('should not invoke checkServerSessionTimeout', () => {
        expect(inactivityTimeout.checkServerSessionTimeout).not.toHaveBeenCalled();
      });
    });
  });
});
