import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import VideoSubtitles
  from 'features/course_wizard/components/content_step/settings/VideoSubtitles';

let wrapper;
let config;
let course;
let courseDataStore;

/**
 * This method gets wrapper for AudioTextAndVideoSupports component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(VideoSubtitles, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

describe('ContentStep', () => {
  describe('mounted', () => {
    beforeEach(() => {
      config = {
        instAdmin: false,
        programHasAudioTranscripts: false,
        programId: 79,
        schoolId: 100,
      };
      course = new Course();
      courseDataStore = {
        newCourseMode: true,
        store: reactive({
          course,
          courseOptions: {
            components: [],
            levels: [{ id: 64, name: 'Portales' }],
            program: {
              unit_label: 'Lession',
            },
            units: [
              { id: 1, label: 'Lession 1' },
              { id: 2, label: 'Lession 2' },
            ],
          },
        }),
        save: jest.fn(),
      };
      courseDataStore.store.courseOptions = {
        video_languages: {
          'None': 'none',
          'Spanish': 'foreign',
          'Spanish and English': 'foreign_and_english',
        },
      };

      wrapper = getWrapper();
    });

    describe('Subtitles Select', () => {
      it('displays the subtitle select dropdown', () => {
        expect(wrapper.find('.test-video-subtitles-dropdown').exists()).toBeTruthy();
      });

      it('displays an option for each subtitle language', () => {
        const availableLanguages = courseDataStore.store.courseOptions.video_languages;
        const renderedOptions = wrapper.findAll('.test-option-item');
        expect(renderedOptions.length).toEqual(Object.keys(availableLanguages).length);
      });
    });

    describe('Screenshot', () => {
      it('does not display "Screenshot" component', () => {
        expect(wrapper.findComponent({ name: 'Screenshot' }).exists()).toBeFalsy();
      });

      describe('when "See Example" link is clicked', () => {
        beforeEach(async () => {
          const linkElm = wrapper.get('.test-subtitle-screenshot-link');
          await linkElm.trigger('click');
        });

        it('displays "Screenshot" component', () => {
          expect(wrapper.findComponent({ name: 'Screenshot' }).exists()).toBeTruthy();
        });
      });
    });
  });
});
