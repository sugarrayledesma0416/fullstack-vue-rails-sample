import { mount } from '@vue/test-utils';
import ExampleDialog from './ExampleDialog.vue';

describe('ExampleDialog', () => {
  let wrapper;
  const defaultProps = {
    title: 'Test Dialog',
    imageSrc: '/test-image.jpg',
    dialogClass: 'test-dialog'
  };

  beforeEach(() => {
    // Mock document.querySelector for dialog operations
    vi.spyOn(document, 'querySelector').mockImplementation((selector) => ({
      hide: vi.fn()
    }));

    wrapper = mount(ExampleDialog, {
      props: defaultProps
    });
  });

  describe('rendering', () => {
    it('renders the dialog with correct title', () => {
      expect(wrapper.find('.c-heading-v3--2').text()).toBe('Test Dialog');
    });

    it('renders the image with correct src and alt', () => {
      const img = wrapper.find('img');
      expect(img.attributes('src')).toBe('/test-image.jpg');
      expect(img.attributes('alt')).toBe('Test Dialog');
    });

    it('renders the close button', () => {
      const button = wrapper.find('button');
      expect(button.text()).toBe('Close');
      expect(button.classes()).toContain('c-button-v3--primary');
    });

    it('applies the dialog class', () => {
      expect(wrapper.find('sl-dialog').attributes('class')).toBe('test-dialog');
    });

    it('sets the dialog width', () => {
      expect(wrapper.find('sl-dialog').attributes('style')).toBe('--width: 600px;');
    });
  });

  describe('dialog functionality', () => {
    it('closes the dialog when close button is clicked', async () => {
      const button = wrapper.find('button');
      await button.trigger('click');
      expect(document.querySelector).toHaveBeenCalledWith('.test-dialog');
    });

    it('renders the footer with centered button', () => {
      const footer = wrapper.find('div[slot="footer"]');
      expect(footer.classes()).toContain('u-dis-flex');
      expect(footer.classes()).toContain('u-justify-content-center');
    });
  });

  describe('props validation', () => {
    it('requires title prop', () => {
      expect(ExampleDialog.props.title.required).toBe(true);
    });

    it('requires imageSrc prop', () => {
      expect(ExampleDialog.props.imageSrc.required).toBe(true);
    });

    it('requires dialogClass prop', () => {
      expect(ExampleDialog.props.dialogClass.required).toBe(true);
    });
  });
});
