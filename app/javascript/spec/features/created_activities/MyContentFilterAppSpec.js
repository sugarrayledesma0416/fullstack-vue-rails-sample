import { mount } from '@vue/test-utils';
import MyContentFilterApp from 'features/created_activities/MyContentFilterApp.vue';

let wrapper;

const props = {
  programId: 1234,
  lessons: [
    { id: 1, label: 'Lesson 1' },
    { id: 2, label: 'Lesson 2' }
  ],
  strandsByLesson: [
    { lesson_id: 1, title: 'Strand 1' },
    { lesson_id: 2, title: 'Strand 2' }
  ],
  types: {
    type1: 'Type 1',
    type2: 'Type 2'
  },
  sharedActivityCreators: [
    { full_name: 'Creator 1', id: 1 },
    { full_name: 'Creator 2', id: 2 }
  ]
};

describe('MyContentFilterApp', () => {
  beforeEach(() => {
    wrapper = mount(MyContentFilterApp, {
      props: {
        ...props,
        sharedActivityCreators: null
      }
    });
  });

  it('redirects to the mycontent URL when filter is changed and sharedActivityCreators is null', async () => {
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
    await wrapper.vm.$nextTick();

    const expectedUrl = `https://test.com/instructor/mycontent/1234?selected_lesson_ids=1&selected_strands=&selected_types=&selected_shared_activity_creator_ids=&filtered=true`;

    expect(window.location.href).toBe(expectedUrl);
  });
});

describe('MyContentFilterApp', () => {
  beforeEach(() => {
    wrapper = mount(MyContentFilterApp, {
      props
    });
  });

  it('applies filters with selected shared activity creators', async () => {
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
    await wrapper.vm.$nextTick();

    const expectedUrl = `https://test.com/instructor/shared_content/1234?selected_lesson_ids=&selected_strands=&selected_types=&selected_shared_activity_creator_ids=1&filtered=true`;
    expect(window.location.href).toBe(expectedUrl);
  });

  it('renders the lessons correctly', () => {
    const lessonLabels = wrapper.findAll('label[for^="checkbox-lesson-id"]');
    expect(lessonLabels.length).toBe(2);
    expect(lessonLabels[0].text()).toBe('Lesson 1');
    expect(lessonLabels[1].text()).toBe('Lesson 2');
  });

  it('renders the types correctly', () => {
    const typeLabels = wrapper.findAll('label[for^="checkbox-type-"]');
    expect(typeLabels.length).toBe(2);
    expect(typeLabels[0].text()).toBe('Type 1');
    expect(typeLabels[1].text()).toBe('Type 2');
  });

  it('filters strands based on selected lessons', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await lessonCheckboxes[0].setChecked(true);
    const strandLabels = wrapper.findAll('label[for^="checkbox-strand-"]');
    expect(strandLabels.length).toBe(1);
    expect(strandLabels[0].text()).toBe('Strand 1');
  });

  it('clears selected strands when no lessons are selected', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await lessonCheckboxes[0].setChecked(true);
    await lessonCheckboxes[0].setChecked(false);
    expect(wrapper.vm.selectedStrands).toEqual([]);
  });

  it('displays selected filters as chips with specific classes', async () => {
    const lessonCheckboxes = wrapper.findAll('input[type="checkbox"]');

    await lessonCheckboxes[0].setChecked(true);
    await wrapper.vm.$nextTick();

    const selectedLessonChip = wrapper.find('.c-lesson-chip');
    expect(selectedLessonChip.exists()).toBe(true);
    expect(selectedLessonChip.text()).toContain('Lesson 1');

    const strandCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await strandCheckboxes[2].setChecked(true);
    await wrapper.vm.$nextTick();

    const selectedStrandChip = wrapper.find('.c-strand-chip');
    expect(selectedStrandChip.exists()).toBe(true);
    expect(selectedStrandChip.text()).toContain('Strand 1');
  })

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

    const selectedLessonChip1 = wrapper.find('.c-lesson-chip');
    const selectedLessonChip2 = wrapper.find('.c-lesson-chip');
    expect(selectedLessonChip1.exists()).toBe(true);
    expect(selectedLessonChip2.exists()).toBe(true);

    await filtersWrapper.find('.m4-button--primary').trigger('click');
    await wrapper.vm.$nextTick();

    expect(wrapper.find('.c-lesson-chip').exists()).toBe(false);
    expect(wrapper.find('.c-lesson-chip').exists()).toBe(false);
  });

  it('renders the shared activity creators correctly', () => {
    const creatorLabels = wrapper.findAll('label[for^="checkbox-shared-activity-creators-"]');
    expect(creatorLabels.length).toBe(2);
    expect(creatorLabels[0].text()).toBe('Creator 1');
    expect(creatorLabels[1].text()).toBe('Creator 2');
  });

  it('selects shared activity creators correctly', async () => {
    const creatorCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await creatorCheckboxes[4].setChecked(true);  // Select "Creator 1"
    expect(wrapper.vm.selectedSharedActivityCreators).toEqual([1]);
  });

  it('removes shared activity creator filter when "X" button is clicked', async () => {
    const creatorCheckboxes = wrapper.findAll('input[type="checkbox"]');
    await creatorCheckboxes[4].setChecked(true);  // Select "Creator 1"
    await wrapper.vm.$nextTick();

    const selectedCreatorChip = wrapper.find('.c-type-chip');
    expect(selectedCreatorChip.exists()).toBe(true);
    expect(selectedCreatorChip.text()).toContain('Creator 1');

    await selectedCreatorChip.find('a').trigger('click');  // Remove "Creator 1"
    await wrapper.vm.$nextTick();

    const removedCreatorChip = wrapper.find('.c-type-chip');
    expect(removedCreatorChip.exists()).toBe(false);
  });
});
