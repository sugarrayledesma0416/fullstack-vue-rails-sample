import DueDateUpdater from 'features/learning_tracks/models/due_date_updater';

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

  add(unit, number) {
    if ( unit === 'days') {
      this.date.setDate(this.date.getDate() + number);
      return new MomentCls(this.date);
    } else if (unit === 'weeks') {
      this.date.setDate(this.date.getDate() + number * 7);
      return new MomentCls(this.date);
    }
  }

  clone() {
    return new MomentCls(this.date.valueOf());
  }

  day(dayIndexInTheWeek) {
    const dayIndex = this.date.getDay();
    const days = dayIndexInTheWeek - dayIndex;
    this.date.setDate(this.date.getDate() + days);
    return new MomentCls(this.date);
  }

  format(formatString) {
    let formattedDate = '';
    switch (formatString) {
    case 'dd':
      // eg. "Mo"
      formattedDate = this.formatDateDd();
      break;
    case 'dddd':
      // eg. "Monday"
      formattedDate = this.formatDateDddd();
      break;
    case 'MM/DD/YYYY':
      // eg. "08/05/2021"
      formattedDate = this.formatDateMMDDYYYY();
      break;
    case 'MMM DD':
      // eg. "Jul 12"
      formattedDate = this.formatDateMMMDD();
      break;
    }
    return formattedDate;
  }

  isAfter(momentInstance) {
    return this.date > momentInstance.getDate();
  }

  isBefore(momentInstance) {
    return this.date < momentInstance.getDate();
  }

  isSame(momentInstance) {
    return this.date == momentInstance.getDate();
  }

  twix(dateStr) {
    const endDate = new Date(dateStr);
    const startDate = this.date;
    function contains(dateToCheck) {
      const twixVal = (dateToCheck.getDate() >= startDate) && (dateToCheck.getDate() <= endDate);
      return twixVal;
    }
    return { contains };
  }

  formatDateDd() {
    const dayIndex = this.date.getDay();
    const daysArr = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return daysArr[dayIndex];
  }

  formatDateDddd() {
    const dayIndex = this.date.getDay();
    const daysArr = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return daysArr[dayIndex];
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

  formatDateMMMDD() {
    let { month, day } = this.getDateParts();
    const monthsArr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    month = monthsArr[month -1];
    if (day.length < 2) {
      day = '0' + day;
    }
    return `${month} ${day}`;
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

let startDate; let endDate; let dueDays; let sectionTrack;
let awhileAgo; let tomorrow; let tomorrowName; let dates;
let date1; let date2; let date3; let date4; let date5; let date6; let date7;
let unselectedLockedDate; let existingDates; let courseDates; let expected1; let expected2;

describe('DueDateUpdater', function() {
  beforeEach(function() {
    startDate = '11/1/2013';
    endDate = '11/30/2013';
    dueDays = [1, 3, 5];
    sectionTrack = {
      description: 'Track 1',
      activities: [
        { due_date: '11/04/2013' },
        { due_date: '11/05/2013' },
      ],
      course_package_ids: [],
    };
  });

  describe('#getCustomDates', function() {
    it('returns the rest of the due dates as indicated in dueDays, for case 1', function() {
      dueDays = [1, 3, 5];
      expect(DueDateUpdater.getCustomDates(startDate, endDate, dueDays).length).toEqual(13);
    });

    it('returns the rest of the due dates as indicated in dueDays, for case 2', function() {
      dueDays = [1, 3];
      expect(DueDateUpdater.getCustomDates(startDate, endDate, dueDays).length).toEqual(8);
    });

    it('returns the rest of the due dates as indicated in dueDays, for case 3', function() {
      dueDays = [0, 1, 2, 3, 4, 5, 6];
      expect(DueDateUpdater.getCustomDates(startDate, endDate, dueDays).length).toEqual(30);
    });
  });

  describe('#fromExistingDates', function() {
    beforeEach(function() {
      awhileAgo = '01/01/1970';
      tomorrow = moment().add('days', 1);
      tomorrowName = tomorrow.format('MM/DD/YYYY');
      dates = [awhileAgo, tomorrowName];
    });

    it('maps date strings to due dates where past due dates are locked', function() {
      expect(DueDateUpdater.fromExistingDates(dates)).toEqual([
        {
          name: awhileAgo,
          label: 'Jan 01',
          selected: true,
          dayOfWeek: moment(awhileAgo).format('dd'),
          locked: true,
        }, {
          name: tomorrowName,
          label: tomorrow.format('MMM DD'),
          selected: true,
          dayOfWeek: tomorrow.format('dd'),
          locked: false,
        },
      ]);
    });
  });

  describe('#guessDueDates', function() {
    it('returns the days of due dates of a previous section', function() {
      expect(DueDateUpdater.guessDueDates(sectionTrack)).toEqual(['Monday', 'Tuesday']);
    });
  });

  describe('#synthesizeDates', function() {
    beforeEach(function() {
      date1 = { name: '08/01/2014', locked: true, selected: true };
      date2 = { name: '08/08/2014', locked: true, selected: true };
      date3 = { name: '08/15/2014', locked: true, selected: true };
      unselectedLockedDate = { name: '08/16/2014', locked: true, selected: false };
      existingDates = [date1, date2, date3, unselectedLockedDate];
      date4 = { name: '08/08/2014' };
      date5 = { name: '08/15/2014' };
      date6 = { name: '08/22/2014', selected: true };
      date7 = { name: '08/09/2014', selected: true };
      courseDates = [date4, date5, date6, date7];
      expected1 = [
        date1,
        date2,
        // date7 deselected
        { name: '08/09/2014', selected: false },
        date3,
        // date6 deselected
        { name: '08/22/2014', selected: false },
      ];
      expected2 = [date1, date2, date7, date3, date6];
    });

    it('combines two separate arrays of dates and returns a sorted union', function() {
      expect(DueDateUpdater.synthesizeDates(existingDates, courseDates)).toEqual(expected2);
    });

    it('combines two separate arrays of dates and returns a sorted union using callback function',
      function() {
        expect(DueDateUpdater.synthesizeDates(existingDates, courseDates, function(date) {
          date.selected = false;
        })).toEqual(expected1);
      }
    );
  });

  describe('#getLockedDueDates', function() {
    beforeEach(function() {
      date1 = { name: '08/08/2014', locked: true };
      date2 = { name: '08/15/2014', locked: true };
      date3 = { name: '08/22/2014', locked: false };
      dates = [date1, date2, date3];
    });

    it('grabs the locked due dates from a due date array', function() {
      expect(DueDateUpdater.getLockedDueDates(dates)).toEqual([date1, date2]);
    });
  });
});
