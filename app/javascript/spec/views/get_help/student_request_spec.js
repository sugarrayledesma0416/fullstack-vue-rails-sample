/*
This spec covers display of overlay and highlightable element for
request_help, request_review and report_content_problem.
*/
import { getHtmlDocument, elmFromString } from '../../support/utils';
import StudentRequest from 'views/get_help/student_request';

const fs = require('fs');
const path = require('path');

const requestRules = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, './../fixtures/help_request_rules.json'), 'utf8'
  )
);
const helpBannerHtml = fs.readFileSync(
  path.resolve(__dirname, './../fixtures/help_banner.html'), 'utf8'
);

/**
 * It executes the expectations when banner is visible.
 * @param {string} selector: A selector use to fetch help banner.
 */
const expectBannerToBeVisible = (selector) => {
  const helpBanner = document.querySelector(selector);
  expect(helpBanner.classList).not.toContain('u-hidden');
};

/**
 * It executes the expectations when banner is not visible.
 * @param {string} selector: A selector use to fetch help banner.
 */
const expectBannerNotToBeVisible = (selector) => {
  const helpBanner = document.querySelector(selector);
  expect(helpBanner.classList).toContain('u-hidden');
};

/**
 * It executes the expectations when overlay is visible.
 * @param {string} selector: A selector use to fetch overlay.
 */
const expectOverlayToBeVisible = (selector) => {
  const helpReqOverlay = document.querySelector(selector);
  expect(helpReqOverlay.classList).toContain('c-transparent-overlay');
  expect(helpReqOverlay.classList).not.toContain('u-hidden');
  expect(helpReqOverlay.classList).toContain('c-help-request-info-mode');
  expect(document.body.classList).toContain('u-pos-rel');
};

/**
 * It executes the expectations when overlay is not visible.
 * @param {string} selector: A selector use to fetch overlay.
 */
const expectOverlayNotToBeVisible = (selector) => {
  const helpReqOverlay = document.querySelector(selector);
  expect(helpReqOverlay.classList).toContain('u-hidden');
  expect(helpReqOverlay.classList).not.toContain('c-help-request-info-mode');
  expect(document.body.classList).not.toContain('u-pos-rel');
};

/**
 * It executes the expectations to check the accessibility of overlay.
 * @param {string} selector: A selector use to fetch all hotspot elements over overlay.
 */
const expectOverlayToBeAccessible = (selector) => {
  const hotspots = document.querySelectorAll(selector);
  const hotspotElmsLength = hotspots.length;
  expect(hotspots[0].classList).toContain('js-modal-a11y__first-focus-element');
  expect(hotspots[0].classList).toContain('js-modal-a11y__default-focus');
  expect(
    hotspots[hotspotElmsLength - 1].classList
  ).toContain('js-modal-a11y__last-focus-element');
};

/**
 * Expectations of submit and save button as enabled.
 */
const expectSaveSubmitBtnEnabled = () => {
  const submitBtn = document.querySelector('#_activity_submit');
  expect(submitBtn.classList).not.toContain('disabled-button');
  if (document.querySelector('#_activity_save')) {
    expect(
      document.querySelector('#_activity_save').classList
    ).not.toContain('disabled-button');
  }
};

/**
 * Expectations of submit and save button as disabled.
 */
const expectSaveSubmitBtnDisabled = () => {
  const submitBtn = document.querySelector('#_activity_submit');
  expect(submitBtn.classList).toContain('disabled-button');
  if (document.querySelector('#_activity_save')) {
    expect(
      document.querySelector('#_activity_save').classList
    ).toContain('disabled-button');
  }
};

/**
* Initialise Student Request.
 * @param {HTMLElement} html
 * @return {Object}
 */
const initStudentRequest = (html) => {
  document.body = getHtmlDocument(html.toString()).body;
  document.body.appendChild(
    elmFromString(helpBannerHtml.toString())
  );
  const studentRequest = new StudentRequest(requestRules);
  return studentRequest;
};

/**
 * Expectation of body to not contain classes help_request_mode,
 * report_problem_mode, report_content_mode.
 */
const expectBodyNotContainClass = () => {
  expect(document.body.classList).not.toContain('help_request_mode');
  expect(document.body.classList).not.toContain('report_problem_mode');
  expect(document.body.classList).not.toContain('report_content_mode');
};

/**
 * Expectation of body to contain class help_request_mode, and not contain
 * report_problem_mode, report_content_mode.
 */
