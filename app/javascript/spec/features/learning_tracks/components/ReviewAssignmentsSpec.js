import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import LearningTrackDataStore from 'features/learning_tracks/learning_track_data_store';
import ReviewAssignments from 'features/learning_tracks/components/ReviewAssignments';
import UnitRange from 'features/learning_tracks/models/unit_range';

jest.mock('features/learning_tracks/directives/work_load_graph', () => {
  return jest.fn().mockImplementation(() => jest.fn());
});

const dueDates = [{
  dayOfWeek: 'Su',
  label: 'Aug 01',
  locked: true,
  name: '08/01/2021',
}, {
  dayOfWeek: 'Mo',
  label: 'Aug 02',
  locked: false,
  name: '08/02/2021',
}];

const parentModel = {
  store: reactive({
    allDueDates: [],
    learningTracksConfig: { chooseTrack: true },
    unitRange: new UnitRange(),
    calendar: { workLoad: {}},
  }),
};

const mockLearningTracks = {
  'activities': {
    '42217': { 'id': 42217 },
  },
};

// Class to mock moment js implementation for the test cases
class MomentCls {
  isAfter() {}
}

/**
 * Get instance of MomentCls
 * @return {MomentCls} - Instance of MomentCls
 */
function momentFn() {
  return new MomentCls();
}

// Mock moment on window object and allow for initialization of moment() without 'new'
window.moment = momentFn;

const learningTrackData = new LearningTrackDataStore(parentModel);

let wrapper;

const getWrapper = () => {
  return mount(ReviewAssignments, {
    global: {
      provide: { learningTrackData },
      stubs: { DueDateGraphComponent: true },
    },
    props: {
      loadingIconPath: '/images/loading.gif',
    },
  });
};

describe('ReviewAssignments', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      parentModel.store.unitRange = new UnitRange(1, 2);
      parentModel.store.calendar.workLoad.activityCount = 20;
      parentModel.store.calendar.workLoad.avg = 120.00;
      learningTrackData.store.learningTracks = mockLearningTracks;
      learningTrackData.store.expandReviewAssignmentsStep = true;
      wrapper = getWrapper();
    });

    it('displays average number of activities per lesson for a track', () => {
      expect(wrapper.get('.test-activities-per-lesson').text()).toBe('10');
    });

    it('displays average assignments per lesson', () => {
      expect(wrapper.get('.test-assignments-per-lesson').text()).toBe('2.0');
    });

    it('displays the work load graph', () => {
      expect(wrapper.find('.test-work-load-graph').exists()).toBeTruthy();
    });
  });

  describe('when learning tracks are loading', () => {
    beforeEach(() => {
      parentModel.store.loadingLearningTracks = true;
      wrapper = getWrapper();
    });

    it('displays loading spinner.', () => {
      expect(
        wrapper.get('.test-loading-spinner').isVisible()
      ).toBeTruthy();
    });
  });

  describe('when learning tracks are loaded', () => {
    beforeEach(() => {
      parentModel.store.loadingLearningTracks = false;
      wrapper = getWrapper();
    });

    it('does not displays loading spinner.', () => {
      expect(
        wrapper.get('.test-loading-spinner').isVisible()
      ).toBeFalsy();
    });
  });

  describe('when due dates are loaded', () => {
    let dueDateElms;
    beforeEach(() => {
      parentModel.store.allDueDates = dueDates;
      wrapper = getWrapper();
      dueDateElms = wrapper.findAll('.test-due-dates');
    });

    it('displays label for each due date.', () => {
      dueDateElms.forEach((dueDateElm, index) => {
        expect(
          dueDateElm.get('.test-due-date-label').text()
        ).toContain(`${dueDates[index].dayOfWeek} ${dueDates[index].label}`);
      });
    });

    it('displays a lock icon for the locked due date and ' +
       'unlock icon for unlocked due date', () => {
      dueDateElms.forEach((dueDateElm, index) => {
        if (dueDates[index].locked) {
          expect(dueDateElm.find('.test-locked-due-date').exists()).toBeTruthy();
          expect(dueDateElm.find('.test-unlocked-due-date').exists()).toBeFalsy();
        } else {
          expect(dueDateElm.find('.test-locked-due-date').exists()).toBeFalsy();
          expect(dueDateElm.find('.test-unlocked-due-date').exists()).toBeTruthy();
        }
      });
    });

    it('displays disabled check box for locked due date', () => {
      expect(wrapper.find('.test-due-date-cb-0').element).toBeDisabled();
      expect(wrapper.find('.test-due-date-cb-1').element).not.toBeDisabled();
    });
  });

  describe('showExternalItems',
    () => {
      describe('when there are external items',
        () => {
          beforeEach(() => {
            parentModel.store.externalItems = [{ id: 1, day_id: '2022-01-01', name: 'A' }];
            wrapper = getWrapper();
          });

          it('displays the external items list', () => {
            expect(wrapper.find('.test-external-items').exists()).toBeTruthy();
          });
        }
      );

      describe('when there are not external items',
        () => {
          beforeEach(() => {
            parentModel.store.externalItems = null;
            wrapper = getWrapper();
          });

          it('does not display the external items list', () => {
            expect(wrapper.find('.test-external-items').exists()).toBeFalsy();
          });
        }
      );
    }
  );
});
