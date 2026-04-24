import CalendarProcessor from 'features/learning_tracks/models/calendar_processor';

// Class to mock moment js implementation for the test cases
class MomentCls {
  constructor(initDate) {
    let date = new Date();
    if (typeof initDate === 'object') {
      date = initDate;
    } else if (initDate) {
      date = new Date(initDate);
    }
    this.date = date;
  }

  format(formatString) {
    let formattedDate = '';
    switch (formatString) {
    case 'MM/DD/YYYY':
      // eg. "08/05/2021"
      formattedDate = this.formatDateMMDDYYYY();
      break;
    }
    return formattedDate;
  }

  isAfter(momentInstance) {
    return this.date > momentInstance.getDate();
  }

  formatDateMMDDYYYY() {
    let { month, day, year } = this.getDateParts();
    if (month.length < 2) {
      month = '0' + month;
    }
    if (day.length < 2) {
      day = '0' + day;
    }
    return [year, month, day].join('/');
  }

  getDate() {
    return this.date;
  }

  getDateParts() {
    const month = (this.date.getMonth() + 1).toString();
    const day = this.date.getDate().toString();
    const year = this.date.getFullYear().toString();
    return { month, day, year };
  }
}

/**
 * Get instance of MomentCls
 * @param {Object|string} date
 * @return {MomentCls} - Instance of MomentCls
 */
function momentFn(date) {
  return new MomentCls(date);
}

// Mock moment on window object and allow for initialization of moment() without 'new'
window.moment = momentFn;

const today = moment().format('MM/DD/YYYY');

const activity1 = {
  activityequirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Talking picture',
  category: 'Cat 1',
  group_id: 10,
  id: 1,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
  individually_assignable: true,
};

const strippedActivity1 = {
  id: 1,
  group_id: 10,
  category: 'Cat 1',
  individually_assignable: true,
};

const activity2 = {
  activity_requirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Talking picture',
  category: 'Cat 2',
  group_id: 11,
  id: 2,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
};

const strippedActivity2 = {
  id: 2,
  group_id: 11,
  category: 'Cat 2',
  individually_assignable: undefined,
};

const activity3 = {
  activity_requirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Talking picture',
  category: 'Cat 3',
  group_id: 12,
  id: 3,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
};

const strippedActivity3 = {
  id: 3,
  group_id: 12,
  category: 'Cat 3',
  individually_assignable: undefined,
};

const activity4 = {
  activity_requirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Talking picture',
  category: 'Cat 4',
  group_id: 13,
  id: 4,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
};

const strippedActivity4 = {
  id: 4,
  group_id: 13,
  category: 'Cat 4',
  individually_assignable: undefined,
};

const activity5 = {
  activity_requirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Learning Engine',
  category: 'Cat 5',
  group_id: 14,
  id: 5,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
};

const activity6 = {
  activity_requirements: {
    1: 'blah',
    2: 'blah',
  },
  activity_type: 'Learning Engine',
  category: 'Cat 6',
  group_id: 15,
  id: 6,
  lesson_name: 'Lesson 1',
  minutes_to_complete: 4,
  strand: 'Contextos',
  strand_name: 'Contextos',
  substrand: null,
  title: 'Hi there',
  unit_id: 194,
};

const calendar = {
  '08/18/2100': [
    {
      activities: [activity1, activity2],
      lesson: 'Lesson 1',
      name: 'Explore',
      strand: 'Contextos',
      total_minutes: 4,
    },
    {
      activities: [activity3],
      lesson: 'Lesson 1',
      name: 'Learn',
      strand: 'Contextos',
      total_minutes: 10,
    },
  ],
  '08/25/2100': [
    {
      activities: [activity4],
      lesson: 'Lesson 2',
      name: 'Learn',
      strand: 'Contextos',
      total_minutes: 12,
    },
  ],
  '08/28/2000': [
    {
      activities: [activity5],
      lesson: 'Lesson 3',
      name: 'Interact',
      strand: 'Contextos',
      total_minutes: 13,
    },
  ],
};

calendar[today] = [{
  activities: [activity6],
  lesson: 'Lesson 4',
  name: 'Interact',
  strand: 'Contextos',
  total_minutes: 13,
}];

describe('CalendarProcessor', function() {
  describe('#stripCalendar', function() {
    it('returns a stripped down calendar with just future due dates and activities', function() {
      // Today should not be included in the results of #stripCalendar
      const expected = {
        '08/18/2100': [strippedActivity1, strippedActivity2, strippedActivity3],
        '08/25/2100': [strippedActivity4],
      };
      expect(CalendarProcessor.stripCalendar(calendar)).toEqual(expected);
    });

    it('modifies the activity with an optional callback', function() {
      const expected = {
        '08/18/2100': [
          {
            id: 1,
            group_id: 10,
            category: 'Explore',
            individually_assignable: true,
          },
          {
            id: 2,
            group_id: 11,
            category: 'Explore',
            individually_assignable: undefined,
          },
          {
            id: 3,
            group_id: 12,
            category: 'Learn',
            individually_assignable: undefined,
          },
        ],
        '08/25/2100': [
          {
            id: 4,
            group_id: 13,
            category: 'Learn',
            individually_assignable: undefined,
          },
        ],
      };
      expect(CalendarProcessor.stripCalendar(calendar, function(activity, group) {
        activity.category = group.name;
      })).toEqual(expected);
    });
  });

  describe('#condenseActivity', function() {
    it("includes the activity's id", function() {
      const id = CalendarProcessor.condenseActivity(activity1).id;
      expect(id).toEqual(1);
    });

    it("includes the activity's group id", function() {
      const groupId = CalendarProcessor.condenseActivity(activity1).group_id;
      expect(groupId).toEqual(10);
    });

    it("includes the activity's category", function() {
      const category = CalendarProcessor.condenseActivity(activity1).category;
      expect(category).toEqual('Cat 1');
    });

    it("includes the activity's individually_assignable property", function() {
      const value = CalendarProcessor.condenseActivity(activity1).individually_assignable;
      expect(value).toEqual(true);
    });
  });
});
