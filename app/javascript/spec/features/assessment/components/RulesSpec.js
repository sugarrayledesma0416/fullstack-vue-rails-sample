import { mount } from '@vue/test-utils';
import Rules from 'features/assessment/components/Rules.vue';

function getWrapper(propsData) {
  return mount(Rules, { propsData });
}

describe('Rules', () => {
  let wrapper;
  describe('Rules component with empty rules', () => {
    beforeEach(() => {
      wrapper = getWrapper({ rules: '[]' });
    });

    it('renders the component', () => {
      expect(wrapper.exists()).toBeTruthy();
    });

    it('renders no list items with empty rules', () => {
      expect(wrapper.findAll('.test-strictness-list-item').length).toBe(0);
    });
  });

  describe('Rules component with non-empty rules', () => {
    let items;
    beforeEach(() => {
      const rules = JSON.stringify([
        { text: 'accents', status: true },
        { text: 'capitalization', status: false },
        { text: 'punctuation', status: true },
      ]);
      wrapper = getWrapper({ rules });
      items = wrapper.findAll('.test-strictness-list-item');
    });

    it('renders correct number of list items with valid rules', () => {
      expect(items.length).toBe(3);
    });

    it('renders list items with correct text, classes, and title for accents', () => {
      expect(items[0].text()).toBe('Extra or missing accent marks WILL NOT affect your score.');
      expect(items[0].classes()).toContain('inactive');
      expect(items[0].classes()).toContain('accents');
      expect(items[0].attributes('title')).toBe('Accents');
    });

    it('renders list items with correct text, classes, and title for capitalization', () => {
      expect(items[1].text()).toBe('Incorrect capitalization WILL affect your score.');
      expect(items[1].classes()).toContain('active');
      expect(items[1].classes()).toContain('capitalization');
      expect(items[1].attributes('title')).toBe('Capitalization');
    });

    it('renders list items with correct text, classes, and title for punctuation', () => {
      expect(items[2].text()).toBe('Punctuation errors WILL NOT affect your score.');
      expect(items[2].classes()).toContain('inactive');
      expect(items[2].classes()).toContain('punctuation');
      expect(items[2].attributes('title')).toBe('Punctuation');
    });
  });

  describe('Rules component with formatted rules', () => {
    let rule;
    beforeEach(() => {
      rule = { text: 'accents', status: true };
      wrapper = getWrapper({ rules: JSON.stringify([rule]) });
    });

    it('formats rules correctly', () => {
      const formattedRule = wrapper.vm.formatRule(rule);
      expect(formattedRule.text).toBe('Extra or missing accent marks WILL NOT affect your score.');
      expect(formattedRule.classes).toBe('inactive accents');
      expect(formattedRule.title).toBe('Accents');
    });
  });
});
