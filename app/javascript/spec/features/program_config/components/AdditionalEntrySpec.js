import { mount } from '@vue/test-utils';
import AdditionalEntry from 'features/program_config/components/AdditionalEntry';

const props = {
  modelValue: {
    description: 'Interactive virtual textbook',
    label: 'some label',
    programId: '123',
    targetUser: 'Student',
    url: 'abc.com/entry-url',
  },
  index: 0,
};

let wrapper;

function getWrapper(propsData) {
  return mount(AdditionalEntry, { propsData });
}

describe('Additional Entry for Content Menu in Program Config', () => {
  beforeEach(() => wrapper = getWrapper(props));

  it('contains input for Additional entry url', () => {
    expect(wrapper.find('.test-additional-entry-url').element.value).toBe('abc.com/entry-url');
  });

  it('contains input for Additional entry label', () => {
    expect(wrapper.find('.test-additional-entry-label').element.value).toBe('some label');
  });

  it('contains dropdown for Additional entry target user', () => {
    expect(wrapper.find('.test-additional-entry-target-user').element.value).toBe('Student');
  });

  it('contains an input for Additional entry program id', () => {
    expect(wrapper.find('.test-additional-entry-program-id').element.value).toBe('123');
  });

  it('contains input for Additional entry description', () => {
    expect(wrapper.find('.test-additional-entry-description').element.value).toBe('Interactive virtual textbook');
  });

  it('triggers event "removeAdditionalEntry" when "Remove Additional Entry" ' +
    'button is clicked', async () => {
    const removeButton = wrapper.find('.test-remove-additional-entry');
    await removeButton.trigger('click');
    expect(wrapper.emitted('removeAdditionalEntry')).toHaveLength(1);
  });
});
