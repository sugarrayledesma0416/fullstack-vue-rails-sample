import { reactive } from 'vue';
import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import AssignmentGroup from 'features/learning_tracks/models/assignment_group';
import GroupMenu from 'features/learning_tracks/models/group_menu';
import { groupByStrand } from 'features/learning_tracks/models/activity_distributor';
import { firstInArray, lastInArray } from 'shared/utils';

const assignmentCalendar = new AssignmentCalendar();
const parentModel = {
  store: reactive({
    calendar: undefined,
  }),
  assignmentCalendar,
};

let group1;
let group2;
let group3;
let group4;
let group5;
let group6;
let group7;
let group8;
let group9;

/**
 * Setup test data. Build Assignment groups, calendar, assignmentCalendar etc in parentModel.
 */
function prepareTestData() {
  group1 = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
  group1.activities = [
    { id: 1, name: 'activity 1', strand_name: 'strand 1', lesson_name: 'lesson 1' },
    { id: 2, name: 'activity 2', strand_name: 'strand 1', lesson_name: 'lesson 1' },
  ];
  group2 = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
  group2.activities = [
    { id: 4, name: 'activity 4', strand_name: 'strand 1', lesson_name: 'lesson 1' },
    { id: 5, name: 'activity 5', strand_name: 'strand 1', lesson_name: 'lesson 1' },
  ];
  group3 = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
  group3.activities = [
    { id: 7, name: 'activity 7', strand_name: 'strand 1', lesson_name: 'lesson 1' },
    { id: 8, name: 'activity 8', strand_name: 'strand 1', lesson_name: 'lesson 1' },
  ];
  group4 = new AssignmentGroup('learn', 'strand 2', 'lesson 1');
  group4.activities = [
    { id: 10, name: 'activity 10', strand_name: 'strand 2', lesson_name: 'lesson 1' },
    { id: 11, name: 'activity 11', strand_name: 'strand 2', lesson_name: 'lesson 1' },
  ];
  group5 = new AssignmentGroup('learn', 'strand 2', 'lesson 1');
  group5.activities = [
    { id: 13, name: 'activity 13', strand_name: 'strand 2', lesson_name: 'lesson 1' },
    { id: 14, name: 'activity 14', strand_name: 'strand 2', lesson_name: 'lesson 1' },
  ];
  group6 = new AssignmentGroup('learn', 'strand 2', 'lesson 1');
  group6.activities = [
    { id: 16, name: 'activity 16', strand_name: 'strand 2', lesson_name: 'lesson 1' },
    { id: 17, name: 'activity 17', strand_name: 'strand 2', lesson_name: 'lesson 1' },
  ];
  group7 = new AssignmentGroup('learn', 'strand 3', 'lesson 1');
  group7.activities = [
    { id: 19, name: 'activity 19', strand_name: 'strand 3', lesson_name: 'lesson 1' },
    { id: 20, name: 'activity 20', strand_name: 'strand 3', lesson_name: 'lesson 1' },
  ];
  group8 = new AssignmentGroup('learn', 'strand 3', 'lesson 1');
  group8.activities = [
    { id: 22, name: 'activity 22', strand_name: 'strand 3', lesson_name: 'lesson 1' },
    { id: 23, name: 'activity 23', strand_name: 'strand 3', lesson_name: 'lesson 1' },
  ];
  group9 = new AssignmentGroup('learn', 'strand 3', 'lesson 1');
  group9.activities = [
    { id: 25, name: 'activity 25', strand_name: 'strand 3', lesson_name: 'lesson 1' },
    { id: 26, name: 'activity 26', strand_name: 'strand 3', lesson_name: 'lesson 1' },
  ];

  parentModel.assignmentCalendar.dueDates = [
    { name: '1/1/2011' },
    { name: '1/2/2011' },
    { name: '1/3/2011' },
  ];

  parentModel.store.calendar = {};
  parentModel.store.calendar.calendar = {
    '1/1/2011': [group1, group2, group3],
    '1/2/2011': [group4, group5, group6],
    '1/3/2011': [group7, group8, group9],
  };
}

/**
 * Return last AssignmentGroup corresponding to given due date
 * @param {string} dateStr - Due date string
 * @return {AssignmentGroup}
 */
function lastGroupInDueDate(dateStr) {
  return lastInArray(parentModel.store.calendar.calendar[dateStr]);
}

/**
 * Return first AssignmentGroup corresponding to given due date
 * @param {string} dateStr - Due date string
 * @return {AssignmentGroup}
 */
