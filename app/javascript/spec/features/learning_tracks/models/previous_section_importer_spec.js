import PreviousSectionImporter from 'features/learning_tracks/models/previous_section_importer';
import AssignmentGroup from 'features/learning_tracks/models/assignment_group';

const learningTrack = {
  activities: [
    {
      id: 1,
      group: 'Practice',
      due_date: '1/1/1970',
      individually_assignable: true,
      category: 'Homework',
    },
    {
      id: 2,
      group: 'Learn',
      due_date: '1/2/1970',
      individually_assignable: false,
      category: 'Quiz',
    },
    {
      id: 3,
      group: 'Learn',
      due_date: '1/2/1970',
      category: 'Exam',
    },
    {
      id: 4,
      group: 'Learn',
      due_date: '1/2/1970',
    },
  ],
  first_unit_id: 1,
  last_unit_id: 2,
  course_package_ids: [1, 2, 3],
  activityCount: 4,
  categories: [],
};

const activities = {
  1: {
    id: 1,
    name: 'whatever',
    minutes_to_complete: 2,
    strand_name: 'strand 1',
    lesson_name: 'lesson 1',
  },
  2: {
    id: 2,
    name: 'wutever',
    minutes_to_complete: 1,
    strand_name: 'strand 1',
    lesson_name: 'lesson 1',
  },
  3: {
    id: 3,
    name: 'blahblah',
    minutes_to_complete: 1,
    strand_name: 'strand 1',
    lesson_name: 'lesson 2',
  },
  4: {
    id: 4,
    name: 'another name',
    minutes_to_complete: 3,
    strand_name: 'strand 2',
    lesson_name: 'lesson 2',
  },
};

let assignmentMap;
let group1; let group2; let group3; let group4;

describe('PreviousSectionImporter', () => {
  describe('#import', () => {
    describe('when all learning track activities are in activity hash', () => {
      beforeEach(() => {
        assignmentMap = PreviousSectionImporter.import(learningTrack, activities);
        group1 = new AssignmentGroup('Practice', 'strand 1', 'lesson 1');
        group2 = new AssignmentGroup('Learn', 'strand 1', 'lesson 1');
        group3 = new AssignmentGroup('Learn', 'strand 1', 'lesson 2');
        group4 = new AssignmentGroup('Learn', 'strand 2', 'lesson 2');

        group1.addActivity(activities[1]);
        group2.addActivity(activities[2]);
        group3.addActivity(activities[3]);
        group4.addActivity(activities[4]);
      });

      it('returns object having calender with assignments', () => {
        expect(assignmentMap.calendar).toEqual({
          '1/1/1970': [group1],
          '1/2/1970': [group2, group3, group4],
        });
      });

      it('returns object with activityCount "4"', () => {
        expect(assignmentMap.activityCount).toEqual(4);
      });

      it('returns object with jsonIsCurrent as true', () => {
        expect(assignmentMap.jsonIsCurrent).toBeTruthy();
      });

      it('returns object with learning track metadata', () => {
        expect(assignmentMap.firstUnitId).toEqual(1);
        expect(assignmentMap.lastUnitId).toEqual(2);
        expect(assignmentMap.coursePackageIds).toEqual([1, 2, 3]);
        expect(assignmentMap.categories).toEqual([]);
      });
    });

    describe('when learning track has an activity not in the activities hash', () => {
      beforeEach(() => {
        delete activities['4'];
        assignmentMap = PreviousSectionImporter.import(learningTrack, activities);
        group1 = new AssignmentGroup('Practice', 'strand 1', 'lesson 1');
        group2 = new AssignmentGroup('Learn', 'strand 1', 'lesson 1');
        group3 = new AssignmentGroup('Learn', 'strand 1', 'lesson 2');

        group1.addActivity(activities[1]);
        group2.addActivity(activities[2]);
        group3.addActivity(activities[3]);
      });

      it('returns object having calender with assignments', () => {
        expect(assignmentMap.calendar).toEqual({
          '1/1/1970': [group1],
          '1/2/1970': [group2, group3],
        });
      });

      it('returns object with activityCount "3"', () => {
        expect(assignmentMap.activityCount).toEqual(3);
      });

      it('returns object with jsonIsCurrent as false', () => {
        expect(assignmentMap.jsonIsCurrent).toBeFalsy();
      });

      it('returns object with learning track metadata', () => {
        expect(assignmentMap.firstUnitId).toEqual(1);
        expect(assignmentMap.lastUnitId).toEqual(2);
        expect(assignmentMap.coursePackageIds).toEqual([1, 2, 3]);
        expect(assignmentMap.categories).toEqual([]);
      });
    });

    it("sets the activities' properties", () => {
      group1 = new AssignmentGroup('Practice', 'strand 1', 'lesson 1');
      group2 = new AssignmentGroup('Learn', 'strand 1', 'lesson 1');
      group3 = new AssignmentGroup('Learn', 'strand 1', 'lesson 2');
      group4 = new AssignmentGroup('Learn', 'strand 2', 'lesson 2');

      group1.addActivity(activities[1]);
      group2.addActivity(activities[2]);
      group3.addActivity(activities[3]);

      PreviousSectionImporter.import(learningTrack, activities);
      expect(activities[1]).toEqual(
        {
          id: 1,
          name: 'whatever',
          minutes_to_complete: 2,
          strand_name: 'strand 1',
          lesson_name: 'lesson 1',
          group_id: undefined,
          category: 'Homework',
          individually_assignable: true,
        }
      );
      expect(activities[2]).toEqual(
        {
          id: 2,
          name: 'wutever',
          minutes_to_complete: 1,
          strand_name: 'strand 1',
          lesson_name: 'lesson 1',
          group_id: undefined,
          category: 'Quiz',
          individually_assignable: false,
        }
      );
      expect(activities[3]).toEqual(
        {
          id: 3,
          name: 'blahblah',
          minutes_to_complete: 1,
          strand_name: 'strand 1',
          lesson_name: 'lesson 2',
          group_id: undefined,
          category: 'Exam',
          individually_assignable: false,
        }
      );
    });
  });
});
