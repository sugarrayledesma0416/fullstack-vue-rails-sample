import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import ReferenceToolSettings from 'features/program_config/components/ReferenceToolSettings';

const currentSettings = reactive([
  { label: 'Vocabulary Tools', link: '/79/vocab_tools/units', type: 'link' },
  { label: '', link: '', type: 'link' },
]);

const getWrapper = () => {
  return mount(ReferenceToolSettings, {
    props: { currentSettings },
  });
};

let wrapper;

describe('Reference Tool Settings in Program Config', () => {
  describe('I see two default settings for reference tools of a program', () => {
    beforeEach(() => wrapper = getWrapper());

    it('contains "Add Setting" button', () => {
      expect(wrapper.find('.test-add-ref-setting').exists()).toBeTruthy();
    });

    it('contains default configuration for "Vocabulary Tools"', () => {
      expect(
        wrapper.find('.test-setting-label-0').element.value
      ).toBe(currentSettings[0].label);

      expect(
        wrapper.find('.test-setting-link-0').element.value
      ).toBe(currentSettings[0].link);
    });

    it('contains default 2 remove setting buttons', () => {
      expect(wrapper.findAll('.test-remove-setting-btn')).toHaveLength(2);
    });
  });

  describe('I can add more settings in a reference tools for a program', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.find('.test-setting-label-1').setValue('Reference Tool 1');
      await wrapper.find('.test-setting-link-1').setValue('/79/reference_tool/1');
    });

    it('contains the custom added reference tool settings', () => {
      expect(
        wrapper.find('.test-setting-label-1').element.value
      ).toBe('Reference Tool 1');

      expect(
        wrapper.find('.test-setting-link-1').element.value
      ).toBe('/79/reference_tool/1');
    });
  });

  describe('I can remove a setting in a reference tools for a program', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-remove-ref-setting-0').trigger('click');
    });

    it('does not contains the removed settings of "Vocabulary Tools"', () => {
      expect(
        wrapper.find('.test-setting-label-0').element.value
      ).not.toBe('Vocabulary Tools');

      expect(
        wrapper.find('.test-setting-link-0').element.value
      ).not.toBe('/79/vocab_tools/units');
    });
  });
});
