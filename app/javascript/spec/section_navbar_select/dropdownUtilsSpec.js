import { handleSectionChange } from '../../src/features/section_navbar_select/dropdown_utils.js';

describe('handleSectionChange', () => {
  beforeEach(() => {
    delete window.location;
    window.location = { href: '' };
  });

  it('should redirect to the selected URL', () => {
    const event = {
      target: { value: 'http://example.com/course-section' }
    };

    handleSectionChange(event);

    expect(window.location.href).toBe('http://example.com/course-section');
  });

  it('should not redirect if no value is selected', () => {
    const event = {
      target: { value: '' }
    };

    handleSectionChange(event);

    expect(window.location.href).toBe('');
  });
});
