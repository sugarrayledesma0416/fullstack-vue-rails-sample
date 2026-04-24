import AssignmentGroup from 'features/learning_tracks/models/assignment_group';

describe('AssignmentGroup', () => {
  const activity1 = { minutes_to_complete: 15 };
  const activity2 = { minutes_to_complete: 10 };

  const assignment = {
    activity: {
      id: 1,
      minutes_to_complete: 10,
      strand_name: 'Contextos',
      lesson_name: 'Phu Lesson',
    },
    group: 'Learn',
  };
  let group;

  describe('.build', () => {
    it('returns a new assignment group object that contains one assignment', () => {
      group = new AssignmentGroup('Learn', 'Contextos', 'Phu Lesson');

      group.addActivity(assignment.activity);
      expect(AssignmentGroup.build(assignment)).toEqual(group);
    });
  });

  describe('#addActivity', () => {
    beforeEach(() => {
      group = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
      group.addActivity(activity1);
    });

    it('adds the activity to the back of the group activities array', () => {
      expect(group.activities).toEqual([activity1]);
      group.addActivity(activity2);
      expect(group.activities).toEqual([activity1, activity2]);
    });

    it('adds activity time to the total time', () => {
      expect(group.totalMinutes).toEqual(15);
      group.addActivity(activity2);
      expect(group.totalMinutes).toEqual(25);
    });
  });

  describe('#addActivityToFront', () => {
    beforeEach(() => {
      group = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
      group.addActivityToFront(activity1);
    });

    it('adds an activity to the front of the group activities array', () => {
      expect(group.activities).toEqual([activity1]);
      group.addActivityToFront(activity2);
      expect(group.activities).toEqual([activity2, activity1]);
    });

    it('adds activity time to the total time', () => {
      expect(group.totalMinutes).toEqual(15);
      group.addActivityToFront(activity2);
      expect(group.totalMinutes).toEqual(25);
    });
  });

  describe('#deleteActivity', () => {
    beforeEach(() => {
      group = new AssignmentGroup('learn', 'strand 1', 'lesson 1');
      group.addActivity(activity1);
      group.addActivity(activity2);
    });

    it('deletes the activity specified by the index', () => {
      group.deleteActivity(0);
      expect(group.activities).toEqual([activity2]);
    });

    it('subtracts activity time from the total time', () => {
      group.deleteActivity(0);
      expect(group.totalMinutes).toEqual(10);
    });
  });
});
