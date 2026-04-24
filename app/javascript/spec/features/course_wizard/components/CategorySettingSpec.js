import { mount } from '@vue/test-utils';
import CategorySetting from 'features/course_wizard/components/CategorySetting';

describe('The CategorySetting component', () => {
  it('Displays the title as an h4 tag.', () => {
    const wrapper = mount(CategorySetting, { propsData: { title: 'Foo' }});
    const heading = wrapper.find('h4');
    expect(heading.exists()).toBe(true);
  });

  it('Displays the supplied title.', () => {
    const wrapper = mount(CategorySetting, { propsData: { title: 'Foo' }});
    expect(wrapper.find('.test-title').text()).toBe('Foo:');
  });
});

