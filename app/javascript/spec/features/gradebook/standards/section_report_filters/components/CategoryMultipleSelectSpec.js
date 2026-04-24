import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import CategoryMultipleSelect from
  'features/gradebook/standards/section_report_filters/components/CategoryMultipleSelect';

const categories = ['Quizzes', 'Unit Test', 'Writing & Reading'];

describe('CategoryMultipleSelect', () => {
  let wrapper;

  function getWrapper(props = {}) {
    return mount(CategoryMultipleSelect, {
      props: {
        categories,
        ...props,
      },
      global: {
        plugins: [
          createTestingPinia({
            stubActions: false,
            initialState: {
              useSectionReportFilterStore: {
                categories,
                isChecked: {},
                isExpanded: false,
              },
            },
          }),
        ],
      },
    });
  }

  beforeEach(() => {
    wrapper = getWrapper();
  });

  it('renders the default dropdown text', () => {
    const text = wrapper.find('.test-disclosure-header-text').text();
    expect(text).toBe('3 Selected');
  });

  it('initially sets the dropdown as collapsed', () => {
    const isExpanded = wrapper.vm.isExpanded;
    expect(isExpanded).toBeFalsy();
  });

  it('updates dropdown text when one category is unselected', async () => {
    const checkbox = wrapper.find('.test-category-checkbox-2');
    await checkbox.setChecked(false);
    await wrapper.vm.$nextTick();

    expect(wrapper.find('.test-disclosure-header-text').text()).toBe('2 Selected');
  });

  it('updates checked state when a category is clicked', async () => {
    const categoryOption = wrapper.find('.test-category-option');
    await categoryOption.trigger('click');
    const checkbox = wrapper.find('.test-category-checkbox-0');

    expect(checkbox.element.checked).toBeTruthy();
  });

  it('collapses the dropdown on outside click', async () => {
    wrapper.vm.isExpanded = true;
    document.body.click(); // Simulate outside click
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.isExpanded).toBeFalsy();
  });

  it('expands the dropdown when clicked', async () => {
    const dropdownButton = wrapper.find('.test-disclosure-button');
    await dropdownButton.trigger('click');

    expect(wrapper.vm.isExpanded).toBeTruthy();
  });

  it('renders all categories when expanded', async () => {
    wrapper.vm.isExpanded = true;
    await wrapper.vm.$nextTick();

    expect(wrapper.findAll('.test-category-option').length).toBe(categories.length);
  });

  describe('when the dropdown is disabled', () => {
    beforeEach(async () => {
      await wrapper.setProps({ categories: [] });
    });

    it('disables the dropdown button', () => {
      expect(
        wrapper.find('.test-disclosure-button').attributes('disabled')
      ).toBeDefined();
    });
  });
});