const expectBodyToHaveHelpRequestMode = () => {
  expect(document.body.classList).toContain('help_request_mode');
  expect(document.body.classList).not.toContain('report_problem_mode');
  expect(document.body.classList).not.toContain('report_content_mode');
};

jest.dontMock('fs');

describe('when request mode is request_help', () => {
  const html = fs.readFileSync(
    path.resolve(__dirname, './../fixtures/activities/recording_v2.html'), 'utf8'
  );

  describe('when the Ask your instructor link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);
      studentRequest.activateRequestMode('request_help');
    });

    it('makes the banner visible', () => {
      expectBannerToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay visible', () => {
      expectOverlayToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes the overlay accessible', () => {
      expectOverlayToBeAccessible('.js-proxy-hotspot');
    });

    it('makes save and submit button disabled', () => {
      expectSaveSubmitBtnDisabled();
    });

    it('makes changes in the class of body tag', () => {
      expectBodyToHaveHelpRequestMode();
    });

    it('makes elements highlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toBeGreaterThanOrEqual(1);
    });
  });

  describe('when Cancel Request link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);

      studentRequest.activateRequestMode('request_help');
      studentRequest.cancelRequest();
    });

    it('makes the banner disappear', () => {
      expectBannerNotToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay disappear', () => {
      expectOverlayNotToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes save and submit button enabled', () => {
      expectSaveSubmitBtnEnabled();
    });

    it('makes changes in the class of body tag', () => {
      expectBodyNotContainClass();
    });

    it('makes elements unhighlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toEqual(0);
    });
  });
});


describe('when request mode is request_report_content', () => {
  const html = fs.readFileSync(
    path.resolve(__dirname, './../fixtures/activities/recording_v2.html'), 'utf8'
  );

  describe('when Report Content Problem link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);
      studentRequest.activateRequestMode('report_content_problem');
    });

    it('makes the banner visible', () => {
      expectBannerToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay visible', () => {
      expectOverlayToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes the overlay accessible', () => {
      expectOverlayToBeAccessible('.js-proxy-hotspot');
    });

    it('makes save and submit button disabled', () => {
      expectSaveSubmitBtnDisabled();
    });

    it('makes changes in the class of body tag', () => {
      expect(document.body.classList).not.toContain('help_request_mode');
      expect(document.body.classList).not.toContain('report_problem_mode');
      expect(document.body.classList).toContain('report_content_mode');
    });

    it('makes elements highlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toBeGreaterThanOrEqual(1);
    });
  });


  describe('when Cancel Request link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);
      studentRequest.activateRequestMode('report_content_problem');
      studentRequest.cancelRequest();
    });

    it('makes the banner disappear', () => {
      expectBannerNotToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay disappear', () => {
      expectOverlayNotToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes save and submit button enabled', () => {
      expectSaveSubmitBtnEnabled();
    });

    it('makes changes in the class of body tag', () => {
      expectBodyNotContainClass();
    });

    it('makes elements unhighlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toEqual(0);
    });
  });
});


describe('when request mode is request_review', () => {
  const html = fs.readFileSync(
    path.resolve(__dirname, './../fixtures/activities/submitted_vchat.html'), 'utf8'
  );

  describe('when Ask for Instructor link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);
      studentRequest.activateRequestMode('request_review');
    });

    it('makes the banner visible', () => {
      expectBannerToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay visible', () => {
      expectOverlayToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes the overlay accessible', () => {
      expectOverlayToBeAccessible('.js-proxy-hotspot');
    });

    it('makes changes in the class of body tag', () => {
      expectBodyToHaveHelpRequestMode();
    });

    it('makes elements highlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toBeGreaterThanOrEqual(1);
    });
  });


  describe('when Cancel Review Request link is clicked', () => {
    beforeAll(() => {
      const studentRequest = initStudentRequest(html);
      studentRequest.activateRequestMode('request_review');
      studentRequest.cancelRequest();
    });

    it('makes the banner disappear', () => {
      expectBannerNotToBeVisible('.js-help-request-flash');
    });

    it('makes the overlay disappear', () => {
      expectOverlayNotToBeVisible('.js-transparent-hr-overlay');
    });

    it('makes changes in the class of body tag', () => {
      expectBodyNotContainClass();
    });

    it('makes elements unhighlighted', () => {
      expect(
        document.querySelectorAll('.helpable').length
      ).toEqual(0);
    });
  });
});
