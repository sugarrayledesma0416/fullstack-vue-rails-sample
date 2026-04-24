import AssignmentWizard from 'features/assignment_wizard/models/assignment_wizard';
import PreviousSectionImporter from 'features/learning_tracks/models/previous_section_importer';
import DueDateUpdater from 'features/learning_tracks/models/due_date_updater';
import CalendarProcessor from 'features/learning_tracks/models/calendar_processor';
import UnitRange from 'features/learning_tracks/models/unit_range';
import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import * as ajaxUtils from 'shared/ajax_utils';
import { dispatchCustomEvent } from 'shared/utils';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

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
    case 'dd':
      // eg. "Mo"
      formattedDate = this.formatDateDd();
      break;
    case 'MMM DD':
      // eg. "Jul 12"
      formattedDate = this.formatDateMMMDD();
      break;
    }
    return formattedDate;
  }

  isBefore(momentInstance) {
    return this.date < momentInstance.getDate();
  }

  formatDateDd() {
    const dayIndex = this.date.getDay();
    const daysArr = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return daysArr[dayIndex];
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

let assignmentWizard;
let instAssignmentWizard;
let importedCalendar;

window.VISTA_ONLINE_LEARNING = '';
const programId = 14;
const courseId = 12345;
const sectionId = 99;

const Logstash = class {
  constructor(templateType) {
    this.templateType = templateType;
  }

  dispatch(type, statsObj) {}
};

window.VHL = {
  CarlinDispatch: { Logstash },
  Common: {
    parse_query_string: () => {
      return { section_id: sectionId };
    },
    createJSErrorLog: jest.fn(),
  },
};
window.alert = jest.fn();

describe('AssignmentWizard', () => {
  describe('When the user is an institution admin', () => {
    beforeEach(async () => {
      // Set up location and meta tags for Institution Admin user
      delete window.location;
      const adminLocationUrl = `http://example.com/institution_admin/${programId}/` +
            `courses/${courseId}/sections/${sectionId}/assignment_wizard_templates`;
      window.location = new URL(adminLocationUrl);

      const userMeta = document.createElement('meta');
      userMeta.setAttribute('name', 'VHL.in_institution_admin');
      userMeta.setAttribute('content', true);
      document.head.append(userMeta);

      jest.useFakeTimers();
      const courseInfo = {
        current_course: courseId,
        start_date: '2014-08-07',
        end_date: '2014-08-27',
      };
      const previousLearningTrack = {
        description: 'My Description',
        firstUnitId: 100,
        lastUnitId: 200,
        units: [{ id: 100 }, { id: 200 }],
      };
      importedCalendar = {
        calendar: {
          '08/08/2020': 'blah',
          '08/27/2020': 'blah2',
          '09/05/2020': 'blah3',
        },
        categories: {},
        jsonIsCurrent: false,
      };
      const courseTemplateInfoUrl = `/institution_admin/${programId}/course/${courseId}/` +
            'assignment_wizard_templates/course_info.json';
      const previousTrackUrl = `/instructor/${programId}/section_learning_track/` +
            `${sectionId}.json?current_course_id=${courseId}`;
      const tracksUrl = `/instructor/${programId}/learning_tracks.json`;
      fetchMock.mock(courseTemplateInfoUrl, { status: 200, body: courseInfo });
      fetchMock.mock(previousTrackUrl, { status: 200, body: previousLearningTrack });
      fetchMock.mock(tracksUrl, { status: 200, body: previousLearningTrack });
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      jest.spyOn(DueDateUpdater, 'guessDueDates').mockImplementation(() => ['Monday']);
      jest.spyOn(PreviousSectionImporter, 'import').mockImplementation(() => importedCalendar);
      const assignmentCalendar = new AssignmentCalendar();
      instAssignmentWizard = new AssignmentWizard(assignmentCalendar);
      jest.spyOn(
        instAssignmentWizard.assignmentCalendar, 'calculateWorkLoad'
      ).mockImplementation(() => 10);
      jest.spyOn(instAssignmentWizard.initDataFetch, 'useDueDateConfig').mockImplementation(() => {
        instAssignmentWizard.store.allDueDates = [
          { label: 'Aug 11', name: '08/11/2020' },
          { label: 'Sep 14', name: '09/14/2020' },
          { label: 'Aug 8', name: '08/08/2020' },
        ];
      });
      instAssignmentWizard.store.learningTracks = { tracks: {}};
      instAssignmentWizard.store.unitRange = new UnitRange(5, 7);
      await fetchMock.flush(true);
      await flushPromises();
    });

    afterEach(() => {
      fetchMock.restore();
      const userMeta = document.querySelector('meta[name="VHL.in_institution_admin"]');
      userMeta.setAttribute('content', false);
    });

    describe('on assignment wizard load', function() {
      it('calls the institution admin url when instAdmin is true', function() {
        const courseTemplateInfoUrl = `/institution_admin/${programId}/course/${courseId}/` +
              'assignment_wizard_templates/course_info.json';

        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          courseTemplateInfoUrl, jasmine.any(Function)
        );
      });
    });
  });


  describe('When the user is an instructor', function() {
    beforeEach(async () => {
      // Set up location and meta tag for instructor user.
      delete window.location;
      const instructorLocationUrl = `http://example.com/instructor/${programId}/` +
             `course/${courseId}/assignment_wizard?section_id=${sectionId}`;
      window.location = new URL(instructorLocationUrl);

      jest.useFakeTimers();
      const courseInfo = {
        current_course: courseId,
        start_date: '2014-08-07',
        end_date: '2014-08-27',
      };
      const previousLearningTrack = {
        description: 'My Description',
        firstUnitId: 100,
        lastUnitId: 200,
        units: [{ id: 100 }, { id: 200 }],
      };
      importedCalendar = {
        calendar: {
          '08/08/2020': 'blah',
          '08/27/2020': 'blah2',
          '09/05/2020': 'blah3',
        },
        categories: {},
        jsonIsCurrent: false,
      };
      const courseInfoUrl = `/instructor/${programId}/course/${courseId}/` +
        'assignment_wizard/course_info.json';
      const previousTrackUrl = `/instructor/${programId}/section_learning_track/` +
        `${sectionId}.json?current_course_id=${courseId}`;
      const tracksUrl = `/instructor/${programId}/learning_tracks.json`;
      fetchMock.mock(courseInfoUrl, { status: 200, body: courseInfo });
      fetchMock.mock(previousTrackUrl, { status: 200, body: previousLearningTrack });
      fetchMock.mock(tracksUrl, { status: 200, body: previousLearningTrack });
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      jest.spyOn(DueDateUpdater, 'guessDueDates').mockImplementation(() => ['Monday']);
      jest.spyOn(PreviousSectionImporter, 'import').mockImplementation(() => importedCalendar);
      const assignmentCalendar = new AssignmentCalendar();
      assignmentWizard = new AssignmentWizard(assignmentCalendar);
      jest.spyOn(
        assignmentWizard.assignmentCalendar, 'calculateWorkLoad'
      ).mockImplementation(() => 10);
      jest.spyOn(assignmentWizard.initDataFetch, 'useDueDateConfig').mockImplementation(() => {
        assignmentWizard.store.allDueDates = [
          { label: 'Aug 11', name: '08/11/2020' },
          { label: 'Sep 14', name: '09/14/2020' },
          { label: 'Aug 8', name: '08/08/2020' },
        ];
      });
      assignmentWizard.store.learningTracks = { tracks: {}};
      assignmentWizard.store.strands = [];
      assignmentWizard.store.unitRange = new UnitRange(5, 7);
      await fetchMock.flush(true);
      await flushPromises();
    });

    afterEach(() => fetchMock.restore());

    describe('on assignment wizard load', function() {
      it('sets the course info name and selected track name', function() {
        expect(assignmentWizard.store.courseInfo.name).toEqual('My Description');
        expect(assignmentWizard.store.selectedTrackName).toEqual('My Description');
      });

      it('sets the learning track to be the one imported', function() {
        expect(assignmentWizard.store.learningTrack).toEqual({
          description: 'My Description',
          firstUnitId: 100,
          lastUnitId: 200,
          units: [{ id: 100 }, { id: 200 }],
        });
      });

      it('sets the first and last unit index on the model data', function() {
        expect(assignmentWizard.store.unitRange.firstUnitIndex).toEqual('0');
        expect(assignmentWizard.store.unitRange.lastUnitIndex).toEqual('1');
      });

      it('shows all dates in between the start date and end date', function() {
        jest.runAllTimers();
        expect(assignmentWizard.store.allDueDates).toEqual([
          {
            dayOfWeek: 'Sa',
            label: 'Aug 08',
            locked: true,
            name: '08/08/2020',
            selected: true,
          },
          {
            label: 'Aug 11',
            name: '08/11/2020',
            selected: false,
          },
          {
            dayOfWeek: 'Th',
            label: 'Aug 27',
            locked: true,
            name: '08/27/2020',
            selected: true,
          },
          {
            dayOfWeek: 'Sa',
            label: 'Sep 05',
            locked: true,
            name: '09/05/2020',
            selected: true,
          },
          {
            label: 'Sep 14',
            name: '09/14/2020',
            selected: false,
          },
        ]);
      });

      it('sets a pristine calendar on the model data', function() {
        jest.runAllTimers();
        expect(assignmentWizard.store.calendar).toEqual(importedCalendar);
      });

      it('sends a Rollbar notification if the activities JSON is not current', function() {
        expect(VHL.Common.createJSErrorLog).toHaveBeenCalled();
      });
    });

    describe('#create', function() {
      it('makes a POST request to create assignments', async function() {
        jest.spyOn(CalendarProcessor, 'stripCalendar').mockImplementation(() => 'calendar');
        assignmentWizard.store.allDueDates = [];
        assignmentWizard.store.calendar = {
          calendar: { whateverKey: 'some value' },
        };
        assignmentWizard.store.categories = 'categories';
        assignmentWizard.store.usingPredefinedTrack = false;
        const postUrl = `/instructor/${programId}/course/${courseId}/assignment_wizard.json` +
          `?section_id=${sectionId}`;
        fetchMock.mock({ url: postUrl, response: { status: 200, body: { job_ids: [1] }}});
        spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();

        assignmentWizard.create();
        expect(CalendarProcessor.stripCalendar).toHaveBeenCalledWith({ whateverKey: 'some value' });
      });

      it('adds back in empty due dates', async function() {
        assignmentWizard.store.allDueDates = [{ name: '1/1/2014' }];
        const calendar = {
          '1/7/2014': 'blah',
        };
        jest.spyOn(CalendarProcessor, 'stripCalendar').mockImplementation(() => 'calendar');
        assignmentWizard.store.calendar = { calendar: calendar };
        assignmentWizard.store.categories = 'categories';
        assignmentWizard.store.usingPredefinedTrack = false;
        const postUrl = `/instructor/${programId}/course/${courseId}/assignment_wizard.json` +
          `?section_id=${sectionId}`;
        fetchMock.mock({ url: postUrl, response: { status: 200, body: {}}});
        spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();

        assignmentWizard.create();
        expect(CalendarProcessor.stripCalendar).toHaveBeenCalledWith({
          '1/7/2014': 'blah',
          '1/1/2014': [],
        });
      });

      describe('when using a predefined track', function() {
        it('reassigns the category of each assignment to its group name', async function() {
          jest.spyOn(CalendarProcessor, 'stripCalendar').mockImplementation(() => 'calendar');
          assignmentWizard.store.allDueDates = [];
          assignmentWizard.store.usingPredefinedTrack = true;
          assignmentWizard.store.calendar = {
            calendar: { whateverKey: 'some value' },
          };
          const postUrl = `/instructor/${programId}/course/${courseId}/assignment_wizard.json` +
            `?section_id=${sectionId}`;
          fetchMock.mock({ url: postUrl, response: { status: 200, body: {}}});
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();

          assignmentWizard.create();
          expect(CalendarProcessor.stripCalendar).toHaveBeenCalledWith(
            { whateverKey: 'some value' }, jasmine.any(Function)
          );
        });
      });
    });

    describe('on assignment_calendar_refresh event', function() {
      it('sets the calendar on the model data', function() {
        const expectedCalendar = {
          groupNames: ['Learn', 'Practice'],
          categories: [{ 'Category 1': 'blah', 'Category 2': 'blah' }],
        };
        dispatchCustomEvent({
          name: 'assignment_calendar_refresh',
          detail: { calendar: expectedCalendar },
        });
        expect(assignmentWizard.store.calendar).toEqual(expectedCalendar);
      });

      describe('when using a predefined track', function() {
        it('sets categories and category mappling on the model data', function() {
          assignmentWizard.store.usingPredefinedTrack = true;
          const expectedCalendar = {
            groupNames: ['Learn', 'Practice'],
            categories: [{ 'Category 1': 'blah', 'Category 2': 'blah' }],
          };
          dispatchCustomEvent({
            name: 'assignment_calendar_refresh',
            detail: { calendar: expectedCalendar },
          });
          expect(assignmentWizard.store.categories).toEqual({
            'Learn': undefined,
            'Practice': undefined,
          });
          const expectedCategoryMappingList = [
            'Explore',
            'Learn',
            'Practice',
            'Communicate',
            'Self-check',
            'Assessment',
            'Build your skills',
          ];
          expect(assignmentWizard.store.categoryMappingList).toEqual(expectedCategoryMappingList);
        });
      });

      describe('when not using a predefined track', function() {
        it('sets categories and category mappling on the model data', function() {
          assignmentWizard.store.usingPredefinedTrack = false;
          const expectedCalendar = {
            groupNames: ['Learn', 'Practice'],
            categories: { 'Category 1': 'blah', 'Category 2': 'blah' },
          };
          dispatchCustomEvent({
            name: 'assignment_calendar_refresh',
            detail: { calendar: expectedCalendar },
          });
          expect(assignmentWizard.store.categories).toEqual({
            'Category 1': undefined,
            'Category 2': undefined,
          });
          expect(assignmentWizard.store.categoryMappingList).toEqual(['Category 1', 'Category 2']);
        });
      });
    });
  });
});
