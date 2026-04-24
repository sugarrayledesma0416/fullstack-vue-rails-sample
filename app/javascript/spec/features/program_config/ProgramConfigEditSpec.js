import { shallowMount } from '@vue/test-utils';
import ProgramConfigEditApp from 'features/program_config/ProgramConfigEditApp';

const propsData = {
  aiSettings: {},
  contentMenuSettings: { additionalEntries: [] },
  currentSettings: [],
  otherFeaturesSettings: {},
  programId: 79,
  programMappingData: {},
  volConfigs: { is_vista_online_learning: true },
  standardsSettings: {
    supportedStandardSetIds: [1, 3]
  },
  standardsSettingsData: {
    standard_sets_array: [
      { id: 1, name: 'standard set 1' },
      { id: 2, name: 'standard set 2' },
      { id: 3, name: 'standard set 3' }
    ]
  }
};

const getWrapper = () => {
  return shallowMount(ProgramConfigEditApp, {
    props: propsData,
  });
};

let wrapper;

describe('Program Configurations Edit Page for VOL Program', () => {
  beforeEach(() => wrapper = getWrapper());

  describe('when ProgramConfigEditApp is mounted', () => {
    it('displays "ReferenceToolSettings" component', () => {
      expect(wrapper.findComponent({ name: 'ReferenceToolSettings' }).exists()).toBeTruthy();
    });

    it('displays "VolConfigs" component', () => {
      expect(wrapper.findComponent({ name: 'VolConfigs' }).exists()).toBeTruthy();
    });

    it('displays "ContentMenuSettings" component', () => {
      expect(wrapper.findComponent({ name: 'ContentMenuSettings' }).exists()).toBeTruthy();
    });

    it('displays the "AISettings" component', () => {
      expect(wrapper.findComponent({ name: 'AISettings' }).exists()).toBeTruthy();
    });

    it('displays "OtherFeaturesSettings" component', () => {
      expect(wrapper.findComponent({ name: 'OtherFeaturesSettings' }).exists()).toBeTruthy();
    });

    describe('when standard sets are present', () => {
      it('displays "StandardSettings" component', () => {
        expect(wrapper.findComponent({ name: 'StandardSettings' }).exists()).toBeTruthy();
      });
    });

    describe('when no standard set is present', () => {
      beforeEach(() => {
        propsData.standardsSettingsData.standard_sets_array = [];
        wrapper = getWrapper();
      });

      it('does not display "StandardSettings" component', () => {
        expect(wrapper.findComponent({ name: 'StandardSettings' }).exists()).toBeFalsy();
      });
    });

    it('displays "ProgramMappingComponent" component', () => {
      expect(wrapper.findComponent({ name: 'ProgramMappingComponent' }).exists()).toBeTruthy();
    });
  });
});

describe('Program Configurations Edit Page for Non-VOL Program', () => {
  beforeEach(() => {
    propsData.volConfigs.is_vista_online_learning = false;
    wrapper = getWrapper();
  });

  describe('when ProgramConfigEditApp is mounted', () => {
    it('displays "ReferenceToolSettings" component', () => {
      expect(wrapper.findComponent({ name: 'ReferenceToolSettings' }).exists()).toBeTruthy();
    });

    it('does not displays "VolConfigs" component', () => {
      expect(wrapper.findComponent({ name: 'VolConfigs' }).exists()).toBeFalsy();
    });

    it('displays "ContentMenuSettings" component', () => {
      expect(wrapper.findComponent({ name: 'ContentMenuSettings' }).exists()).toBeTruthy();
    });

    it('displays the "AISettings" component', () => {
      expect(wrapper.findComponent({ name: 'AISettings' }).exists()).toBeTruthy();
    });

    it('displays "OtherFeaturesSettings" component', () => {
      expect(wrapper.findComponent({ name: 'OtherFeaturesSettings' }).exists()).toBeTruthy();
    });

    describe('when standard sets are present', () => {
      beforeEach(() => {
        propsData.standardsSettingsData.standard_sets_array = [
          { id: 1, name: 'standard set 1' },
          { id: 2, name: 'standard set 2' },
          { id: 3, name: 'standard set 3' }
        ];
        wrapper = getWrapper();
      });

      it('displays "StandardSettings" component', () => {
        expect(wrapper.findComponent({ name: 'StandardSettings' }).exists()).toBeTruthy();
      });
    });

    describe('when no standard set is present', () => {
      beforeEach(() => {
        propsData.standardsSettingsData.standard_sets_array = [];
        wrapper = getWrapper();
      });

      it('does not display "StandardSettings" component', () => {
        expect(wrapper.findComponent({ name: 'StandardSettings' }).exists()).toBeFalsy();
      });
    });

    it('displays "ProgramMappingComponent" component', () => {
      expect(wrapper.findComponent({ name: 'ProgramMappingComponent' }).exists()).toBeTruthy();
    });
  });
});
