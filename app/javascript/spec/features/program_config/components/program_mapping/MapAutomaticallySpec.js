import { mount } from '@vue/test-utils';
import MapAutomatically from 'features/program_config/components/program_mapping/MapAutomatically';

const programToProgramMapping = {
  mapAutomatically: jest.fn(),
};

const getWrapper = () => {
  return mount(MapAutomatically, {
    global: {
      provide: { programToProgramMapping },
    },
    props: {
      srcProgId: 2,
    },
  });
};

describe('MapAutomatically', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = getWrapper();
  });

  it('displays "Map automatically will override the current strand mappings"', () => {
    expect(
      wrapper.get('.test-auto-map-modal').text()
    ).toContain('Map automatically will override the current strand mappings');
  });

  it('emits close event on cancel button click', async () => {
    await wrapper.get('.test-modal-cancel').trigger('click');
    expect(wrapper.emitted().close).toBeTruthy();
  });

  it('maps source to destination on "Map Automatically" button click', async () => {
    await wrapper.get('.test-map-automatically').trigger('click');
    expect(programToProgramMapping.mapAutomatically).toHaveBeenCalledWith(2);
  });
});
