import { shallowMount } from '@vue/test-utils';
import ActivityNotes from 'features/instructor_notes/ActivityNotes';
import ActivityNote from 'features/instructor_notes/ActivityNote';

describe('ActivityNotes', () => {
  let wrapper;

  function getWrapper(options) {
    return shallowMount(ActivityNotes, {
      props: options,
    });
  }

  const notes = [
    { id: 1, title: 'Test Note 1' },
    { id: 2, title: 'Test Note 2' },
  ];
  const appId = 'question_01_whole_question';

  it('has appId class on the main div', () => {
    wrapper = getWrapper({ notes, appId });
    expect(wrapper.attributes('class')).toContain(`c-instructor-note-app-${appId}`);
  });

  it('mounts child Activity note components for each note', () => {
    wrapper = getWrapper({ notes, appId });
    expect(wrapper.findAllComponents(ActivityNote)).toHaveLength(notes.length);
  });

  it('removes a activity note whenever "deleted" is emitted on the child component', () => {
    wrapper = getWrapper({ notes, appId });
    wrapper.findComponent({ ref: 'ref-note-1' }).vm.$emit('deleted', 1);
    expect(wrapper.vm.currentNotes).toHaveLength(notes.length - 1);
  });
});
