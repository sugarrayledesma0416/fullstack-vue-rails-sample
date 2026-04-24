import LearningTrackDataStore from 'features/learning_tracks/learning_track_data_store';
import SelectContent from 'features/learning_tracks/components/SelectContent';
import UnitRange from 'features/learning_tracks/models/unit_range';
import { reactive } from 'vue';
import { mount } from '@vue/test-utils';

const parentModel = {
  store: reactive({
    disableAllControls: undefined,
    includeInstructorGradedActivities: true,
    includeMicrophoneActivities: true,
    includePartnerActivities: true,
    learningTracksConfig: { chooseTrack: true },
    strands: undefined,
    unitRange: new UnitRange(),
  }),
};

const learningTrackData = new LearningTrackDataStore(parentModel);
let wrapper;

const getWrapper = () => {
  return mount(SelectContent, {
    global: { provide: { learningTrackData }},
  });
};

describe('SelectContent', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      learningTrackData.store.expandSelectContentStep = true;
      wrapper = getWrapper();
    });

    it('displays "Step 2" component of "Select Content"', () => {
      expect(wrapper.findAll('.test-expanded-body')[0].classes('expanded')).toBeTruthy();
    });

    it('displays "Step 2: Set the content available to assign" text on header', () => {
      expect(wrapper.get('.test-select-content-header').text()).toBe(
        'Step 2: Set the content available to assign'
      );
    });

    it('does not display lesson options', () => {
      expect(wrapper.findAll('.test-expanded-body')[1].classes('expanded')).toBeFalsy();
      expect(wrapper.get('.test-lesson-options').isVisible()).toBeFalsy();
    });

    it('display "Show options"', () => {
      expect(wrapper.get('.test-toggle-lesson-options').text()).toBe('Show options');
    });
  });

  describe('when "Show Options" is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      learningTrackData.parentDataStore.strands = [
        { 'name': 'Pronunciación', 'color': '#76377C', 'selected': true },
        { 'name': 'Estructura 2.11', 'color': '#BE0027', 'selected': true },
        { 'name': 'Contextos', 'color': '#BE0027', 'selected': true },
        { 'name': 'Estructura 2.2', 'color': '#BE0027', 'selected': true },
        { 'name': 'Estructura 1.1', 'color': '#BE0027', 'selected': true },
        { 'name': 'Estructura 1.2', 'color': '#BE0027', 'selected': true },
        { 'name': 'Estructura 11.1', 'color': '#BE0027', 'selected': true },
        { 'name': 'Estructura 2.1', 'color': '#BE0027', 'selected': true },
        { 
          'name': "Connect to Grammar:<br/> <b>can</b> and <b>can't</b>", 
          'selected': true
        }
      ];
      await wrapper.get('.test-toggle-lesson-options').trigger('click');
    });

    it('display lesson options', () => {
      expect(wrapper.get('.test-lesson-options').isVisible()).toBeTruthy();
    });

    it('displays checkbox with text "Instructor-graded"', () => {
      expect(
        wrapper.get('.test-instructor-graded-activities').text()
      ).toBe('Instructor-graded');
    });

    it('displays checkbox with text "Microphone required"', () => {
      expect(
        wrapper.get('.test-include-microphone-activities').text()
      ).toBe('Microphone required');
    });

    it('displays checkbox with text "Partner required"', () => {
      expect(
        wrapper.get('.test-include-partner-activities').text()
      ).toBe('Partner required');
    });

    it('displays the heading of "Strands included"', () => {
      expect(
        wrapper.get('.test-track-substep').text()
      ).toBe('Strands included');
    });
    
    it('displays "Connect to Grammar" as strand without escaped html', () => {
      expect(
        wrapper.get('.test-strand-0').text()
      ).toBe("Connect to Grammar: can and can't");
    });

    it('removes <br> tags from the strand name', () => {
      expect(
        wrapper.get('.test-strand-0 span.test-strand-name').html()
      ).toBe( "<span class=\"u-pad-rt-16 test-strand-name\">Connect to Grammar: <b>can</b> and <b>can't</b></span>");
    });

    it('displays "Contextos" as strand', () => {
      expect(
        wrapper.get('.test-strand-1').text()
      ).toBe('Contextos');
    });

    it('displays "Estructura n.n" strands in the correct order', () => {
      expect(
        wrapper.get('.test-strand-2').text()
      ).toBe('Estructura 1.1');

      expect(
        wrapper.get('.test-strand-3').text()
      ).toBe('Estructura 1.2');

      expect(
        wrapper.get('.test-strand-4').text()
      ).toBe('Estructura 2.1');

      expect(
        wrapper.get('.test-strand-5').text()
      ).toBe('Estructura 2.2');

      expect(
        wrapper.get('.test-strand-6').text()
      ).toBe('Estructura 2.11');

      expect(
        wrapper.get('.test-strand-7').text()
      ).toBe('Estructura 11.1');
    });

    it('displays "Pronunciación" as strand', () => {
      expect(
        wrapper.get('.test-strand-8').text()
      ).toBe('Pronunciación');
    });
  });

  describe('when units are loaded', () => {
    beforeEach(() => {
      learningTrackData.store.units = [{
        'id': 303, 'name': 'Lección 1 | Hola, ¿qué tal? ', 'label': 'Lección 1',
      }];
      wrapper = getWrapper();
    });

    it('displays the length of options as "2" for both start and end range', () => {
      expect(wrapper.get('.test-range-start').findAll('option').length).toEqual(2);
      expect(wrapper.get('.test-range-end').findAll('option').length).toEqual(2);
    });

    it('displays "Lección 1" in the dropdown', () => {
      expect(wrapper.get('.test-range-start').findAll('option')[1].text()).toBe('Lección 1');
      expect(wrapper.get('.test-range-end').findAll('option')[1].text()).toBe('Lección 1');
    });
  });

  describe('select "Lección 1" from a dropdown', () => {
    beforeEach(() => {
      learningTrackData.store.units = [{
        'id': 303, 'name': 'Lección 1 | Hola, ¿qué tal? ', 'index': '1', 'label': 'Lección 1',
      }, {
        'id': 304, 'name': 'Lección 2 | Hola, ¿qué tal? ', 'index': '2', 'label': 'Lección 2',
      }];
      wrapper = getWrapper();

      const selectStart = wrapper.get('.test-range-start');
      const startOptions = selectStart.findAll('option');
      startOptions[1].element.selected = true;

      const selectEnd = wrapper.get('.test-range-end');
      const endOptions = selectEnd.findAll('option');
      endOptions[2].element.selected = true;
    });

    it('displays value of 1 for the start range', () => {
      expect(wrapper.get('.test-range-start').element.value).toBe('1');
    });

    it('displays value of 2 for the end range', () => {
      expect(wrapper.get('.test-range-end').element.value).toBe('2');
    });
  });
});
