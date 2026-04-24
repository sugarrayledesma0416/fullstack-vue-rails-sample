import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import Components from
  'features/course_wizard/components/content_step/settings/Components';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const courseOptionsResponse = { components: [], levels: [], settings: [] };

/**
 * This method gets wrapper for Components component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Components, {
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
describe('Components', () => {
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
        isEnterprise: false
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
        components: [
          { id: 11, 
            name: 'component 1', 
            license_groups: [
              {id: 3, name: 'WebSAM'}, {id: 26, name: 'Portfolio'}
            ]
          }, 
          { id: 12, 
            name: 'component 2',
            license_groups: [
              {id: 1, name: '01-Supersite'}
            ]
          }
        ],
        schools: [{ id: 101, name: 'School 1' }, { id: 102, name: 'School 1' }],
      };
    });

    describe('Components section', () => {
      describe('when available_course_packages is null and canShareToPortfolio is false', () => {
        beforeEach(() => {
          courseDataStore.store.courseOptions.available_course_packages = null;
          wrapper = getWrapper();
        });

        it('displays the checkbox for the component that does not have Portfolio license group', () => {
          expect(wrapper.findAll('.test-component-checkbox').length).toBe(1);
        });
      });

      describe('when a component has Portfolio license group and canShareToPortfolio is true', () => {
        beforeEach(() => {
          course.canShareToPortfolio = true;
          wrapper = getWrapper();
        });

        it('displays the checkbox for the component that has Portfolio license group', () => {
          expect(wrapper.findAll('.test-portfolio-comp').length).toBe(1);
        });
      });

      describe('when the components have no Portfolio license group', () => {
        beforeEach(() => {
          course.canShareToPortfolio = true;
          courseDataStore.store.courseOptions = {
            available_course_packages: null,
            components: [
              { id: 11, 
                name: 'component 1', 
                license_groups: [
                  {id: 3, name: 'WebSAM'}
                ]
              }, 
              { id: 12, 
                name: 'component 2',
                license_groups: [
                  {id: 1, name: '01-Supersite'}
                ]
              }
            ],
            schools: [{ id: 101, name: 'School 1' }],
          };
          wrapper = getWrapper();
        });

        it('does not display the checkbox of the components that have Portfolio license group', () => {
          expect(wrapper.findAll('.test-portfolio-comp').length).toBe(0);
        });
      });
    });
  });
});
