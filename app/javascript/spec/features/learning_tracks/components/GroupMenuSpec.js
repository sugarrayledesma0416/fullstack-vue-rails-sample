import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import GroupMenu from 'features/learning_tracks/components/GroupMenu';
import AssignmentGroup from 'features/learning_tracks/models/assignment_group';

const activityGroup1 = new AssignmentGroup('group name 1', 'strand 1', 'lesson 1');
activityGroup1.activities = [
  {
    activity_type: 'Multiple choice',
    id: 1,
    lesson_name: 'lesson 1',
    minutes_to_complete: '4',
    strand_name: 'strand 1',
    title: 'activity 1',
  },
  {
    activity_type: 'Multiple choice',
    id: 2,
    lesson_name: 'lesson 1',
    minutes_to_complete: '5',
    strand_name: 'strand 1',
    title: 'activity 2',
  },
];
const activityGroup2 = new AssignmentGroup('group name 2', 'strand 1', 'lesson 1');
activityGroup2.activities = [
  {
    activity_type: 'Multiple choice',
    id: 3,
    lesson_name: 'lesson 1',
    minutes_to_complete: '6',
    strand_name: 'strand 1',
    title: 'activity 3',
  },
];

const strandGroups = [
  {
    groups: [
      activityGroup1,
      activityGroup2,
    ],
  },
];

const parentModel = { store: reactive({}) };

const learningTrackData = {
  store: reactive({}),
  parentDataStore: parentModel.store,
  parentModel: parentModel,
  groupMenu: {
    deleteActivity: jest.fn(()=> true),
    hoursForStrandGroup: jest.fn(()=> true),
    moveFirstActivity: jest.fn(()=> true),
    moveLastActivity: jest.fn(()=> true),
    noActivities: false,
    strandGroups: strandGroups,
    store: {
      showFirst: true,
      showLast: true,
      strandGroupPosition: 0,
    },
  },
};

let wrapper;

/**
 * This method gets wrapper for GroupMenu component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(GroupMenu, {
    global: {
      provide: { learningTrackData },
    },
  });
}

describe('GroupMenu', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays group activity table', () => {
      expect(wrapper.find('.test-group-activities-table').exists()).toBeTruthy();
    });

    it('does not display no activities message', () => {
      expect(wrapper.find('.test-no-activities').exists()).toBeFalsy();
    });

    it('displays 2 rows showing group names in the activities table', () => {
      expect(wrapper.findAll('.test-activity-group-name')).toHaveLength(2);
    });

    it('displays 3 rows showing activity details in the activities table', () => {
      expect(wrapper.findAll('.test-activity-row')).toHaveLength(3);
    });

    it('displays 3 links to take to activity detail in the activities table', () => {
      expect(wrapper.findAll('.test-activity-link')).toHaveLength(3);
    });

    it('displays 3 links to delete activity in the activities table', () => {
      expect(wrapper.findAll('.test-delete-activity')).toHaveLength(3);
    });

    it('displays first group name as "group name 1" in the activities table', () => {
      expect(wrapper.find('.test-activity-group-name').text()).toBe('group name 1');
    });

    it('displays Activity Type value as "Multiple choice" for first activity', () => {
      expect(wrapper.find('.test-activity-type').text()).toBe('Multiple choice');
    });

    it('displays Est.Time to Complete as "4 minutes" for first activity', () => {
      expect(wrapper.find('.test-activity-minutes').text()).toBe('4 minutes');
    });
  });

  describe('when click on Delete button', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      // click on first Delete link
      await wrapper.find('.test-delete-activity').trigger('click');
    });

    it('it calls deleteActivity method in learningTrackData', () => {
      expect(learningTrackData.groupMenu.deleteActivity).toHaveBeenCalled();
    });
  });

  describe('when click on "Move first activity to previous due date" link', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.find('.test-move-first-activity').trigger('click');
    });

    it('calls moveFirstActivity method in learningTrackData', () => {
      expect(learningTrackData.groupMenu.moveFirstActivity).toHaveBeenCalled();
    });
  });

  describe('when click on "Move last activity to next due date" link', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.find('.test-move-last-activity').trigger('click');
    });

    it('calls moveLastActivity method in learningTrackData', () => {
      expect(learningTrackData.groupMenu.moveLastActivity).toHaveBeenCalled();
    });
  });

  describe('when noActivities flag is true in learningTrackData', () => {
    beforeEach(() => {
      learningTrackData.groupMenu.store.noActivities = true;
      wrapper = getWrapper();
    });

    it('does not display group activity table', () => {
      expect(wrapper.find('.test-group-activities-table').exists()).toBeFalsy();
    });

    it('displays no activities message', () => {
      expect(wrapper.find('.test-no-activities').exists()).toBeTruthy();
    });
  });
});
