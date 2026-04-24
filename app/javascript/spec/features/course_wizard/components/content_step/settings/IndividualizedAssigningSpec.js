import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import IndividualizedAssigning from
  'features/course_wizard/components/content_step/settings/IndividualizedAssigning';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const courseOptionsResponse = { components: [], levels: [], settings: [] };

/**
 * This method gets wrapper for IndividualizedAssigning component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(IndividualizedAssigning, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

let wrapper;
let config;
let course;
let courseDataStore;
describe('IndividualizedAssigning', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      config = {
        instAdmin: false,
        programId: 79,
        schoolId: 100,
        isEnterprise: false,
      };
      course = new Course();
      courseDataStore = new CourseDataStore(
        course,
        config.instAdmin,
        config.isEnterprise,
        config.programId,
        config.schoolId
      );
      course.schoolId = 101;
      course.level = 1;
      courseDataStore.store.courseOptions = {
        available_course_packages: null,
        levels: [{ id: 1, name: 'level 1' }, { id: 2, name: 'level 2' }],
        components: [{ id: 11, name: 'component 1' }, { id: 12, name: 'component 2' }],
        schools: [{ id: 101, name: 'School 1' }, { id: 102, name: 'School 1' }],
      };
    });

    describe('Individualized Assigning section', () => {
      beforeEach(() => {
        wrapper = getWrapper();
      });

      it('displays "Allow Individualized Assigning" checkbox', () => {
        expect(wrapper.find('.test-allow-individual-assign-checkbox').exists()).toBeTruthy();
      });

      it('is checked', () => {
        expect(wrapper.find('.test-allow-individual-assign-checkbox').element.checked).toBeTruthy();
      });

      describe('When there are already individual assignments', () => {
        beforeEach(() => {
          courseDataStore.editCourseMode = true;
          courseDataStore.store.courseHasIndividualAssignments = true;
        });

        it('displays "Allow Individualized Assigning" checkbox disabled', () => {
          expect(wrapper.get('.test-allow-individual-assign-checkbox').element).toBeDisabled;
        });

        it('displays a tooltip explaining why the checkbox is disabled', () => {
          const disabledIndAssignMsg = 'This setting is disabled because you already have ' +
                'individually assigned activities in your course.';
          const title = wrapper.find('.checkbox-container').attributes('title');
          expect(title).toEqual(disabledIndAssignMsg);
        });
      });

      describe('When there are no individual assignments', () => {
        beforeEach(() => {
          courseDataStore.editCourseMode = true;
          courseDataStore.store.courseHasIndividualAssignments = false;
        });

        it('displays "Allow Individualized Assigning" checkbox enabled', () => {
          expect(wrapper.get('.test-allow-individual-assign-checkbox').element).toBeEnabled;
        });

        it('does not display a tooltip message', () => {
          const title = wrapper.find('.checkbox-container').attributes('title');
          expect(title).toEqual('');
        });
      });


      describe('Loader message for "Allow Individualized Assigning" in edit course mode', () => {
        beforeEach(() => {
          courseDataStore.editCourseMode = true;
        });
        describe('when Content Step Data is not loaded ', () => {
          beforeEach(() => {
            courseDataStore.store.contentStepDataFetchState = 'loading';
          });

          it('displays loader message', () => {
            expect(wrapper.find('.test-individual-assign-loading').exists()).toBeTruthy();
          });

          it('displays "Allow Individualized Assigning" checkbox disabled', () => {
            expect(wrapper.get('.test-allow-individual-assign-checkbox').element).toBeDisabled;
          });
        });

        describe('when Content Step Data is loaded and courseHasIndividualAssignments ' +
          'is true', () => {
          beforeEach(() => {
            courseDataStore.store.contentStepDataFetchState = 'success';
            courseDataStore.store.courseHasIndividualAssignments = true;
          });

          it('does not display loader message', () => {
            expect(wrapper.find('.test-individual-assign-loading').exists()).toBeFalsy();
          });

          it('displays "Allow Individualized Assigning" checkbox enabled', () => {
            expect(wrapper.get('.test-allow-individual-assign-checkbox').element).toBeEnabled;
          });
        });

        describe('when there is some error while fetching Content Step Data', () => {
          beforeEach(() => {
            courseDataStore.store.contentStepDataFetchState = 'error';
          });

          it('does not display loader message', () => {
            expect(wrapper.find('.test-individual-assign-loading').exists()).toBeFalsy();
          });

          it('displays "Allow Individualized Assigning" checkbox disabled', () => {
            expect(wrapper.get('.test-allow-individual-assign-checkbox').element).toBeDisabled;
          });
        });
      });
    });
  });
});
