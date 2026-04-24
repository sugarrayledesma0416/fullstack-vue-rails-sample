import { reactive, ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import ReviewAssignmentsStep from 'features/learning_tracks/components/ReviewAssignmentsStep';
import { dispatchCustomEvent } from 'shared/utils';

const parentModel = {
  store: reactive({
    calendar: { workLoad: {}},
  }),
  assignmentCalendar: {
    calculateWorkLoad: jest.fn(() => true),
  },
};

const learningTrackData = {
  store: reactive({}),
  parentDataStore: parentModel.store,
  parentModel: parentModel,
  state: (step) => 'active',
  groupMenu: {
    buildDataToOpenGroupMenu: jest.fn(() => true),
    getGroupMenuDialogTitle: jest.fn(() => 'dailog title'),
  },
};

const reviewComponentKey = ref(0);
let wrapper;

/**
 * This method gets wrapper for ReviewAssignmentsStep component
 * @return {Wrapper}
 */
function getWrapper() {
  return shallowMount(ReviewAssignmentsStep, {
    global: {
      provide: { learningTrackData, reviewComponentKey },
      stubs: { ReviewAssignments: true },
    },
    props: {
      loadingIconPath: '/images/loading.gif',
    },
    stubs: { GroupMenu: true },
  });
}

/**
 * This method simulates event triggering from given component
 * @param {Wrapper} wrapper - Wrapper for ReviewAssignmentsStep component
 * @param {String} compRef - Vue ref of event triggering component
 * @param {String} eventName - Event name to trigger
 */
async function triggerCompEvent(wrapper, compRef, eventName) {
  const comp = wrapper.findComponent({ ref: compRef });
  await comp.vm.$emit(eventName);
}

describe('ReviewAssignmentsStep', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays ReviewAssignments component', () => {
      expect(wrapper.findComponent({ name: 'ReviewAssignments' }).exists()).toBeTruthy();
    });

    it('does not display GroupMenu Modal', () => {
      expect(wrapper.findComponent({ ref: 'refGroupMenuModal' }).exists()).toBeFalsy();
    });

    it('does not display WarnAboutChanges Modal', () => {
      expect(wrapper.findComponent({ ref: 'refWarnAboutChangesModal' }).exists()).toBeFalsy();
    });
  });

  describe('when event "openGroupMenu" is received on document', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      dispatchCustomEvent({
        name: 'openGroupMenu',
        detail: { date: { name: '01/01/2021' }},
      });
    });

    it('displays GroupMenu Modal', () => {
      expect(wrapper.findComponent({ ref: 'refGroupMenuModal' }).exists()).toBeTruthy();
    });
  });

  describe('when event "assignmentShifted" is received on document', () => {
    beforeEach(() => {
      wrapper = getWrapper();
      dispatchCustomEvent({
        name: 'assignmentShifted',
        detail: {},
      });
    });

    it('sets "pendingWarnAboutChanges" in localStore', () => {
      expect(wrapper.vm.localStore.pendingWarnAboutChanges).toBe(true);
    });
  });

  describe('when GroupMenu Modal closes', () => {
    describe('when flag "pendingWarnAboutChanges" in localStore is false', () => {
      beforeEach(async () => {
        wrapper = getWrapper();
        // Set localStore to show group menu modal initially
        wrapper.vm.localStore.showGroupMenuModal = true;
        wrapper.vm.localStore.pendingWarnAboutChanges = false;
        await wrapper.vm.$nextTick();
        await triggerCompEvent(wrapper, 'refGroupMenuModal', 'close');
      });

      it('does not display WarnAboutChanges Modal', () => {
        expect(wrapper.findComponent({ ref: 'refWarnAboutChangesModal' }).exists()).toBeFalsy();
      });
    });

    describe('when flag "pendingWarnAboutChanges" in localStore is true', () => {
      beforeEach(async () => {
        wrapper = getWrapper();
        // Set localStore to show group menu modal initially
        wrapper.vm.localStore.showGroupMenuModal = true;
        wrapper.vm.localStore.pendingWarnAboutChanges = true;
        await wrapper.vm.$nextTick();
        await triggerCompEvent(wrapper, 'refGroupMenuModal', 'close');
      });

      it('displays WarnAboutChanges Modal', () => {
        expect(wrapper.findComponent({ ref: 'refWarnAboutChangesModal' }).exists()).toBeTruthy();
      });
    });
  });
});
