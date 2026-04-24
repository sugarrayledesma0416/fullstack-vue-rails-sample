import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
import fetchMock from 'fetch-mock';
import LearningTrackDataStore from 'features/learning_tracks/learning_track_data_store';
import PreDefinedTracks from 'features/learning_tracks/components/PreDefinedTracks';
import useLearningTrack from 'features/learning_tracks/use_learning_track';
import { reactive } from 'vue';
import * as ajaxUtils from 'shared/ajax_utils';
import { mount } from '@vue/test-utils';

VHL = { Music: { V1: {}}};
VHL.Music.V1.Disclosure = jest.fn(() => {});

const parentModel = {
  store: reactive({
    learningTracksConfig: { chooseTrack: true },
    setupDescriptions: {
      learning_tracks: {
        general: 'Learning Tracks are pre-built courses created by curricular experts.',
        header: 'Learning Track',
        options: [
          { label: 'Complete' },
          { label: 'Essentials' },
        ],
        options_overall: '<b>Fotonovela.</b>',
      },
    },
  }),
};

const config = { instAdmin: false, programId: 79 };
const learningTrackData = new LearningTrackDataStore(parentModel);
const assignmentCalendar = new AssignmentCalendar();
let wrapper;

const getLearningTracksJson = {
  strands: { Contextos: { color: '#BE0027', name: 'Contextos' }},
  tracks: {
    Communicative: {
      description: '<b>Supports</b>',
      subtracks: { Complete: {}, Essentials: {}},
    },
  },
};

const getWrapper = () => {
  return mount(PreDefinedTracks, {
    global: { provide: { learningTrackData }},
  });
};

describe('PreDefinedTracks', () => {
  describe('onMounted', () => {
    beforeEach(async () => {
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      fetchMock.mock(
        `/instructor/${config.programId}/learning_tracks.json`,
        { status: 200, body: getLearningTracksJson }
      );

      const { updateDataStore } = useLearningTrack(
        assignmentCalendar, config, learningTrackData
      );
      await updateDataStore();
      wrapper = getWrapper();
    });

    afterEach(() => fetchMock.restore());

    it('displays "VhlExpander" component', () => {
      expect(wrapper.findComponent({ name: 'VhlExpander' }).exists()).toBeTruthy();
    });

    it('displays the header with value "Learning Track"', () => {
      expect(wrapper.get('.test-setup-header').text()).toEqual('Learning Track');
    });

    it('displays the general setup with value "Learning Track"', () => {
      expect(wrapper.get('.test-setup-general').text()).toEqual(
        'Learning Tracks are pre-built courses created by curricular experts.'
      );
    });

    it('displays the heading of expander as "Communicative"', () => {
      const expander = wrapper.findComponent({ name: 'VhlExpander' });
      expect(expander.vm.headerText).toEqual('Communicative');
    });
  });

  describe('when disclosure is opened', () => {
    beforeEach(async () => {
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      fetchMock.mock(
        `/instructor/${config.programId}/learning_tracks.json`,
        { status: 200, body: getLearningTracksJson }
      );

      const { updateDataStore } = useLearningTrack(
        assignmentCalendar, config, learningTrackData
      );
      await updateDataStore();
      wrapper = getWrapper();
      await wrapper.get('.test-vhl-expander').trigger('click');
    });

    afterEach(() => fetchMock.restore());

    it('displays template description as "Supports"', () => {
      expect(wrapper.get('.test-template-description').text()).toEqual('Supports');
    });

    it('displays "Select Complete" button', () => {
      expect(wrapper.find('.test-select-Complete-0').exists()).toBeTruthy();
    });

    it('displays "Select Essentials" button', () => {
      expect(wrapper.find('.test-select-Essentials-1').exists()).toBeTruthy();
    });
  });

  describe('when modal is opened', () => {
    beforeEach(async () => {
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      fetchMock.mock(
        `/instructor/${config.programId}/learning_tracks.json`,
        { status: 200, body: getLearningTracksJson }
      );

      const { updateDataStore } = useLearningTrack(
        assignmentCalendar, config, learningTrackData
      );
      await updateDataStore();
      wrapper = getWrapper();
      await wrapper.get('.test-track-help-model-0').trigger('click');
    });

    afterEach(() => fetchMock.restore());

    it('displays a modal', () => {
      expect(
        wrapper.findComponent({ name: 'ModalComponent' }).exists()
      ).toBeTruthy();
    });

    it('displays the subtracks options overall on the modal', () => {
      expect(wrapper.get('.test-setup-options-overall').text()).toEqual('Fotonovela.');
    });
  });
});
