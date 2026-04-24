import { mount } from '@vue/test-utils';
import StandardSettings from 'features/program_config/components/StandardSettings';

const props = {
  supportedStandardSetIds: ['1,3'],
  standardsSettingsData: {
    standard_sets_array: [
      { ids: '1,3', name: 'Display name 1' },
      { ids: '2', name: 'Display name 2' },
    ]
  }
};
const getWrapper = () => mount(StandardSettings, {
  props: props
});

describe('Standard Settings in Program Config', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = getWrapper()
  });

  it('contains checkboxes to select supported standard sets', () => {
    expect(wrapper.findAll('.test-supported-standard-set-ids').length).toBeGreaterThan(0);
  });

  it('contains all the existing standard sets as checkboxes', () => {
    const checkboxes = wrapper.findAll('input[type="checkbox"].test-supported-standard-set-ids');
    props.standardsSettingsData['standard_sets_array'].forEach((standardSet, i) => {
      const checkbox = checkboxes[i];
      expect(checkbox.attributes('value')).toEqual(standardSet.ids);
      expect(wrapper.find(`label[for="${standardSet.ids}"]`).text()).toEqual(standardSet.name);

      if (props.supportedStandardSetIds.includes(standardSet.ids)) {
        // Only supported standard set must be checked
        expect(checkbox.element.checked).toBeTruthy();
      } else {
        expect(checkbox.element.checked).toBeFalsy();
      }
    });
  });
});
