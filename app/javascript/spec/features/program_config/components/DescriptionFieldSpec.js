import { shallowMount } from '@vue/test-utils';
import DescriptionField from 'features/program_config/components/DescriptionField';

CKEDITOR = {
  env: {},
  replace() {},
};

const getWrapper = () => {
  return shallowMount(DescriptionField, {
    props: {
      id: 'datastore_course_setup_descriptions_learning_tracks_header',
      name: 'datastore[course_setup_descriptions][learning_tracks][header]',
      value: '<p>Learning tracks header</p>',
      type: 'header',
    },
  });
};

let wrapper;

describe('Description Field for Program Configs', () => {
  beforeEach(() => wrapper = getWrapper());

  it('contains text area', () => {
    expect(wrapper.get('.test-description-header').exists()).toBeTruthy();
  });

  it('contains hidden input tag with value provided', () => {
    expect(
      wrapper.get('.test-desciption-input-header').element.value
    ).toEqual('<p>Learning tracks header</p>');
  });
});
