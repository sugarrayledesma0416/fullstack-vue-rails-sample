import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import UnitRange from 'features/learning_tracks/models/unit_range';
import * as ActivityDistributor from 'features/learning_tracks/models/activity_distributor';

let assignmentCalendar;
let learningTrack;
let units;

const assignDefaultCalendarData = () => {
  assignmentCalendar.learningTrack = { 'activities': [{ id: 1 }] };
  assignmentCalendar.activities = [2, 4];
  assignmentCalendar.unitRange = new UnitRange(1, 2);
  assignmentCalendar.units = [{ id: 1 }];
  assignmentCalendar.dueDates = [{ name: '1/1/1970' }];
  assignmentCalendar.strands = ['strand1', 'strand2'];
};

describe('AssignmentCalendar', () => {
  beforeEach(() => {
    assignmentCalendar = new AssignmentCalendar();
    assignDefaultCalendarData();
  });

  describe('#build', () => {
    beforeEach(() => {
      learningTrack = [{}, {}, {}, {}];
      jest.spyOn(assignmentCalendar, 'reduceLearningTrack').mockImplementation(
        () => {
          return learningTrack;
        }
      );

      jest.spyOn(assignmentCalendar, 'makeCalendar').mockImplementation(
        () => {
          return 'calendar';
        }
      );
      jest.spyOn(assignmentCalendar, 'calculateWorkLoad').mockImplementation(
        () => {
          return 'workload';
        }
      );

      jest.spyOn(assignmentCalendar, 'buildByLesson').mockImplementation(
        () => {
          return 'built_by_lesson_cal';
        }
      );
      assignmentCalendar.learningTrack = {
        course_package_ids: [1],
        categories: ['Meow'],
      };
      assignmentCalendar.categories = { 'Learn': 'Homework' };
      units = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];
      assignmentCalendar.units = units;
      assignmentCalendar.unitRange = new UnitRange(0, 1, units);
    });

    it('returns null if fields are not valid', () => {
      jest.spyOn(assignmentCalendar, 'isValid').mockImplementation(
        () => {
          return false;
        }
      );
      expect(assignmentCalendar.build()).toEqual(null);
    });

    it('returns an object containing a calendar if fields are valid', () => {
      jest.spyOn(assignmentCalendar, 'isValid').mockImplementation(
        () => {
          return true;
        }
      );
      assignmentCalendar.groupNames = ['Learn', 'Learn', 'Practice'];
      const expected = {
        calendar: 'calendar',
        coursePackageIds: [1],
        firstUnitId: 1,
        lastUnitId: 2,
        categories: { 'Learn': 'Homework' },
        workLoad: 'workload',
        groupNames: ['Learn', 'Practice'],
      };
      expect(assignmentCalendar.build()).toEqual(expected);
    });

    it('calls buildByLesson if splitLessons and enoughDueDates are true', () => {
      jest.spyOn(assignmentCalendar, 'isValid').mockImplementation(
        () => {
          return true;
        }
      );
      assignmentCalendar.splitLessons = true;
      assignmentCalendar.dueDates = [
        { name: '1/1/1970' },
        { name: '1/8/1970' },
        { name: '1/9/1970' },
      ];
      expect(assignmentCalendar.build().calendar).toEqual('built_by_lesson_cal');
    });
  });

  describe('#buildByLesson', () => {
    beforeEach(() => {
      jest.spyOn(assignmentCalendar, 'reduceLearningTrack').mockImplementation(
        () => {
          return 'learning track';
        }
      );
    });

    it('appends each calendar subset to the calendar once for each unit', () => {
      jest.spyOn(Object, 'assign');
      jest.spyOn(assignmentCalendar, 'makeCalendar').mockImplementation(
        () => {
          return 'calender';
        }
      );
      assignmentCalendar.dueDates = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      assignmentCalendar.unitRange = new UnitRange(0, 9);
      assignmentCalendar.buildByLesson();
      expect(Object.assign).toHaveBeenCalledTimes(10);
    });

    it('distributes remaining days among the lessons', () => {
      let calls = 0;
      const calendarSubsets = [
        {
          1: 'subset 1',
          2: 'subset 1',
          3: 'subset 1',
          4: 'subset 1',
        }, {
          5: 'subset 2',
          6: 'subset 2',
          7: 'subset 2',
        }, {
          8: 'subset 3',
          9: 'subset 3',
          10: 'subset 3',
        },
      ];
      assignmentCalendar.dueDates = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      assignmentCalendar.unitRange = new UnitRange(0, 2);

      jest.spyOn(assignmentCalendar, 'makeCalendar').mockImplementation(
        () => {
          return calendarSubsets[calls++];
        }
      );
      expect(assignmentCalendar.buildByLesson()).toEqual({
        1: 'subset 1',
        2: 'subset 1',
        3: 'subset 1',
        4: 'subset 1',
        5: 'subset 2',
        6: 'subset 2',
        7: 'subset 2',
        8: 'subset 3',
        9: 'subset 3',
        10: 'subset 3',
      });
      expect(assignmentCalendar.makeCalendar).
        toHaveBeenCalledWith('learning track', [1, 2, 3, 4]);
      expect(assignmentCalendar.makeCalendar).
        toHaveBeenCalledWith('learning track', [5, 6, 7]);
      expect(assignmentCalendar.makeCalendar).
        toHaveBeenCalledWith('learning track', [8, 9, 10]);
    });
  });

  describe('#calculateWorkLoad', () => {
    const calendar = {
      '11/1/2014': [
        {
          totalMinutes: 15,
          activities: [1, 2, 3],
        },
        {
          totalMinutes: 15,
          activities: [4, 5],
        },
      ],
      '11/3/2014': [
        {
          totalMinutes: 5,
          activities: [6, 7, 8],
        },
        {
          totalMinutes: 15,
          activities: [9, 10],
        },
      ],
    };
    beforeEach(() => {
      assignmentCalendar.learningTrack = [
        {
          activity: { unit_id: 2 },
          group: 'Listen',
        },
        {
          activity: { unit_id: 3 },
          group: 'Listen',
        },
      ];
    });

    it('returns an object with activityCount, avg, max and min', () => {
      const workload = {
        activityCount: 10,
        avg: 25,
        max: 30,
        min: 20,
      };
      expect(assignmentCalendar.calculateWorkLoad(calendar)).
        toEqual(workload);
    });
  });

  describe('#isValid', () => {
    it('is false if learningTrack is empty', () => {
      assignmentCalendar.learningTrack = {};
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is false if first unit index is null', () => {
      assignmentCalendar.unitRange = new UnitRange(null, 2);
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is false if last unit index is null', () => {
      assignmentCalendar.unitRange = new UnitRange(1, null);
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is false if dueDates is null', () => {
      assignmentCalendar.dueDates = null;
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is false if strands is empty', () => {
      assignmentCalendar.strands = [];
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is false if units is empty', () => {
      assignmentCalendar.units = [];
      expect(assignmentCalendar.isValid()).toBeFalsy();
    });

    it('is true if all fields are filled', () => {
      expect(assignmentCalendar.isValid()).toBeTruthy();
    });
  });

  describe('#makeCalendar', () => {
    it('returns a new assignment calendar', () => {
      const dueDates = [
        {
          name: '1/1/1970',
          locked: false,
        }, {
          name: '1/8/1970',
          locked: false,
        },
      ];
      jest.spyOn(ActivityDistributor, 'distribute').mockImplementation(
        () => {
          return 'Calendar';
        }
      );
      expect(assignmentCalendar.makeCalendar('LearningTrack', dueDates))
        .toEqual('Calendar');
      expect(ActivityDistributor.distribute).
        toHaveBeenCalledWith('LearningTrack',
          ['1/1/1970', '1/8/1970'],
          assignmentCalendar.basicStrategy);
    });

    describe('when there is a previous calendar', () => {
      it('adds the assignments for locked days into the new assignment calendar', () => {
        const dueDates = [
          {
            name: '1/1/1970',
            locked: true,
          }, {
            name: '1/8/1970',
            locked: false,
          },
        ];

        assignmentCalendar.prev = {
          calendar: {
            '1/1/1970': 'foo',
            '1/8/1970': 'baz',
          },
        };
        jest.spyOn(ActivityDistributor, 'distribute').mockImplementation(
          () => {
            return { '1/8/1970': 'bar' };
          }
        );
        expect(assignmentCalendar.makeCalendar('LearningTrack', dueDates))
          .toEqual({
            '1/1/1970': 'foo',
            '1/8/1970': 'bar',
          });
      });
    });
  });

  describe('#reduceLearningTrack', () => {
    beforeEach(() => {
      units = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];
      assignmentCalendar.units = units;
      assignmentCalendar.copyIac = true;

      assignmentCalendar.activities = {
        1: { unit_id: 1, strand: 'strand1' },
        2: { unit_id: 2, strand: 'strand1' },
        3: { unit_id: 3, strand: 'strand2' },
        4: { unit_id: 4, strand: 'strand2' },
      };
      assignmentCalendar.learningTrack = {
        activities: [
          {
            id: 1,
            group: 'Listen',
            group_id: 1,
            individually_assignable: true,
          }, {
            id: 2,
            group: 'Listen',
            group_id: 1,
            category: 'category',
            due_date: 'dueDate',
            individually_assignable: true,
          }, {
            id: 3,
            group: 'Listen',
            group_id: 1,
            individually_assignable: false,
          }, {
            id: 4,
            group: 'Listen',
            group_id: 1,
            individually_assignable: undefined,
          }, {
            activity_requirements: {
              instructor_graded: false,
              required_microphone: false,
              require_partner: false,
            },
            id: 5,
            is_igc: true,
            group: 'Listen',
            group_id: 1,
            strand: 'strand1',
            strand_name: 'strand1',
            unit_id: 1,
          },
        ],
      };
    });

    it('filters out learning track activities that fall outside the ' +
       'lesson and strand ranges', () => {
      const unitRange = new UnitRange(1, 2, units);
      expect(assignmentCalendar.reduceLearningTrack(unitRange, ['strand1'])).toEqual([
        {
          activity: {
            unit_id: 2,
            strand: 'strand1',
            group_id: 1,
            category: 'category',
            individually_assignable: true,
          },
          group: 'Listen',
          due_date: 'dueDate',
        },
      ]);
    });

    it('filters out activities that do not satisfy custom filters', () => {
      const unitRange = new UnitRange(0, 3, units);
      assignmentCalendar.registerFilter(function(activity) {
        return activity.unit_id > 1 && activity.unit_id < 4;
      });

      expect(assignmentCalendar.reduceLearningTrack(unitRange, ['strand1', 'strand2'])).toEqual([
        {
          activity: {
            unit_id: 2,
            strand: 'strand1',
            group_id: 1,
            category: 'category',
            individually_assignable: true,
          },
          group: 'Listen',
          due_date: 'dueDate',
        }, {
          activity: {
            unit_id: 3,
            strand: 'strand2',
            group_id: 1,
            individually_assignable: false,
          },
          group: 'Listen',
        },
      ]);
    });

    it('filters out activities that are assigned on locked days in the ' +
       'previous calendar', () => {
      const strands = ['strand1', 'strand2'];
      const unitRange = new UnitRange(0, 3, units);
      assignmentCalendar.prev = {
        calendar: {
          '1/1/1970': [
            {
              group: 'Learn',
              activities: [
                {
                  id: 1,
                  group: 'Listen',
                  group_id: 1,
                }, {
                  id: 2,
                  group: 'Listen',
                  group_id: 1,
                },
              ],
            },
          ],
        },
      };
      assignmentCalendar.dueDates = [
        {
          name: '1/1/1970',
          locked: true,
        }, {
          name: '1/8/1970',
          locked: false,
        },
      ];

      expect(assignmentCalendar.reduceLearningTrack(unitRange, strands))
        .toEqual([
          {
            activity: {
              unit_id: 3,
              strand: 'strand2',
              group_id: 1,
              category: undefined,
              individually_assignable: false,
            },
            group: 'Listen',
            due_date: undefined,
          }, {
            activity: {
              unit_id: 4,
              strand: 'strand2',
              group_id: 1,
              category: undefined,
              individually_assignable: undefined,
            },
            group: 'Listen',
            due_date: undefined,
          },
        ]);
    });

    it("sets activities' individually_assignable property to that of the assignment", () => {
      const unitRange = new UnitRange(0, 3, units);
      const reducedAssignments = assignmentCalendar.reduceLearningTrack(
        unitRange, ['strand1', 'strand2']
      );

      const individuallyAssignableValues = reducedAssignments.map(
        (a) => a.activity.individually_assignable
      );

      expect(individuallyAssignableValues).toEqual([true, true, false, undefined]);
    });
    it(
      'filters out IGC if Copy Instructor-created Activities is not checked',
      () => {
        const strands = ['strand1', 'strand2'];
        const unitRange = new UnitRange(0, 3, units);

        expect(
          assignmentCalendar.reduceLearningTrack(unitRange, strands)
        ).toEqual(
          [
            {
              activity: {
                unit_id: 1,
                strand: 'strand1',
                group_id: 1,
                category: undefined,
                individually_assignable: true,
              },
              group: 'Listen',
              due_date: undefined,
            }, {
              activity: {
                unit_id: 2,
                strand: 'strand1',
                group_id: 1,
                category: 'category',
                individually_assignable: true,
              },
              group: 'Listen',
              due_date: 'dueDate',
            }, {
              activity: {
                unit_id: 3,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: false,
              },
              group: 'Listen',
              due_date: undefined,
            }, {
              activity: {
                unit_id: 4,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: undefined,
              },
              group: 'Listen',
              due_date: undefined,
            },
          ]
        );
      }
    );

    it(
      'filters out individually assigned activities if IAC Copy is not checked',
      () => {
        assignmentCalendar.copyIac = false;

        const strands = ['strand1', 'strand2'];
        const unitRange = new UnitRange(0, 3, units);

        expect(
          assignmentCalendar.reduceLearningTrack(unitRange, strands)
        ).toEqual(
          [
            {
              activity: {
                unit_id: 3,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: false,
              },
              group: 'Listen',
              due_date: undefined,
            }, {
              activity: {
                unit_id: 4,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: undefined,
              },
              group: 'Listen',
              due_date: undefined,
            },
          ]
        );
      }
    );

    it(
      'includes IGC if Copy Instructor-created Activities is checked',
      () => {
        assignmentCalendar.copyIgc = true;
        const strands = ['strand1', 'strand2'];
        const unitRange = new UnitRange(0, 3, units);

        expect(
          assignmentCalendar.reduceLearningTrack(unitRange, strands)
        ).toEqual(
          [
            {
              activity: {
                unit_id: 1,
                strand: 'strand1',
                group_id: 1,
                category: undefined,
                individually_assignable: true,
              },
              group: 'Listen',
              due_date: undefined,

            }, {
              activity: {
                unit_id: 2,
                strand: 'strand1',
                group_id: 1,
                category: 'category',
                individually_assignable: true,
              },
              group: 'Listen',
              due_date: 'dueDate',
            }, {
              activity: {
                unit_id: 3,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: false,
              },
              group: 'Listen',
              due_date: undefined,
            }, {
              activity: {
                unit_id: 4,
                strand: 'strand2',
                group_id: 1,
                category: undefined,
                individually_assignable: undefined,
              },
              group: 'Listen',
              due_date: undefined,
            }, {
              activity: {
                activity_requirements: {
                  instructor_graded: false,
                  required_microphone: false,
                  require_partner: false,
                },
                category: undefined,
                id: 5,
                individually_assignable: undefined,
                is_igc: true,
                group: 'Listen',
                group_id: 1,
                strand: 'strand1',
                strand_name: 'strand1',
                unit_id: 1,
              },
              due_date: undefined,
              group: 'Listen',
            },
          ]
        );
      }
    );
  });
});
