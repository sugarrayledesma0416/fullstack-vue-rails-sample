import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import DueDatesStep from 'features/learning_tracks/components/DueDatesStep';
import UnitRange from 'features/learning_tracks/models/unit_range';

const DAYS_OF_WEEK = [
  { name: 'Sunday', selected: false, value: 0 },
  { name: 'Monday', selected: true, value: 1 },
  { name: 'Tuesday', selected: false, value: 2 },
  { name: 'Wednesday', selected: false, value: 3 },
  { name: 'Thursday', selected: false, value: 4 },
  { name: 'Friday', selected: false, value: 5 },
  { name: 'Saturday', selected: false, value: 6 },
];

const parentModel = {
  store: reactive({
    daysOfWeek: DAYS_OF_WEEK,
    disableAllControls: undefined,
    learningTracksConfig: { chooseTrack: true },
    loadingLearningTracks: false,
    respectDueDates: false,
    unitRange: new UnitRange(),
    usingPredefinedTrack: false,
  }),
  vistaOnlineLearning: false,
};

const learningTrackData = {
  store: reactive({
    allowMultipleLessonsOnDates: false,
    breakGroupAcrossDates: false,
    breakStrandAcrossDates: false,
    expandDueDatesStep: true,
  }),
  parentDataStore: parentModel.store,
  parentModel: parentModel,
  state: (step) => 'active',
};

let wrapper;

/**
 * This method gets wrapper for DueDatesStep component
 * @return {Wrapper}
 */
const getWrapper = () => {
  return mount(DueDatesStep, {
    global: {
      provide: {
        learningTrackData,
        config: { instAdmin: false },
      },
    },
  });
};

/**
 * This method returns whether step content in child component 'Expandable' is
 * in expanded state based on its 'expand' vue prop value.
 * @param {Wrapper} wrapper - wrapper for DueDatesStep component
 * @return {boolean}
 */
function isStepContentExpanded(wrapper) {
  const childComp = wrapper.findComponent({ ref: 'ref-expandable-step-content' });
  return childComp.componentVM.expand;
}

/**
 * This method returns whether component 'Expandable' corresponding to Advanced Setting
 * is in expanded state based on its 'expand' vue prop value.
 * @param {Wrapper} wrapper - wrapper for DueDatesStep component
 * @return {boolean}
 */
function isAdvancedSettingsExpanded(wrapper) {
  const childComp = wrapper.findComponent({ ref: 'ref-expandable-advanced-settings' });
  return childComp.componentVM.expand;
}

/**
 * This method returns whether checkbox wrapped in component 'VhlCheckbox' is disabled
 * based on its 'disabled' vue prop value.
 * @param {Wrapper} wrapper - wrapper for DueDatesStep component
 * @param {string} checkBoxRef - Vue ref of VhlCheckbox component
 * @return {boolean}
 */
function isCheckboxDisabled(wrapper, checkBoxRef) {
  const childComp = wrapper.findComponent({ ref: checkBoxRef });
  return childComp.componentVM.disabled;
}

/**
 * This method returns whether checkbox wrapped in component 'VhlCheckbox' is checked
 * based on its 'checked' vue prop value.
 * @param {Wrapper} wrapper - wrapper for DueDatesStep component
 * @param {string} checkBoxRef - Vue ref of VhlCheckbox component
 * @return {boolean}
 */
function isCheckboxChecked(wrapper, checkBoxRef) {
  const childComp = wrapper.findComponent({ ref: checkBoxRef });
  return childComp.componentVM.checked;
}

/**
 * This method triggers checked event from VhlCheckbox component with detail
 * whether its set checked or unchecked.
 * @async
 * @param {Wrapper} wrapper - wrapper for DueDatesStep component
 * @param {string} checkBoxRef - Vue ref of VhlCheckbox component
 * @param {boolean} isChecked - Event detail whether its set checked or unchecked
 */
