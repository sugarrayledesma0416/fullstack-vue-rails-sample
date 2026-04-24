import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import Portfolio from 'features/course_wizard/components/content_step/settings/Portfolio';
jest.mock('!!raw-loader!MusicAssets/images/music/icons/close.svg', () => jest.fn());

let wrapper;

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};
const props = {
  component: { 
    id: 11, 
    name: 'Portfolio', 
    license_groups: [
      {id: 3, name: 'WebSAM'}, 
      {id: 26, name: 'Portfolio'}
    ]
  } 
};

/**
 * This method gets wrapper for Portfolio component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Portfolio, {
    props,
    global: {
      provide: { courseDataStore },
    },
  });
}

describe('Portfolio', () => {
  describe('when shareToPortfolio is true', () => {
    beforeEach(async () => {
      courseDataStore.store.course.shareToPortfolio = true;
      wrapper = getWrapper();
      wrapper.vm.loadingResource = true;
      await wrapper.vm.$nextTick();
    });

    it('displays "Include Partner and Group chat"', () => {
      expect(wrapper.get('.test-title').text()).toBe(
        'Include Partner and Group Chat'
      );
    });
  });

  describe('when shareToPortfolio is false', () => {
    beforeEach(() => {
      courseDataStore.store.course.shareToPortfolio = false;
      wrapper = getWrapper();
    });

    it('does not display display "Include Partner and Group chat"', () => {
      expect(wrapper.find('.test-title').exists()).toBeFalsy();
    });
  });

  describe('when "Do not include" is selected', () => {
    beforeEach(async () => {
      courseDataStore.store.course.shareToPortfolio = true;
      wrapper = getWrapper();
      const elm = wrapper.get('.test-include_chat_activity');
      elm.element.value = 'false';
      elm.trigger('change');
      await wrapper.vm.$nextTick();
    });

    it('does not display PortfolioConfirmDialog', () => {
      expect(wrapper.find('.test-dialog-box').exists()).toBeFalsy();
    });
  });

  describe('when "Include" is selected', () => {
    beforeEach(async () => {
      courseDataStore.store.course.shareToPortfolio = true;
      wrapper = getWrapper();
      const elm = wrapper.get('.test-include_chat_activity');
      elm.element.value = 'true';
      await elm.trigger('change');
      await wrapper.vm.$nextTick();
    });

    it('displays PortfolioConfirmDialog', () => {
      expect(wrapper.find('.test-dialog-box').exists()).toBeTruthy();
    });
  });
});
