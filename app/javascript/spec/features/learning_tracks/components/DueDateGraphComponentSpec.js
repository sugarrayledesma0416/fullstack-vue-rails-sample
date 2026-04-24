import { mount } from '@vue/test-utils';
import DueDateGraphComponent from 'features/learning_tracks/components/DueDateGraphComponent';

jest.mock('features/learning_tracks/models/due_date_graph', () => {
  return jest.fn().mockImplementation(() => {
    return {
      drawGraph: () => {},
    };
  });
});

const calendarObj = {
  workLoad: {
    activityCount: 354,
    avg: 1555.5,
    max: 1564,
    min: 1547,
  },
  calendar: {
    '09/12/2021': [],
  },
};

const date = {
  dayOfWeek: 'Su',
  label: 'Aug 01',
  locked: true,
  name: '09/12/2021',
};

const getWrapper = () => {
  return mount(DueDateGraphComponent, {
    props: {
      calendarObj,
      date,
      unitLabel: 'Lesson',
    },
  });
};

const groupInfoData = {
  strandHeading: 'Footnova',
  activityCount: 6,
  totalMinutes: 0.8,
};

let wrapper;

describe('DueDateGraphComponent', () => {
  describe('onMounted', () => {
    it('does not display the group Info Elm', () => {
      wrapper = getWrapper();
      expect(wrapper.find('.test-group-info-elm').isVisible()).toBeFalsy();
    });

    it('renders without errors with an empty calendar prop', () => {
      wrapper = mount(DueDateGraphComponent, {
        props: {
          calendarObj: {},
          date,
          unitLabel: 'Lesson',
        },
      })
      expect(wrapper.find('.due-date-graph-container').isVisible()).toBe(true);
    });
  });

  describe('when showGroupInfoElm is true', () => {
    beforeEach(() => {
      wrapper = getWrapper();
      wrapper.vm.localstore.showGroupInfoElm = true;
      wrapper.vm.localstore.groupInfoData = groupInfoData;
    });

    it('does not displays the group Info Elm', () => {
      expect(wrapper.find('.test-group-info-elm').isVisible()).toBeTruthy();
    });

    it('displays the strand heading', () => {
      expect(wrapper.find('.test-group-info-heading').text()).toBe('Footnova');
    });

    it('displays the activity count', () => {
      expect(wrapper.find('.test-activity-count').text()).toBe('Number of activities: 6');
    });

    it('displays the average completion time', () => {
      expect(wrapper.find('.test-average-completion-time').text()).toBe(
        'Average Completion Time: 0.8 hours'
      );
    });
  });
});
