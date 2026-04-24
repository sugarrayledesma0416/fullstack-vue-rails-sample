import CourseHttp from 'features/course_wizard/services/course_http';
import CourseSerializer from 'features/course_wizard/services/course_serializer';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

jest.mock('features/learning_tracks/models/calendar_processor', () => {
  return { stripCalendar() {
    return 'calendar';
  } };
});

const options = {
  instAdmin: false,
  schoolId: 1,
  programId: 2,
};

const course = {
  id: 3,
  categories: [],
  removed_categories: [],
};

let courseData;

const calendar = {
  calendar: 'calendar',
  course_package_ids: [1],
  categories: [{ name: 'Foo' }],
};

let courseHttp;

delete window.location;
window.location = new URL('http://example.com');
window.location.replace = jest.fn();

const instAdminBaseUrl =
     `/institution_admin/${options.programId}/school/${options.schoolId}/course_templates`;
const instructorBaseUrl = `/instructor/${options.programId}/courses`;

describe('CourseHttp', () => {
  describe('#destroy', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'deleteFromEndpoint').and.callThrough();
          fetchMock.mock(
            `${instAdminBaseUrl}/${course.id}`, { status: 200, body: {}}
          );
          options.instAdmin = true;
          courseHttp = new CourseHttp(options);
          courseHttp.destroy(course);
        }
      );

      it('sends a delete request with institute admin base url', () => {
        expect(ajaxUtils.deleteFromEndpoint).toHaveBeenCalledWith(
          `${instAdminBaseUrl}/${course.id}`,
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'deleteFromEndpoint').and.callThrough();
          fetchMock.mock(
            `${instructorBaseUrl}/${course.id}`, { status: 200, body: {}}
          );
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.destroy(course);
        }
      );

      it('sends a delete request with the instructor base url', () => {
        expect(ajaxUtils.deleteFromEndpoint).toHaveBeenCalledWith(
          `${instructorBaseUrl}/${course.id}`,
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });
  });

  describe('#expressCreate', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instAdminBaseUrl}/express_create.json`, { status: 200, body: {}}
          );
          options.instAdmin = true;
          courseHttp = new CourseHttp(options);
          courseHttp.expressCreate(course, calendar);
        }
      );

      it('sends a post request with institute admin base url, course and calendar' +
         'for course creation', () => {
        expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
          `${instAdminBaseUrl}/express_create.json`,
          jasmine.any(Object),
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instructorBaseUrl}/express_create.json`, { status: 200, body: {}}
          );
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.expressCreate(course, calendar);
        }
      );

      it('sends a post request with the instructor base url, course and calendar' +
         'for course creation', () => {
        expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
          `${instructorBaseUrl}/express_create.json`,
          jasmine.any(Object),
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });

    describe('when the calendar is undefined', () => {
      beforeEach(
        () => {
          // This is a valid use case when there are
          // only external assignments in a source section.
          const undefined_calendar = {
            calendar: undefined,
            srcSectionId: 1,
            copyIgc: true,
          };
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instructorBaseUrl}/express_create.json`, { status: 200, body: {}}
          );
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.expressCreate(course, undefined_calendar);
        }
      );

      it('sends a post request with the instructor base url, course and calendar' +
         'for course creation', () => {
           expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
             `${instructorBaseUrl}/express_create.json`,
             jasmine.any(Object),
             jasmine.any(Function)
           );
         });

      afterEach(() => fetchMock.restore());
    });
  });

  describe('#gotoSectionWizard', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          options.instAdmin = true;
          courseHttp = new CourseHttp(options);
          courseHttp.gotoSectionWizard(course);
        }
      );

      it('redirects to the institute section wizard', () => {
        expect(window.location.replace).toHaveBeenCalledWith(
          `/institution_admin/${options.programId}/school/${options.schoolId}/courses/${course.id}/sections/new`
        );
      });
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.gotoSectionWizard(course);
        }
      );

      it('redirects to the instructor section wizard', () => {
        expect(window.location.replace).toHaveBeenCalledWith(
          `/instructor/${options.programId}/courses/${course.id}/sections/new`
        );
      });
    });
  });

  describe('#returnToDashboard', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          options.instAdmin = true;
          courseHttp = new CourseHttp(options);
          courseHttp.returnToDashboard(course);
        }
      );

      it('redirects to the institute admin dashboard path', () => {
        expect(window.location.replace).toHaveBeenCalledWith(
          `/institution_admin/templates/${options.programId}?school_id=${options.schoolId}` +
          `&template_id=${course.id}`
        );
      });
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.returnToDashboard(course);
        }
      );

      it('redirects to the instructor dashboard path', () => {
        expect(window.location.replace).toHaveBeenCalledWith(
          `/instructor/dashboard/${options.programId}`
        );
      });
    });
  });

  describe('#save', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instAdminBaseUrl}.json`, { status: 200, body: { id: course.id }}
          );
          options.instAdmin = true;
          const courseSerializer = new CourseSerializer(course);
          courseData = courseSerializer.serialize();
          courseHttp = new CourseHttp(options);
          courseHttp.save(course);
        }
      );

      it('makes a post request with institute admin base url to create new course', () => {
        expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
          `${instAdminBaseUrl}.json`,
          courseData,
          jasmine.any(Function), // resolve
          jasmine.any(Function) // reject
        );
      });

      afterEach(() => fetchMock.restore());
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instructorBaseUrl}.json`, { status: 200, body: { id: course.id }}
          );
          options.instAdmin = false;
          const courseSerializer = new CourseSerializer(course);
          courseData = courseSerializer.serialize();
          courseHttp = new CourseHttp(options);
          courseHttp.save(course);
        }
      );

      it('makes a post request with instructor base url to create new course', () => {
        expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
          `${instructorBaseUrl}.json`,
          courseData,
          jasmine.any(Function), // resolve
          jasmine.any(Function) // reject
        );
      });

      afterEach(() => fetchMock.restore());
    });
  });

  describe('#update', () => {
    describe('when instAdmin is true', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'putToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instAdminBaseUrl}/${course.id}.json`, { status: 200, body: {}}
          );
          options.instAdmin = true;
          courseHttp = new CourseHttp(options);
          courseHttp.update(course);
        }
      );

      it('sends a put request with institute admin base url', () => {
        expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
          `${instAdminBaseUrl}/${course.id}.json`,
          jasmine.any(Object),
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });

    describe('when instAdmin is false', () => {
      beforeEach(
        () => {
          spyOn(ajaxUtils, 'putToEndpoint').and.callThrough();
          fetchMock.mock(
            `${instructorBaseUrl}/${course.id}.json`, { status: 200, body: {}}
          );
          options.instAdmin = false;
          courseHttp = new CourseHttp(options);
          courseHttp.update(course);
        }
      );

      it('sends a put request with the instructor base url', () => {
        expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
          `${instructorBaseUrl}/${course.id}.json`,
          jasmine.any(Object),
          jasmine.any(Function)
        );
      });

      afterEach(() => fetchMock.restore());
    });
  });

  describe('#getContentStepData', () => {
    const contentStepDataUrl = 'http://example.com/content_step.json';
    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(
          contentStepDataUrl,
          { status: 200, body: {}}
        );
        courseHttp = new CourseHttp(options);
        courseHttp.getContentStepData(course.id);
      }
    );

    it('sends a get request on content step data url', () => {
      expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
        contentStepDataUrl,
        jasmine.any(Function)
      );
    });

    afterEach(() => fetchMock.restore());
  });
});
