import { mount } from '@vue/test-utils';
import AiSuggestionsFilterApp from '../../../../../src/features/ai/instructor_grading/suggestion_rating_reports/AiSuggestionsFilterApp.vue';

describe('AiSuggestionsFilterApp', () => {
  let wrapper;

  const props = {
    programId: 1234,
    lessons: [
      { id: 1, label: 'Lesson 1' },
      { id: 2, label: 'Lesson 2' }
    ],
    strandsByLesson: [
      { lesson_id: 1, title: 'Strand 1', strand_id: 1 },
      { lesson_id: 2, title: 'Strand 2', strand_id: 2 }
    ],
    types: {
      type1: 'Type 1',
      type2: 'Type 2'
    },
    instructors: [
      { id: 1, full_name: 'Instructor 1' },
      { id: 2, full_name: 'Instructor 2' }
    ],
  };

  beforeEach(() => {
    wrapper = mount(AiSuggestionsFilterApp, {
      props
    });
  });

  it('renders the lessons correctly', () => {
    const lessonLabels = wrapper.findAll('label[for^="checkbox-lesson-id"]');
    expect(lessonLabels.length).toBe(2);
    expect(lessonLabels[0].text()).toBe('Lesson 1');
    expect(lessonLabels[1].text()).toBe('Lesson 2');
  });

  it('renders the strands correctly based on selected lessons', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    
    await lessonCheckboxes[0].setChecked(true);

    const strandLabels = wrapper.findAll('label[for^="checkbox-strand-id"]');
    expect(strandLabels.length).toBe(1);
    expect(strandLabels[0].text()).toBe('Strand 1');
  });

  it('clears selected strands when no lessons are selected', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await lessonCheckboxes[0].setChecked(true);
    await lessonCheckboxes[0].setChecked(false);

    expect(wrapper.vm.selectedStrands).toEqual([]);
  });

  it('renders the types correctly', () => {
    const typeLabels = wrapper.findAll('label[for^="checkbox-type-id"]');
    expect(typeLabels.length).toBe(2);
    expect(typeLabels[0].text()).toBe('Type 1');
    expect(typeLabels[1].text()).toBe('Type 2');
  });

  it('renders the instructors correctly', () => {
    const instructorLabels = wrapper.findAll('label[for^="checkbox-instructor-id"]');
    expect(instructorLabels.length).toBe(2);
    expect(instructorLabels[0].text()).toBe('Instructor 1');
    expect(instructorLabels[1].text()).toBe('Instructor 2');
  });

  it('filters strands based on selected lessons', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await lessonCheckboxes[0].setChecked(true);
    
    const strandLabels = wrapper.findAll('label[for^="checkbox-strand-"]');
    expect(strandLabels.length).toBe(1);
    expect(strandLabels[0].text()).toBe('Strand 1');
  });

  it('removes selected filter when the "X" button is clicked', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');

    await lessonCheckboxes[0].setChecked(true);
    await wrapper.vm.$nextTick();

    const selectedLessonChip = wrapper.find('.c-lesson-chip');
    expect(selectedLessonChip.exists()).toBe(true);
    expect(selectedLessonChip.text()).toContain('Lesson 1');

    await selectedLessonChip.find('a').trigger('click');
    await wrapper.vm.$nextTick();

    const removedLessonChip = wrapper.find('.c-lesson-chip');
    expect(removedLessonChip.exists()).toBe(false);
  });

  it('clears all filters when "Clear All" is clicked', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    const filtersWrapper = wrapper.find('div.u-dis-flex.flex-wrap');

    await lessonCheckboxes[0].setChecked(true);
    await lessonCheckboxes[1].setChecked(true);
    await wrapper.vm.$nextTick();

    expect(wrapper.findAll('.c-lesson-chip').length).toBe(2);

    await filtersWrapper.find('.m4-button--primary').trigger('click');
    await wrapper.vm.$nextTick();

    expect(wrapper.find('.c-lesson-chip').exists()).toBe(false);
    expect(wrapper.find('.c-strand-chip').exists()).toBe(false);
    expect(wrapper.find('.c-type-chip').exists()).toBe(false);
  });

  it('redirects to the correct URL when "Apply" is clicked', async () => {
    global.window = Object.create(window);
    const url = 'https://test.com';
    Object.defineProperty(window, 'location', {
      value: {
        href: url,
        origin: 'https://test.com'
      },
      writable: true
    });

    await wrapper.findAll('input[type="checkbox"]')[0].setChecked(true);
    await wrapper.findAll('input[type="checkbox"]')[2].setChecked(true);
    await wrapper.find('StandardButton').trigger('click');

    const expectedUrl = `https://test.com/ai/programs/1234/instructor_grading/suggestion_rating_reports?selected_lesson_ids=1&selected_strands=1&selected_types=&selected_instructor_ids=&filtered=true`;
    
    expect(window.location.href).toBe(expectedUrl);
  });

  it('applies filters with selected instructors', async () => {
    global.window = Object.create(window);
    const url = 'https://test.com';
    Object.defineProperty(window, 'location', {
      value: {
        href: url,
        origin: 'https://test.com'
      },
      writable: true
    });

    await wrapper.findAll('input[type="checkbox"]')[4].setChecked(true);
    await wrapper.find('StandardButton').trigger('click');

    const expectedUrl = `https://test.com/ai/programs/1234/instructor_grading/suggestion_rating_reports?selected_lesson_ids=&selected_strands=&selected_types=&selected_instructor_ids=1&filtered=true`;
    expect(window.location.href).toBe(expectedUrl);
  });
});
