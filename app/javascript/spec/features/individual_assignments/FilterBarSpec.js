import { mount } from '@vue/test-utils';

import FilterBar from 'features/individual_assignments/FilterBar';
import Datastore from 'features/individual_assignments/models/datastore';

describe(
  'FilterBar',
  () => {
    let wrapper;

    const exportUrl = '/path/to/export.csv';

    const lessonOptions = [
      { name: 'Lesson 1', value: 1, selected: false },
      { name: 'Lesson 2', value: 2, selected: true },
    ];
    const weekOptions = [
      { name: 'Week 1', value: '5/21', selected: false },
      { name: 'Week 2', value: '5/28', selected: true },
    ];
    const props = { exportUrl, lessonOptions, weekOptions };
    const store = new Datastore({});

    function getWrapper() {
      return mount(
        FilterBar,
        { global: { provide: { store }}, props }
      );
    }

    function getLessonMenu() {
      return wrapper.get('.test-lesson-filter-menu');
    }

    function getWeekMenu() {
      return wrapper.get('.test-week-filter-menu');
    }

    beforeEach(() => wrapper = getWrapper());

    it(
      'renders a select for lessons',
      () => {
        expect(getLessonMenu().exists()).toBeTruthy();
      }
    );

    it(
      'renders options for each lesson in the props',
      () => {
        const options = getLessonMenu().findAll('option');
        expect(
          options.map(
            (option) => [option.text(), option.attributes('value')]
          )
        ).toEqual([['Lesson 1', '1'], ['Lesson 2', '2']]);
      }
    );

    it(
      'sets the selected state of an option to true if that lesson is ' +
      'marked as selected in the props',
      () => {
        const options = getLessonMenu().findAll('option');
        expect(options[1].element.selected).toBeTruthy();
      }
    );

    it(
      'sets the selected state of an option to false if that lesson is ' +
      'not marked as selected in the props',
      () => {
        const options = getLessonMenu().findAll('option');
        expect(options[0].element.selected).toBeFalsy();
      }
    );

    it(
      'renders a select for weeks',
      () => {
        expect(getWeekMenu().exists()).toBeTruthy();
      }
    );

    it(
      'renders options for each week in the props',
      () => {
        const options = getWeekMenu().findAll('option');
        expect(
          options.map(
            (option) => [option.text(), option.attributes('value')]
          )
        ).toEqual([['Week 1', '5/21'], ['Week 2', '5/28']]);
      }
    );

    it(
      'sets the selected state of an option to true if that week is ' +
      'marked as selected in the props',
      () => {
        const options = getWeekMenu().findAll('option');
        expect(options[1].element.selected).toBeTruthy();
      }
    );

    it(
      'sets the selected state of an option to false if that week is ' +
      'not marked as selected in the props',
      () => {
        const options = getWeekMenu().findAll('option');
        expect(options[0].element.selected).toBeFalsy();
      }
    );

    it(
      'emits a selectLesson event when a lesson is selected',
      async () => {
        const menu = getLessonMenu();
        menu.element.value = '1';
        await menu.trigger('change');

        expect(wrapper.emitted().selectLesson).toHaveLength(1);
      }
    );

    it(
      'emits a selectWeek event when a week is selected',
      async () => {
        const menu = getWeekMenu();
        menu.element.value = '5/21';
        await menu.trigger('change');

        expect(wrapper.emitted().selectWeek).toHaveLength(1);
      }
    );
  }
);
