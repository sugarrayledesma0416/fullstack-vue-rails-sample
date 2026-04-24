import * as ActivityDistributor from 'features/learning_tracks/models/activity_distributor';
import AssignmentGroup from 'features/learning_tracks/models/assignment_group';

describe('ActivityDistributor', () => {
  const activity1 = {
    id: 1,
    minutes_to_complete: 10,
    lesson_name: 'Lesson 1',
    strand_name: 'Strand 1',
  };

  const activity2 = {
    id: 2,
    minutes_to_complete: 10,
    lesson_name: 'Lesson 1',
    strand_name: 'Strand 1',
  };

  const activity3 = {
    id: 3,
    minutes_to_complete: 15,
    lesson_name: 'Lesson 1',
    strand_name: 'Strand 2',
  };

  let assignment1 = { activity: activity1, group: 'Learn' };
  let assignment2 = { activity: activity2, group: 'Practice' };
  let assignment3 = { activity: activity3, group: 'Practice' };

  let activity4; let activity5; let activity6;
  let assignment4; let assignment5; let assignment6;

  let assignments = [];
  let assignmentGroups = [];
  let dueDates = [];

  function basicStrategy() {
    return false;
  }

  function groupStrategy(current, previous) {
    return current.group === previous.group;
  }

  describe('#groupByStrand', () => {
    it('converts an array of assignment groups to strand groups', () => {
      activity4 = {
        id: 4,
        minutes_to_complete: 15,
        lesson_name: 'Lesson 2',
        strand_name: 'Strand 2',
      };

      assignment4 = { activity: activity4, group: 'Interact' };

      const group1 = AssignmentGroup.build(assignment1);
      const group2 = AssignmentGroup.build(assignment2);
      const group3 = AssignmentGroup.build(assignment3);
      const group4 = AssignmentGroup.build(assignment4);

      assignmentGroups = [group1, group2, group3, group4];

      expect(ActivityDistributor.groupByStrand(assignmentGroups)).toEqual([
        {
          name: 'Strand 1',
          lesson: 'Lesson 1',
          totalMinutes: 20,
          groups: [group1, group2],
        },
        {
          name: 'Strand 2',
          lesson: 'Lesson 1',
          totalMinutes: 15,
          groups: [group3],
        },
        {
          name: 'Strand 2',
          lesson: 'Lesson 2',
          totalMinutes: 15,
          groups: [group4],
        },
      ]);
    });
  });

  describe('#buildChunks', () => {
    assignments = [assignment1, assignment2, assignment3];

    it('builds an array of assignment chunks based on a chunking strategy', () => {
      const expected = [[assignment1], [assignment2, assignment3]];

      expect(ActivityDistributor.buildChunks(assignments, groupStrategy)).
        toEqual(expected);
    });

    it('does not call the strategy with a null previous assignment', () => {
      const spy = jest.fn();

      ActivityDistributor.buildChunks(assignments, spy);
      expect(spy).not.toHaveBeenCalledWith(assignment1, null);
      expect(spy).toHaveBeenCalledWith(assignment2, assignment1);
    });
  });

  describe('#buildGroups', () => {
    let group1; let group2; let group3; let group4; let group5;

    beforeEach(() => {
      activity4 = {
        id: 3,
        minutes_to_complete: 15,
        lesson_name: 'Lesson 2',
        strand_name: 'Strand 2',
      };

      activity5 = {
        id: 4,
        minutes_to_complete: 10,
        lesson_name: 'Lesson 2',
        strand_name: 'Strand 3',
      };

      activity6 = {
        id: 5,
        minutes_to_complete: 11,
        lesson_name: 'Lesson 2',
        strand_name: 'Strand 3',
      };

      assignment4 = { activity: activity4, group: 'Practice' };
      assignment5 = { activity: activity5, group: 'Practice' };
      assignment6 = { activity: activity6, group: 'Practice' };

      assignments = [
        assignment1,
        assignment2,
        assignment3,
        assignment4,
        assignment5,
        assignment6,
      ];
      group1 = AssignmentGroup.build(assignment1);
      group2 = AssignmentGroup.build(assignment2);
      group3 = AssignmentGroup.build(assignment3);
      group4 = AssignmentGroup.build(assignment4);
      group5 = AssignmentGroup.build(assignment5);

      group5.addActivity(assignment6.activity);
    });

    it('folds an array of assignments into an array of assignment groups', () => {
      expect(ActivityDistributor.buildGroups(assignments)).
        toEqual([group1, group2, group3, group4, group5]);
    });
  });

  describe('#assign', () => {
    const chunks = [[assignment1], [assignment2]];
    let group1; let group2; let result;

    describe('when all of the chunks fit within the total time', () => {
      beforeEach(() => {
        result = ActivityDistributor.assign(20, chunks);
        group1 = AssignmentGroup.build(assignment1);
        group2 = AssignmentGroup.build(assignment2);
      });

      it('returns an array of assignment groups with all activities in the chunks', () => {
        expect(result[0]).toEqual([group1, group2]);
      });

      it('returns an empty remainder array', () => {
        expect(result[1]).toEqual([]);
      });
    });

    describe('when none of the chunks fit within the total time', () => {
      beforeEach(() => {
        result = ActivityDistributor.assign(9, chunks);
      });

      it('returns the first assignment group array', () => {
        expect(result[0]).toEqual([AssignmentGroup.build(assignment1)]);
      });

      it('returns the rest of the chunks unchanged', () => {
        expect(result[1]).toEqual([[assignment2]]);
      });
    });

    describe('when some of the chunks fit within the total time', () => {
      beforeEach(() => {
        result = ActivityDistributor.assign(10, chunks);
      });

      it('returns an array of assignment groups with activities from the chunks that fit', () => {
        expect(result[0]).toEqual([AssignmentGroup.build(assignment1)]);
      });

      it('returns an array of the chunks that do not fit', () => {
        expect(result[1]).toEqual([[assignment2]]);
      });
    });
  });

  describe('#distribute', () => {
    let dueDate1; let dueDate2; let dueDate3; let dueDate4;

    it('returns an assignment calendar that maps due dates to groups', () => {
      dueDate1 = new Date('1/1/1970');
      dueDate2 = new Date('11/22/2013');

      assignments = [assignment1, assignment2];
      dueDates = [dueDate1, dueDate2];
      const calendar = ActivityDistributor.distribute(assignments, dueDates, groupStrategy);

      // Build Expectation
      const expected = {};
      expected[dueDate1] = [AssignmentGroup.build(assignment1)];
      expected[dueDate2] = [AssignmentGroup.build(assignment2)];

      expect(calendar).toEqual(expected);
    });

    describe('edge cases', () => {
      beforeEach(() => {
        dueDate1 = new Date('10/26/2013');
        dueDate2 = new Date('10/27/2013');
        dueDate3 = new Date('10/28/2013');
        dueDate4 = new Date('10/29/2013');
        assignment1 = { activity: { id: 1, minutes_to_complete: 10 }, group: 'Learn' };
        assignment2 = { activity: { id: 2, minutes_to_complete: 5 }, group: 'Learn' };
        assignment3 = { activity: { id: 3, minutes_to_complete: 15 }, group: 'Learn' };
        assignment4 = { activity: { id: 4, minutes_to_complete: 20 }, group: 'Practice' };
        assignment5 = { activity: { id: 5, minutes_to_complete: 55 }, group: 'Learn' };
      });

      it('distributes correctly when there is an outlier activity', () => {
        dueDates = [dueDate1, dueDate2, dueDate3, dueDate4];
        assignments = [assignment1, assignment2, assignment3, assignment4, assignment5];
        const calendar = ActivityDistributor.distribute(assignments, dueDates, basicStrategy);

        // Build Expectation
        const expected = {};
        const assignmentGroup = AssignmentGroup.build(assignment1);
        assignmentGroup.addActivity(assignment2.activity);
        expected[dueDate1] = [assignmentGroup];
        expected[dueDate2] = [AssignmentGroup.build(assignment3)];
        expected[dueDate3] = [AssignmentGroup.build(assignment4)];
        expected[dueDate4] = [AssignmentGroup.build(assignment5)];

        expect(calendar).toEqual(expected);
      });

      it('distributes correctly when there are less due dates than activities', () => {
        dueDates = [dueDate1, dueDate2, dueDate3];
        assignments = [assignment1, assignment2, assignment3, assignment4, assignment5];
        const calendar = ActivityDistributor.distribute(assignments, dueDates, basicStrategy);

        // Build Expectation
        const expected = {};
        const assignmentGroup = AssignmentGroup.build(assignment1);
        assignmentGroup.addActivity(assignment2.activity);
        assignmentGroup.addActivity(assignment3.activity);
        expected[dueDate1] = [assignmentGroup];
        expected[dueDate2] = [AssignmentGroup.build(assignment4)];
        expected[dueDate3] = [AssignmentGroup.build(assignment5)];

        expect(calendar).toEqual(expected);
      });

      it('distributes correctly when there is a due date with a low completion time', () => {
        dueDates = [dueDate1, dueDate2, dueDate3, dueDate4];
        assignment1.activity.minutes_to_complete = 10;
        assignment2.activity.minutes_to_complete = 20;
        assignment3.activity.minutes_to_complete = 1;
        assignment4.activity.minutes_to_complete = 2;
        assignment5.activity.minutes_to_complete = 30;

        const assignments = [assignment1, assignment2, assignment3, assignment4, assignment5];
        const calendar = ActivityDistributor.distribute(assignments, dueDates, basicStrategy);

        // Build Expectation
        const expected = {};
        expected[dueDate1] = [AssignmentGroup.build(assignment1)];
        expected[dueDate2] = [AssignmentGroup.build(assignment2)];
        expected[dueDate3] = [
          AssignmentGroup.build(assignment3),
          AssignmentGroup.build(assignment4),
        ];
        expected[dueDate4] = [AssignmentGroup.build(assignment5)];

        expect(calendar).toEqual(expected);
      });

      it('distributes correctly when there are two activities with low completion times', () => {
        dueDates = [dueDate1, dueDate2, dueDate3];
        assignment1.activity.minutes_to_complete = 10;
        assignment2.activity.minutes_to_complete = 20;
        assignment3.activity.minutes_to_complete = 1;
        assignment4.activity.minutes_to_complete = 2;
        assignment5.activity.minutes_to_complete = 30;
        assignments = [assignment1, assignment2, assignment3, assignment4, assignment5];
        const calendar = ActivityDistributor.distribute(assignments, dueDates, basicStrategy);

        // Build Expectation
        const expected = {};
        const assignmentGroup = AssignmentGroup.build(assignment2);
        assignmentGroup.addActivity(assignment3.activity);
        expected[dueDate1] = [AssignmentGroup.build(assignment1)];
        expected[dueDate2] = [assignmentGroup, AssignmentGroup.build(assignment4)];
        expected[dueDate3] = [AssignmentGroup.build(assignment5)];

        expect(calendar).toEqual(expected);
      });
    });
  });
});
