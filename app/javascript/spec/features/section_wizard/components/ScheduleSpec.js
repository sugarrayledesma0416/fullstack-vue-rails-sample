import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Schedule from 'features/section_wizard/components/Schedule';

let wrapper;

const section = {
  dueTimeAmpm: 'PM',
  dueTimeHour: '11',
  dueTimeMinute: '59',
  hourOptions: ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  minutesOptions: ['00', '15', '30', '45', '59'],
  ampmOptions: ['AM', 'PM'],
  timeZone: 'Eastern Time (US & Canada)',
};

const props = {
  remainingTimeZones: [
    ['(GMT-11:00) American Samoa', 'American Samoa'],
    ['(GMT-08:00) Tijuana', 'Tijuana'],
  ],
  timeZones: [
    ['(GMT-05:00) Eastern Time (US & Canada)', 'Eastern Time (US & Canada)'],
    ['(GMT-06:00) Central Time (US & Canada)', 'Central Time (US & Canada)'],
    ['(GMT-07:00) Arizona', 'Arizona'],
  ],
};

/**
 * This method gets wrapper for Schedule component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Schedule, {
    global: {
      provide: {
        datastore: reactive({ section }),
      },
    },
    props,
  });
}

async function changeSelectValue(selectTag, value) {
  selectTag.element.value = value;
  await selectTag.trigger('change');
}

describe('Schedule', () => {
  describe('when Schedule is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays due time hour as "11"', () => {
      expect(wrapper.get('.test-due-time-hour').element.value).toBe('11');
    });

    it('displays due time min as "59"', () => {
      expect(wrapper.get('.test-due-time-min').element.value).toBe('59');
    });

    it('displays due time ampm as "PM"', () => {
      expect(wrapper.get('.test-due-time-ampm').element.value).toBe('PM');
    });

    it('displays default time zone as "Eastern Time (US & Canada)"', () => {
      expect(
        wrapper.get('.test-section-time-zone').element.value
      ).toBe('Eastern Time (US & Canada)');
    });
  });

  describe('when due time hour is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await changeSelectValue(
        wrapper.get('.test-due-time-hour'),
        '2'
      );
    });

    it('displays the changed due time hour of "2"', () => {
      expect(wrapper.get('.test-due-time-hour').element.value).toBe('2');
    });
  });

  describe('when due time min is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await changeSelectValue(
        wrapper.get('.test-due-time-min'),
        '30'
      );
    });

    it('displays the changed due time min of "30"', () => {
      expect(wrapper.get('.test-due-time-min').element.value).toBe('30');
    });
  });

  describe('when due time ampm is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await changeSelectValue(
        wrapper.get('.test-due-time-ampm'),
        'AM'
      );
    });

    it('displays the changed due time ampm of "AM"', () => {
      expect(wrapper.get('.test-due-time-ampm').element.value).toBe('AM');
    });
  });

  describe('when time zone is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await changeSelectValue(
        wrapper.get('.test-section-time-zone'),
        'Arizona'
      );
    });

    it('displays the changed time zone of "Arizona"', () => {
      expect(wrapper.get('.test-section-time-zone').element.value).toBe('Arizona');
    });
  });
});