function firstGroupInDueDate(dateStr) {
  return firstInArray(parentModel.store.calendar.calendar[dateStr]);
}

/**
 * Return AssignmentGroups corresponding to given due date
 * @param {string} dateStr - Due date string
 * @return {Array.<AssignmentGroup>}
 */
function groupsInDueDate(dateStr) {
  return parentModel.store.calendar.calendar[dateStr];
}

/**
 * Update due date and strandAssignmentGroups in test data
 * @param {string} dateStr - Due date string
 */
function updateDateAndGroupStrandsInData(dateStr) {
  groupMenuInstance.store.date = { name: dateStr };
  groupMenuInstance.store.strandAssignmentGroups = groupByStrand(
    groupsInDueDate(groupMenuInstance.store.date.name)
  );
}

let mockDispatchEvent;
let groupMenuInstance;
describe('GroupMenu', function() {
  beforeEach(function() {
    prepareTestData();
    groupMenuInstance = new GroupMenu(parentModel);
    const detail = { detail: { position: 0, date: { name: '1/2/2011' }}};
    groupMenuInstance.buildDataToOpenGroupMenu(parentModel.store.calendar.calendar, detail);
  });

  describe('#getGroupMenuDialogTitle', function() {
    it('sets the title to be the lesson and strand of the first activity shown', function() {
      expect(
        groupMenuInstance.getGroupMenuDialogTitle()
      ).toEqual('Assignments for 1/2/2011, lesson 1 | strand 2');
    });
  });

  describe('#moveFirstActivity', function() {
    it('emits that an assignment has been shifted', function() {
      jest.spyOn(global, 'CustomEvent').mockImplementation((name, detail) => ({ name, detail }));
      mockDispatchEvent = jest.spyOn(document, 'dispatchEvent').mockImplementation(
        () => true
      );
      groupMenuInstance.moveFirstActivity();

      expect(mockDispatchEvent).toHaveBeenCalledWith({
        name: 'assignmentShifted',
        detail: { detail: {}},
      });
    });

    describe('when target group has the same name and strand as current group', function() {
      beforeEach(function() {
        group4.strand = 'strand 1';
        groupMenuInstance.moveFirstActivity();
      });

      it('moves the activity from current due date', function() {
        expect(firstGroupInDueDate('1/2/2011').activities.length).toEqual(1);
      });

      it('moves the first activity to the previous due date', function() {
        expect(
          lastInArray(parentModel.store.calendar.calendar['1/1/2011']).activities.length
        ).toEqual(3);
      });
    });

    describe('when target group does not have the same name or strand', function() {
      beforeEach(function() {
        group4.name = 'interact';
        groupMenuInstance.moveFirstActivity();
      });

      it('moves the activity from current due date', function() {
        expect(firstGroupInDueDate('1/2/2011').activities.length).toEqual(1);
      });

      it('creates a new assignment group with the activity on previous due date', function() {
        const activityId = lastGroupInDueDate('1/1/2011').activities[0].id;
        const { name: groupName, strand: groupStrand } = lastGroupInDueDate('1/1/2011');

        expect(lastGroupInDueDate('1/1/2011').activities.length).toEqual(1);
        expect({ activityId, groupName, groupStrand }).toEqual(
          { activityId: 10, groupName: 'interact', groupStrand: 'strand 2' }
        );
      });
    });

    describe('when target group is empty', function() {
      beforeEach(function() {
        parentModel.store.calendar.calendar['1/1/2011'] = [];
        groupMenuInstance.moveFirstActivity();
      });

      it('moves the activity from current due date', function() {
        expect(firstGroupInDueDate('1/2/2011').activities.length).toEqual(1);
      });

      it('creates a new assignment group to be the target group on the previous due date',
        function() {
          const {
            id, strand_name: strandName, lesson_name: lessonName,
          } = firstGroupInDueDate('1/1/2011').activities[0];

          expect(firstGroupInDueDate('1/1/2011').activities.length).toEqual(1);
          expect({ id, strandName, lessonName }).toEqual(
            { id: 10, strandName: 'strand 2', lessonName: 'lesson 1' }
          );
        }
      );
    });
  });

  describe('#moveLastActivity', function() {
    it('emits that an assignment has been shifted', function() {
      jest.spyOn(global, 'CustomEvent').mockImplementation((name, detail) => ({ name, detail }));
      mockDispatchEvent = jest.spyOn(document, 'dispatchEvent').mockImplementation(
        () => true
      );
      groupMenuInstance.moveLastActivity();

      expect(mockDispatchEvent).toHaveBeenCalledWith({
        name: 'assignmentShifted',
        detail: { detail: {}},
      });
    });

    describe('when target group has the same name and strand as current group', function() {
      beforeEach(function() {
        group6.strand = 'strand 3';
        groupMenuInstance.moveLastActivity();
      });

      it('moves the activity from current due date', function() {
        expect(lastGroupInDueDate('1/2/2011').activities.length).toEqual(1);
      });

      it('moves the last activity to the next due date', function() {
        expect(firstGroupInDueDate('1/3/2011').activities.length).toEqual(3);
      });
    });

    describe('when target group does not have the same name or strand', function() {
      beforeEach(function() {
        group6.name = 'interact';
        groupMenuInstance.moveLastActivity();
      });

      it('moves the activity from current due date', function() {
        expect(lastGroupInDueDate('1/2/2011').activities.length).toEqual(1);
      });

      it('creates a new assignment group with the activity', function() {
        const activityId = firstGroupInDueDate('1/3/2011').activities[0].id;
        const { name: groupName, strand: groupStrand } = firstGroupInDueDate('1/3/2011');

        expect(firstGroupInDueDate('1/3/2011').activities.length).toEqual(1);
        expect({ activityId, groupName, groupStrand }).toEqual(
          { activityId: 17, groupName: 'interact', groupStrand: 'strand 2' }
        );
      });
    });
  });

  describe('#hoursForStrandGroup', function() {
    it('calculates the number of hours for a strand group', function() {
      group4.totalMinutes = 60;
      group5.totalMinutes = 60;
      group6.totalMinutes = 61;

      expect(groupMenuInstance.hoursForStrandGroup()).toEqual('3.0');
    });
  });

  describe('#deleteActivity', function() {
    it('delete the activity specified by the index in the selected group', function() {
      groupMenuInstance.deleteActivity(0, 1);

      expect(firstGroupInDueDate('1/2/2011').activities).toEqual([
        { id: 10, name: 'activity 10', strand_name: 'strand 2', lesson_name: 'lesson 1' },
      ]);
    });

    it('emits that an assignment has been shifted', function() {
      jest.spyOn(global, 'CustomEvent').mockImplementation((name, detail) => ({ name, detail }));
      mockDispatchEvent = jest.spyOn(document, 'dispatchEvent').mockImplementation(
        () => true
      );
      groupMenuInstance.deleteActivity(0);
      expect(mockDispatchEvent).toHaveBeenCalledWith({
        name: 'assignmentShifted',
        detail: { detail: {}},
      });
    });
  });

  describe('#displayMoveButtons', function() {
    describe('when an assignment group is first', function() {
      describe('when it is in the first due date', function() {
        it('does not show a button to move it', function() {
          updateDateAndGroupStrandsInData('1/1/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showFirst).toBe(false);
        });
      });

      describe('when it is not in the first due date', function() {
        it('shows a button to move it', function() {
          updateDateAndGroupStrandsInData('1/2/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showFirst).toBe(true);
        });
      });

      describe('when the previous date is locked', function() {
        it('does not show a button to move the first activity', function() {
          firstInArray(assignmentCalendar.dueDates).locked = true;
          updateDateAndGroupStrandsInData('1/2/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showFirst).toBe(false);
        });
      });
    });

    describe('when an assignment group is last', function() {
      describe('when it is in the last due date', function() {
        it('does not show a button to move it', function() {
          updateDateAndGroupStrandsInData('1/3/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showLast).toBe(false);
        });
      });

      describe('when it is not in the last due date', function() {
        it('shows a button to move it', function() {
          updateDateAndGroupStrandsInData('1/2/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showLast).toBe(true);
        });
      });

      describe('when the next date is locked', function() {
        it('does not show a button to move the last activity', function() {
          lastInArray(assignmentCalendar.dueDates).locked = true;
          updateDateAndGroupStrandsInData('1/2/2011');
          groupMenuInstance.displayMoveButtons();

          expect(groupMenuInstance.store.showLast).toBe(false);
        });
      });
    });

    describe('when an assignment group no longer has activities', function() {
      it('does not display either button', function() {
        group4.activities = [];
        parentModel.store.calendar.calendar['1/2/2011'] = [group4];
        updateDateAndGroupStrandsInData('1/2/2011');
        groupMenuInstance.displayMoveButtons();

        expect(groupMenuInstance.store.showFirst).toBe(false);
        expect(groupMenuInstance.store.showLast).toBe(false);
      });
    });
  });
});
