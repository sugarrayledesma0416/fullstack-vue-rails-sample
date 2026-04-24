import { mount } from '@vue/test-utils';
import AddHelpRequest from 'features/get_help/AddHelpRequest';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

VHL = VHL || {};
VHL.AccentBarComponent = class {
  register() {}
  deactivateAll() {}
};

jest.mock('shared/accent_bar_helper', () => {
  return jest.fn().mockImplementation(() => {
    return {
      attachToAccentBarEvents: jest.fn(),
      detachFromAccentBarEvents: jest.fn(),
      moveAccentBarBackToActivity: jest.fn(),
      moveAccentBarToRequestModal: jest.fn(),
    };
  });
});

describe('AddHelpRequest', () => {
  let wrapper;

  const commonProps = {
    activityId: 1,
    payloadFromRails: {},
    requestSeverityLevels: [],
    sectionId: 1,
    userType: 'student',
  };

  const commonPayloadForShowDialog = {
    activityFormData: 'key1=value1&key2=value2',
    helpableItemId: 'helpable-id-1',
    helpableItemType: 'helpable-item-type-1',
    requestMode: 'request_help',
  };

  const requestUrl = `/sections/1/activities/1/help_requests`;

  const setComment = async (newComment) => {
    const inputElm = wrapper.get('.test-help-request-comment-input');
    await inputElm.setValue(newComment);
  };

  /**
   * This method gives a Wrapper based on input data
   * @param {String} userType enum values of 'student', 'instructor'
   * @param {requestMode} requestMode one of the following enum values
   * 'request_help'
   * 'request_review'
   * 'Review My Score'
   * 'report_content_problem'
   * 'report_technical_problem'
   * @return {Object} a Wrapper that contains the mounted Vue component.
   */
  const getWrapper = (userType, requestMode) => {
    const propsData = { ...commonProps, ...{ userType }};
    const payload = { ...commonPayloadForShowDialog, ...{ requestMode }};
    const wrapper = mount(AddHelpRequest, {
      propsData: propsData,
    });
    wrapper.vm.showDialog(payload);
    return wrapper;
  };

  describe('when userType is student', () => {
    describe('when requestMode is "request_help".', () => {
      beforeEach(() => {
        wrapper = getWrapper('student', 'request_help');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Request Instructor Help"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Request Instructor Help');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });

      describe('when comment is changed.', () => {
        beforeEach(() => {
          wrapper = getWrapper('student', 'request_help');
        });

        it('I can see enabled submit button', async () => {
          await setComment('Test comment');
          expect(wrapper.get('.test-submit-help-request').element).not.toBeDisabled();
        });
      });

      describe('when cancel clicked.', () => {
        beforeEach(() => {
          wrapper = getWrapper('student', 'request_help');
        });

        it('I can not see modal with title "Request Instructor Help"', async () => {
          await wrapper.get('.test-cancel-help-request').trigger('click');
          expect(wrapper.find('.test-modal-heading').exists()).toBeFalsy();
        });
      });

      describe('when submit clicked.', () => {
        beforeEach(async () => {
          fetchMock.mock({
            url: requestUrl, response: { status: 200, body: {}}});
          wrapper = getWrapper('student', 'request_help');
          wrapper.vm.showDialog(commonPayloadForShowDialog);
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
        });

        afterEach(() => {
          fetchMock.restore();
        });

        it('does make an ajax request', async () => {
          await setComment('This is test help request comment.');
          await wrapper.get('.test-submit-help-request').trigger('click');
          expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
            requestUrl,
            jasmine.any(Object),
            jasmine.any(Function)
          );
        });
      });
    });

    describe('when requestMode is "request_review".', () => {
      beforeEach(() => {
        wrapper = getWrapper('student', 'request_review');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Review My Score"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Review My Score');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });

    describe('when requestMode is "report_content_problem".', () => {
      beforeEach(() => {
        wrapper = getWrapper('student', 'report_content_problem');
      });

      describe('when showDialog is called.', () => {
        beforeEach(() => {
          wrapper = getWrapper('student', 'report_content_problem');
        });

        it('I can see title "Report Content Error"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Report Content Error');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });

    describe('when requestMode is "report_technical_problem".', () => {
      beforeEach(() => {
        wrapper = getWrapper('student', 'report_technical_problem');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Report Technical Problem"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Report Technical Problem');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });
  });

  describe('when userType is instructor', () => {
    describe('when requestMode is "request_help".', () => {
      beforeEach(() => {
        wrapper = getWrapper('instructor', 'request_help');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Request Instructor Help"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Request Instructor Help');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can not see comment text field', () => {
          expect(wrapper.find('.test-help-request-comment-input').exists()).toBeFalsy();
        });

        it('I can see instructor text', () => {
          expect(wrapper.get('.test-help-request-instructor-text').isVisible()).toBeTruthy();
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });

    describe('when requestMode is "request_review".', () => {
      beforeEach(() => {
        wrapper = getWrapper('instructor', 'request_review');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Review My Score"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Review My Score');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can not see comment text field', () => {
          expect(wrapper.find('.test-help-request-comment-input').exists()).toBeFalsy();
        });

        it('I can see instructor text', () => {
          expect(wrapper.get('.test-help-request-instructor-text').isVisible()).toBeTruthy();
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });

    describe('when requestMode is "report_content_problem".', () => {
      beforeEach(() => {
        wrapper = getWrapper('instructor', 'report_content_problem');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Report Content Error"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Report Content Error');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can not see instructor text', () => {
          expect(wrapper.find('.test-help-request-instructor-text').exists()).toBeFalsy();
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });

    describe('when requestMode is "report_technical_problem".', () => {
      beforeEach(() => {
        wrapper = getWrapper('instructor', 'report_technical_problem');
      });

      describe('when showDialog is called.', () => {
        it('I can see title "Report Technical Problem"', () => {
          expect(wrapper.get('.test-modal-heading').text()).toBe('Report Technical Problem');
        });

        it('I can see close button on dialog', () => {
          expect(wrapper.get('.test-modal-close-button').isVisible()).toBeTruthy();
        });

        it('I can see empty comment text field', () => {
          expect(wrapper.get('.test-help-request-comment-input').element.value).toBe('');
        });

        it('I can not see instructor text', () => {
          expect(wrapper.find('.test-help-request-instructor-text').exists()).toBeFalsy();
        });

        it('I can see disabled submit button', () => {
          expect(wrapper.get('.test-submit-help-request').element).toBeDisabled();
        });
      });
    });
  });
});
