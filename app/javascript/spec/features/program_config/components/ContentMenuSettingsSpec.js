import { shallowMount } from '@vue/test-utils';
import ContentMenuSettings from 'features/program_config/components/ContentMenuSettings';

const contentMenuSettings = {
  additionalEntries: [],
  ebook: 'ebook value',
  teacherVtextLabel: 'teacher vText label',
  teacherVtextUrl: 'abc.com/teacher-vtext-url',
  vocabTools: 'vocab tools title',
  vocabToolsEnabled: true,
  vtextLabel: 'vText label',
  vtextType: 'eCompanion',
  vtextUrl: 'abc.com/vtext-url',
};

const contentMenuSettingsWith2Entries = {
  ...contentMenuSettings,
  ...{
    additionalEntries: [
      {},
      {},
    ],
  },
};

let wrapper;
const getWrapper = (propsData) => {
  return shallowMount(ContentMenuSettings, {
    global: {
      provide: { programId: 1 },
    },
    propsData,
    stubs: ['AdditionalEntry'],
  });
};

/**
 * This method simulates 'change' event in the checkbox with the given css selector
 * @param {string} elmSelector - Css selector for checkbox
 */
const triggerChangeInCheckbox = async (elmSelector) => {
  const checkbox = wrapper.find(elmSelector);
  await checkbox.trigger('click');
  await checkbox.trigger('change');
};

describe('Content Menu Settings in Program Config', () => {
  describe('When additional entries are not present', () => {
    beforeEach(() => wrapper = getWrapper(contentMenuSettings));

    it('contains "Vocabulary Tools" checkbox', () => {
      expect(wrapper.find('.test-vocab-tools').element.checked).toBeTruthy();
    });

    it('contains input to override Vocab tools title for Content Menu', () => {
      expect(wrapper.find('.test-input-vocab-tools').element.value).toBe('vocab tools title');
    });

    it('contains input to override eBook title for Content Menu', () => {
      expect(wrapper.find('.test-input-ebook').element.value).toBe('ebook value');
    });

    it('contains input for virtual textbook type', () => {
      expect(wrapper.find('.test-input-vtext-type').element.value).toBe('eCompanion');
    });

    it('contains input for the virtual textbook url', () => {
      expect(wrapper.find('.test-input-vtext-url').element.value).toBe('abc.com/vtext-url');
    });

    it('contains input to override virtual textbook label for Content Menu', () => {
      expect(wrapper.find('.test-input-vtext-label').element.value).toBe('vText label');
    });

    it('contains input for teacher edition vText url', () => {
      expect(
        wrapper.find('.test-input-teacher-vtext-url'
        ).element.value).toBe('abc.com/teacher-vtext-url');
    });

    it('contains input to override Instructor Manual label for Content Menu', () => {
      expect(
        wrapper.find('.test-input-teacher-vtext-label').element.value
      ).toBe('teacher vText label');
    });

    it('displays 1 "AdditionalEntry" component', () => {
      expect(wrapper.findAllComponents({ name: 'AdditionalEntry' })).toHaveLength(1);
    });

    it('contains "Add Additional Entry" button', () => {
      expect(wrapper.find('.test-add-additional-entry').exists()).toBeTruthy();
    });

    it('triggers event "updateHideTranslation" when "Vocabulary Tools" checkbox is clicked',
      async () => {
        await triggerChangeInCheckbox('.test-vocab-tools');
        expect(wrapper.emitted('updateHideTranslation')).toHaveLength(1);
      });
  });

  describe('When additional entries are present', () => {
    beforeEach(() => {
      wrapper = getWrapper(contentMenuSettingsWith2Entries);
    });

    it('displays 2 "AdditionalEntry" component', () => {
      expect(wrapper.findAllComponents({ name: 'AdditionalEntry' })).toHaveLength(2);
    });
  });

  describe('I can add more additional entries', () => {
    beforeEach(async () => {
      wrapper = getWrapper(contentMenuSettings);
      const addButton = wrapper.find('.test-add-additional-entry');
      await addButton.trigger('click');
    });

    it('displays 2 "AdditionalEntry" components', () => {
      expect(wrapper.findAllComponents({ name: 'AdditionalEntry' })).toHaveLength(2);
    });
  });

  describe('I can remove additional entries', () => {
    beforeEach(async () => {
      wrapper = getWrapper(contentMenuSettingsWith2Entries);
      const comp = wrapper.findComponent({ name: 'AdditionalEntry' });
      await comp.vm.$emit('removeAdditionalEntry', { entryIndex: 0 });
    });

    it('removes one "AdditionalEntry" component when receives "removeAdditionalEntry" ' +
      'event from it"', () => {
      expect(wrapper.findAllComponents({ name: 'AdditionalEntry' })).toHaveLength(1);
    });
  });
});
