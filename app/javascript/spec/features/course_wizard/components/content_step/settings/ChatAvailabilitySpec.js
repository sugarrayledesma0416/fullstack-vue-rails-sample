import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import ChatAvailability
  from 'features/course_wizard/components/content_step/settings/ChatAvailability';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};
const config = {
  institutionSupportsChat: true,
};
/**
 * This method gets wrapper for TechnicalSupportAndChat component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(ChatAvailability, {
    global: {
      provide: { courseDataStore, config},
    },
  });
}

/**
 * This method returns whether the checkbox with the given css selector is checked
 * or not in the wrapper
 * @param {string} elmSelector - Css selector for checkbox
 * @return {boolean} - Whether the checkbox is checked
 */
function getCheckedState(elmSelector) {
  return wrapper.get(elmSelector).element.checked;
}

let wrapper;
describe('ChatAvailability', () => {
  describe('mounted', () => {
    describe('when chatLevel is "partner_chat"', () => {
      beforeEach(() => {
        courseDataStore.store.course.chatLevel = 'partner_chat';
        wrapper = getWrapper();
      });

      it('informs the user about the feature', () => {
        expect(wrapper.get('p').text()).toEqual(
          'By enabling chat features, you and your students can send, share, and record messages (text, video, audio).'
        );
      });

      it('displays "Chat availability to students - Never available" radio button ' +
        'in unchecked state', () => {
        expect(getCheckedState('.test-chat-availability-never-rb')).toBeFalsy();
      });

      it('displays "Chat availability to students - Only in Partner Chat activities" ' +
        'radio button in checked state', () => {
        expect(getCheckedState('.test-chat-availability-in-partner-chat-rb')).toBeTruthy();
      });

      it('displays "Chat availability to students - Always available" radio button ' +
        'in unchecked state', () => {
        expect(getCheckedState('.test-chat-availability-always-rb')).toBeFalsy();
      });
    });

    describe('when the institution disabled chat support', () => {
      beforeEach(() => {
        config.institutionSupportsChat = false;
        courseDataStore.store.course.chatLevel = 'partner_chat';
        wrapper = getWrapper();
      });

      it('informs the user that the chat feature is disabled', () => {
        expect(wrapper.get('p').text()).toEqual(
          'Your institution has disabled this behavior.'
        );
      });

      it('does not display any radio button', () => {
        expect(wrapper.find('input[type="radio"]').exists()).toBeFalsy();
      });
    });
  });
});
