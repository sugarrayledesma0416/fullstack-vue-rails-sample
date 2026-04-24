import { mount } from '@vue/test-utils';
import SettingsDropdown from './SettingsDropdown.vue';

describe('SettingsDropdown', () => {
  let wrapper;
  const defaultProps = {
    'data-testid': 'test-dropdown',
    'aria-label': 'Test dropdown',
    buttonLabel: 'Test Button',
    disabled: false
  };

  beforeEach(() => {
    wrapper = mount(SettingsDropdown, {
      props: defaultProps,
      slots: {
        default: [
          // Using divs instead of sl-menu-item to avoid custom element issues in test.
          '<div data-testid="option">Option 1</div>',
          '<div data-testid="option">Option 2</div>',
        ]
      }
    });
  });

  describe('rendering', () => {
    it('renders with correct props', () => {
      const dropdown = wrapper.find('sl-dropdown');
      expect(dropdown.attributes('data-testid')).toBe('test-dropdown');
      expect(dropdown.attributes('aria-label')).toBe('Test dropdown');
      expect(wrapper.find('button').text()).toContain('Test Button');
    });

    it('renders menu items from slot', () => {
      const menuItems = wrapper.findAll('[data-testid="option"]');
      expect(menuItems).toHaveLength(2);
      expect(menuItems[0].text()).toBe('Option 1');
      expect(menuItems[1].text()).toBe('Option 2');
    });

    it('shows tooltip when disabled', async () => {
      await wrapper.setProps({ disabled: true });
      const trigger = wrapper.find('[data-testid="settings-dropdown-trigger"]');
      expect(trigger.element.tagName.toLowerCase()).toBe('sl-tooltip');
      expect(trigger.attributes('content')).toBe('Select at least one student to apply settings.');
    });

    it('does not show tooltip when enabled', () => {
      const trigger = wrapper.find('[data-testid="settings-dropdown-trigger"]');
      expect(trigger.element.tagName.toLowerCase()).toBe('div');
    });
  });

  describe('aria-expanded functionality', () => {
    it('sets aria-expanded to true when dropdown is shown', async () => {
      const button = wrapper.find('button');

      // Initially aria-expanded should be false
      expect(button.attributes('aria-expanded')).toBe('false');

      // Trigger show event
      await wrapper.find('sl-dropdown').trigger('sl-show');

      // After show, aria-expanded should be true
      expect(button.attributes('aria-expanded')).toBe('true');
    });

    it('sets aria-expanded to false when dropdown is hidden', async () => {
      const button = wrapper.find('button');

      // First show the dropdown
      await wrapper.find('sl-dropdown').trigger('sl-show');
      expect(button.attributes('aria-expanded')).toBe('true');

      // Then hide it
      await wrapper.find('sl-dropdown').trigger('sl-hide');

      // After hide, aria-expanded should be false
      expect(button.attributes('aria-expanded')).toBe('false');
    });
  });

  describe('events', () => {
    it('emits select event when menu item is selected', async () => {
      await wrapper.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'option1' } }
      });

      expect(wrapper.emitted('select')).toBeTruthy();
      expect(wrapper.emitted('select')[0][0].detail).toEqual({
        item: { value: 'option1' }
      });
    });

    it('does not emit select event when disabled', async () => {
      await wrapper.setProps({ disabled: true });
      await wrapper.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'option1' } }
      });

      expect(wrapper.emitted('select')).toBeFalsy();
    });
  });
});
