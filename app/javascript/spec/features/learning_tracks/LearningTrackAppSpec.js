import { shallowMount } from '@vue/test-utils';
import { reactive } from 'vue';
import fetchMock from 'fetch-mock';
import LearningTrackApp from 'features/learning_tracks/LearningTrackApp';
import UnitRange from 'features/learning_tracks/models/unit_range';
import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';

const loadingIconPath = '/images/loading_32.gif';
const parentModel = {
  store: reactive({
    sectionSource: { type: 'section' },
    learningTracksConfig: { chooseTrack: true },
    unitRange: new UnitRange(),
    selectedTrackName: 'Track 1',
  }),
};

const assignmentCalendar = new AssignmentCalendar();
const config = { instAdmin: false, programId: 79 };

const getWrapper = () => {
  return shallowMount(LearningTrackApp, {
    global: {
      provide: { assignmentCalendar, config },
    },
    props: { loadingIconPath, parentModel },
  });
};

let wrapper;

describe('LearningTrackApp', () => {
  beforeEach(() => {
    fetchMock.mock(
      `/instructor/${config.programId}/learning_tracks.json`,
      { status: 200, body: { strands: {}, tracks: {}}}
    );
    wrapper = getWrapper();
  });

  afterEach(() => fetchMock.restore());

  it('displays "ChooseTemplate" component', () => {
    expect(wrapper.findComponent({ name: 'ChooseTemplate' }).exists()).toBeTruthy();
  });

  it('displays "SelectContent" component', () => {
    expect(wrapper.findComponent({ name: 'SelectContent' }).exists()).toBeTruthy();
  });

  it('displays "DueDatesStep" component', () => {
    expect(wrapper.findComponent({ name: 'DueDatesStep' }).exists()).toBeTruthy();
  });

  it('displays "ReviewAssignmentsStep" component', () => {
    expect(wrapper.findComponent({ name: 'ReviewAssignmentsStep' }).exists()).toBeTruthy();
  });
});
