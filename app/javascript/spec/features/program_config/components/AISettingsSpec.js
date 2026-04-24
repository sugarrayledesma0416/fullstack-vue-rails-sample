import { mount } from '@vue/test-utils';
import AISettings from 'features/program_config/components/AISettings';

/**
 * This method returns props for the AISettings component
 * @param {boolean} checked - Boolean value for checkbox
 * @param {String} programLevelVal - String value for program level
 * @return {Object} - Props for the AISettings component
 */
const getAISettings = (checked, programLevelVal) => {
  return {
    gradingSuggestions: checked,
    programLevel: programLevelVal || '',
  };
};

let wrapper;
const getWrapper = (propsData) => mount(AISettings, { propsData });

/**
 * This method returns whether the checkbox with the given css selector is checked
 * in the wrapper
 * @param {string} elmSelector - css selector for checkbox
 * @return {boolean} - whether the checkbox is checked
 */
const getCheckedState = (elmSelector) => {
  return wrapper.get(elmSelector).element.checked;
};

describe('AI Settings in Program Config', () => {
  describe('when the grading_suggestions_enabled configuration option is set to false', () => {
    beforeEach(() => {
      const aiSettings = getAISettings(false);
      wrapper = getWrapper(aiSettings);
    });

    it('contains an unchecked checkbox to configure "Grading Suggestions"',
      () => {
        expect(getCheckedState('.test-datastore-ai-settings-grading-suggestions')).toBeFalsy();
      }
    );

    it('contains an enabled dropdown to select the program level', () => {
      const programLevelEl = wrapper.find('#datastore_ai_settings_program_level');
      expect(programLevelEl.element.disabled).toBeFalsy();
    });
  });

  describe('when the grading_configuration_option is set to true', () => {
    beforeEach(() => {
      const aiSettings = getAISettings(true);
      wrapper = getWrapper(aiSettings);
    });

    it('contains a checked checkbox to configure "Grading Suggestions"',
      () => {
        expect(getCheckedState('.test-datastore-ai-settings-grading-suggestions')).toBeTruthy();
      }
    );

    it('contains an enabled dropdown to select the program level', () => {
      const programLevelEl = wrapper.find('#datastore_ai_settings_program_level');
      expect(programLevelEl.element.disabled).toBeFalsy();
    });
  });

  describe('when the program level is set to blank', () => {
    beforeEach(() => {
      const aiSettings = getAISettings(false, '');
      wrapper = getWrapper(aiSettings);
    });

    it('contains a dropdown with "Select Level" selected', () => {
      const programLevelEl = wrapper.find('#datastore_ai_settings_program_level');
      const emptyOptionEl = programLevelEl.find('option[value=""]');
      expect(programLevelEl.element.value).toBe('');
      expect(emptyOptionEl.text()).toBe('Select Level');
    });
  });

  describe('when the program level is set to a valid non-blank value', () => {
    const programLevel = 'intermediate';

    beforeEach(() => {
      const aiSettings = getAISettings(false, programLevel);
      wrapper = getWrapper(aiSettings);
    });

    it('contains a dropdown with the selected program level', () => {
      const programLevelEl = wrapper.find('#datastore_ai_settings_program_level');
      const optionEl = programLevelEl.find('option[value="' + programLevel + '"]');
      expect(programLevelEl.element.value).toBe(programLevel);
      expect(optionEl.text()).toBe(programLevel);
    });
  });
});
