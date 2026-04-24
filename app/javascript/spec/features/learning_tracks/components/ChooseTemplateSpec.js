import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import ChooseTemplate from 'features/learning_tracks/components/ChooseTemplate';
import UnitRange from 'features/learning_tracks/models/unit_range';
import LearningTrackDataStore from 'features/learning_tracks/learning_track_data_store';

const parentModel = {
  store: reactive({
    sectionSource: { type: 'section' },
    learningTracksConfig: { chooseTrack: true },
    unitRange: new UnitRange(),
    selectedTrackName: 'Track 1',
    learningTrack: {},
  }),
};
const mockLearningTracks = {
  'activities': {
    '42217': { 'id': 42217 },
  },
};
const learningTrackData = new LearningTrackDataStore(parentModel);
const assignmentCalendar = new AssignmentCalendar();
const config = { instAdmin: false, programId: 79 };
let wrapper;

const getWrapper = () => {
  return mount(ChooseTemplate, {
    global: {
      provide: { assignmentCalendar, learningTrackData, config },
      stubs: { PreDefinedTracks: true },
    },
    props: {
      loadingIconPath: '/images/loading.gif',
    },
  });
};

describe('ChooseTemplate', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      learningTrackData.store.expandChooseTemplateAltContent = true;
      learningTrackData.store.expandChooseTemplateStep = true;
      wrapper = getWrapper();
    });

    it('displays the selected track name as "Track 1"', () => {
      expect(wrapper.get('.test-selected-track').text()).toBe('Track 1');
    });

    it('does not displays insufficientLicenseGroups section', () => {
      expect(wrapper.find('.test-insufficient-license-grp').exists()).toBeFalsy();
    });

    it('displays template chooser anchor tag with text "Change course template"', () => {
      expect(wrapper.find('.test-template-chooser').text()).toBe('Change course template');
    });

    it('displays existing course selection with section source as "section"', () => {
      expect(wrapper.find('.test-source-section').exists()).toBeTruthy();
    });

    it('does not displays course selection with section source as "section_template"', () => {
      expect(wrapper.find('.test-source-section-template').exists()).toBeFalsy();
    });

    it('displays section select button as disabled', () => {
      expect(wrapper.get('.test-select-existing-section').element).toBeDisabled();
    });

    it(
      'displays an informacion modal when the individual assignment link is clicked',
      async () => {
        await wrapper.get('.test-show-individual-assignment-information-modal').trigger('click');
        expect(wrapper.get('.test-show-individual-assignment-information-text').text())
          .toBe('When copying individually assigned activities to a new section, ' +
                  'all students in the section will receive these assignments.  ' +
                  'Copying Group Chat activities will also copy over their settings.');
      }
    );
  });

  describe('when "Predefined" is visible', () => {
    beforeEach(() => {
      learningTrackData.store.learningTracks = mockLearningTracks;
      learningTrackData.store.VOL = true;
      wrapper = getWrapper();
    });

    it('renders PreDefinedTracks component', () => {
      expect(wrapper.findComponent({ name: 'PreDefinedTracks' }).exists()).toBeTruthy();
    });
  });

  describe('when "Predefined" is not visible', () => {
    beforeEach(() => {
      learningTrackData.store.learningTracks = mockLearningTracks;
      learningTrackData.store.VOL = false;
      wrapper = getWrapper();
    });

    it('does not renders PreDefinedTracks component', () => {
      expect(wrapper.findComponent({ name: 'PreDefinedTracks' }).exists()).toBeFalsy();
    });
  });
});
