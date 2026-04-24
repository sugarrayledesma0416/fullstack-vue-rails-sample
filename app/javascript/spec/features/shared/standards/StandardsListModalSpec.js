import { shallowMount } from '@vue/test-utils';
import StandardsListModal from 'features/shared/standards/StandardsListModal';

const props = {
  standardsList: [
    [
      {
        id: 20155,
        vendor_guid: "0D967DC6-D45B-11E6-B36B-24D8CCC8CA83",
        vendor_standard_set_guid: "8757F654-CB95-11E6-9608-EC26CDC8CA83",
        name: "English Language Arts",
        description: "Demonstrate command of the conventions of Standard English grammar and usage when writing or speaking.",
        label: "Standard",
        number: "6.L.1",
        additional_info: '{\"additional_info\":{\"ancestors\":\"FBB63C8A-D456-11E6-8800-7840BF03DF2F,716BCF44-D457-11E6-8BDD-79D2CCC8CA83\",\"children\":\"1900F876-D45B-11E6-A27E-0046BF03DF2F,1FEAB5E6-D45B-11E6-B8CF-7545BF03DF2F,244A3576-D45B-11E6-9BFE-1E46BF03DF2F,2AD9C9F6-D45B-11E6-9E7F-E3D7CCC8CA83,2F79AD82-D45B-11E6-9E7F-E3D7CCC8CA83\",\"grade_levels\":\"6\",\"parent_guid\":\"716BCF44-D457-11E6-8BDD-79D2CCC8CA83\"}}',
        created_at: '2024-01-17T12:44:39-05:00',
        updated_at: '2024-01-17T12:44:39-05:00',
        searchable: true,
        standard_set: {
          id: 46,
          vendor_guid: '8757F654-CB95-11E6-9608-EC26CDC8CA83',
          issuer: 'Arizona DOE',
          name: 'English Language Arts',
          adopt_year: 2016,
          state: 'US,AZ',
          acronym: '',
          description: 'High Academic Standards for Students',
          created_at: '2024-01-17T12:44:23-05:00',
          updated_at: '2024-04-29T13:45:18-04:00',
          display_name: 'AZ ELA',
        },
      },
    ],
  ],
  instructorStandardsAssigningPath: 'dummy/path',
  unitId: '2965',
};

function getWrapper() {
  return shallowMount(
    StandardsListModal,
    {
      props: props,
    });
}

describe('StandardsListModal',
  () => {
    let wrapper;

    beforeEach(
      () => {
        wrapper = getWrapper();
      }
    );

    it('displays StandardsListModal component', () => {
      expect(wrapper.find('.test-standard-list-modal').exists()).toBeTruthy();
    });
  });