async function triggerCheckboxCompEvent(wrapper, checkBoxRef, isChecked) {
  const childComp = wrapper.findComponent({ ref: checkBoxRef });
  await childComp.componentVM.$emit('update:checked', isChecked);
}

describe('DueDatesStep', () => {
  describe('onMounted', () => {
    describe('when "expandDueDatesStep" flag is false in store', () => {
      beforeEach(() => {
        learningTrackData.store.expandDueDatesStep = false;
        wrapper = getWrapper();
      });

      it('displays "Step 3: Set assignment due dates and settings" text on header', () => {
        expect(wrapper.get('.test-due-dates-step-header').text()).toBe(
          'Step 3: Set assignment due dates and settings'
        );
      });

      it('contains provided step content in the slot of Expandable component', () => {
        expect(wrapper.find('.test-due-dates-step-content').exists()).toBeTruthy();
      });

      it('has collapsed content', () => {
        expect(isStepContentExpanded(wrapper)).toBeFalsy();
      });
    });

    describe('when "expandDueDatesStep" flag is true in store', () => {
      beforeEach(() => {
        learningTrackData.store.expandDueDatesStep = true;
        wrapper = getWrapper();
      });

      it('displays "Step 3: Set assignment due dates and settings" text on header', () => {
        expect(wrapper.get('.test-due-dates-step-header').text()).toBe(
          'Step 3: Set assignment due dates and settings'
        );
      });

      it('contains provided step content in the slot of Expandable component', () => {
        expect(wrapper.find('.test-due-dates-step-content').exists()).toBeTruthy();
      });

      it('has expanded content', () => {
        expect(isStepContentExpanded(wrapper)).toBeTruthy();
      });

      it('has collapsed Assignment Distribution Options', () => {
        expect(isAdvancedSettingsExpanded(wrapper)).toBeFalsy();
      });

      it('displays "Show Options" link to toggle due dates options', () => {
        expect(wrapper.get('.test-toggle-due-dates-options').text()).toBe('Show Options');
      });

      it('displays unchecked checkbox for Sunday', () => {
        expect(isCheckboxChecked(wrapper, 'ref-due-day-0')).toBeFalsy();
      });

      it('displays checked checkbox for Monday', () => {
        expect(isCheckboxChecked(wrapper, 'ref-due-day-1')).toBeTruthy();
      });

      it('displays checkbox "Keep assignments grouped as they were in my existing course"', () => {
        expect(wrapper.findComponent({ ref: 'ref-respect-due-dates' }).exists()).toBeTruthy();
      });

      it('does not display ModalComponent', () => {
        expect(wrapper.findComponent({ name: 'ModalComponent' }).exists()).toBeFalsy();
      });

      it('displays 2 Expandable components', () => {
        expect(wrapper.findAllComponents({ name: 'Expandable' }).length).toBe(2);
      });
    });

    describe('when "usingPredefinedTrack" flag is true in parent store', () => {
      beforeEach(() => {
        parentModel.store.usingPredefinedTrack = true;
        wrapper = getWrapper();
      });

      it('does not display checkbox "Keep assignments grouped as they were in my existing course"',
        () => {
          expect(wrapper.findComponent({ ref: 'ref-respect-due-dates' }).exists()).toBeFalsy();
        });
    });
  });

  describe('when learning tracks are loading', () => {
    beforeEach(() => {
      parentModel.store.loadingLearningTracks = true;
      wrapper = getWrapper();
    });

    it('displays loading spinner', () => {
      expect(
        wrapper.get('.test-loading-spinner-tracks').isVisible()
      ).toBeTruthy();
    });
  });

  describe('when click on "More information" button', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-more-information').trigger('click');
    });

    it('displays ModalComponent', () => {
      expect(wrapper.findComponent({ name: 'ModalComponent' }).exists()).toBeTruthy();
    });
  });

  describe('when click on "Show Options" link to toggle due dates options', () => {
    beforeEach(async () => {
      learningTrackData.store.expandDueDatesStep = true;
      wrapper = getWrapper();
      await wrapper.get('.test-toggle-due-dates-options').trigger('click');
    });

    it('shows Hide Options link', () => {
      expect(wrapper.get('.test-toggle-due-dates-options').text()).toBe('Hide Options');
    });

    it('has expanded Assignment Distribution Options', () => {
      expect(isAdvancedSettingsExpanded(wrapper)).toBeTruthy();
    });

    it('displays active checkbox "Allow assignments from more than one lesson to ' +
      'occur on the same due date."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-multiple-lessons-on-same-date')).toBeFalsy();
    });

    it('displays active checkbox "Allow assignments from one section within a lesson ' +
      'to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-strand-across-dates')).toBeFalsy();
    });

    it('displays disabled checkbox "Allow assignments from one learning group within ' +
      'a section of a lesson to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-group-across-dates')).toBeTruthy();
    });
  });

  describe('when checkbox "Allow assignments from one section within a lesson ' +
    'to be split across multiple due dates." is set checked', () => {
    beforeEach(async () => {
      // Checkboxes corresponding to respectDueDates & breakStrandAcrossDates are set unchecked
      learningTrackData.parentDataStore.respectDueDates = false;
      learningTrackData.store.breakStrandAcrossDates = false;
      wrapper = getWrapper();
      const isChecked = true;
      await triggerCheckboxCompEvent(wrapper, 'ref-break-strand-across-dates', isChecked);
    });

    it('updates "breakStrandAcrossDates" property in data store', () => {
      expect(learningTrackData.store.breakStrandAcrossDates).toBe(true);
    });

    it('displays active checkbox "Allow assignments from one learning group within ' +
      'a section of a lesson to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-group-across-dates')).toBeFalsy();
    });
  });

  describe('when checkbox "Allow assignments from one section within a lesson ' +
    'to be split across multiple due dates." is set unchecked', () => {
    beforeEach(async () => {
      // Checkboxes corresponding to respectDueDates is set unchecked &
      // corresponding to breakStrandAcrossDates is set checked
      learningTrackData.parentDataStore.respectDueDates = false;
      learningTrackData.store.breakStrandAcrossDates = true;
      wrapper = getWrapper();
      const isChecked = false;
      await triggerCheckboxCompEvent(wrapper, 'ref-break-strand-across-dates', isChecked);
    });

    it('updates "breakStrandAcrossDates" property in data store', () => {
      expect(learningTrackData.store.breakStrandAcrossDates).toBe(false);
    });

    it('displays disabled checkbox "Allow assignments from one learning group within ' +
      'a section of a lesson to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-group-across-dates')).toBeTruthy();
    });
  });

  describe('when checkbox "Keep assignments grouped as they were in my existing course" ' +
    'is set checked', () => {
    beforeEach(async () => {
      // Checkbox corresponding to respectDueDates is set unchecked
      learningTrackData.parentDataStore.respectDueDates = false;
      parentModel.store.usingPredefinedTrack = false;
      wrapper = getWrapper();
      const isChecked = true;
      await triggerCheckboxCompEvent(wrapper, 'ref-respect-due-dates', isChecked);
    });

    it('updates "respectDueDates" property in parent data store', () => {
      expect(learningTrackData.parentDataStore.respectDueDates).toBe(true);
    });

    it('displays disabled checkbox "Allow assignments from more than one lesson to ' +
      'occur on the same due date."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-multiple-lessons-on-same-date')).toBeTruthy();
    });

    it('displays disabled checkbox "Allow assignments from one section within a lesson ' +
      'to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-strand-across-dates')).toBeTruthy();
    });

    it('displays disabled checkbox "Allow assignments from one learning group within ' +
      'a section of a lesson to be split across multiple due dates."', () => {
      expect(isCheckboxDisabled(wrapper, 'ref-break-group-across-dates')).toBeTruthy();
    });
  });
});
