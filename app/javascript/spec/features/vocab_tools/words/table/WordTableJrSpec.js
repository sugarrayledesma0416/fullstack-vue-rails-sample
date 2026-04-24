import { shallowMount } from '@vue/test-utils';
import WordTableJr from 'features/vocab_tools/words/table/WordTableJr';
const unitData = {
  id: 1,
  inCourse: true,
  lessons: [
    {
      id: 11,
      name: 'Lección 1',
      selectedWords: [
        { headword: 'test' },
        { headword: 'qwerty' },
      ],
    },
    {
      id: 12,
      name: 'Lección 2',
      selectedWords: [
        { headword: 'test' },
        { headword: 'qwerty' },
      ],
    },
  ],
  name: 'Unité 1',
};
const commmonProps = {
  isTranslationHidden: false,
  ssjrStudent: true,
  targetLanguage: 'French',
  targetLanguageCode: 'fr',
  units: [unitData],
  viewAllLessons: true,
  vocabHasDefinition: true,
};
const getSomeInCourseUnits = () => {
  const unit1Data = { ...unitData, ...{ inCourse: true }};
  const unit2Data = { ...unitData, ...{ inCourse: false }};
  return [unit1Data, unit2Data];
};

let wrapper;
const getWrapper = (propsData) => {
  return shallowMount(WordTableJr, {
    propsData,
    stubs: ['AddWordIcon', 'EditWord', 'HeaderRow', 'NewWord'],
  });
};

const triggerCompEvent = async (compName, eventName, eventData) => {
  const comp = wrapper.findComponent({ name: compName });
  await comp.vm.$emit(eventName, eventData);
};

describe('WordTableJr', () => {
  describe('when unit has 2 lessons and 4 words', () => {
    beforeEach(() => {
      wrapper = getWrapper(commmonProps);
    });

    describe('when WordTableJr is mounted', () => {
      it('displays 2 tables one for each lesson', () => {
        expect(wrapper.findAll('.test-table-vocab-tools-lesson-words')).toHaveLength(2);
      });

      it('displays 1 "CommonHeader" component', () => {
        expect(wrapper.findAllComponents({ name: 'CommonHeader' })).toHaveLength(1);
      });

      it('displays 2 "WordTableCaption" components one for each lesson', () => {
        expect(wrapper.findAllComponents({ name: 'WordTableCaption' })).toHaveLength(2);
      });

      it('displays 2 "LessonHeaderRow" components one for each lesson', () => {
        expect(wrapper.findAllComponents({ name: 'LessonHeaderRow' })).toHaveLength(2);
      });

      it('displays 2 "AddWordIcon" components one for each lesson', () => {
        expect(wrapper.findAllComponents({ name: 'AddWordIcon' })).toHaveLength(2);
      });

      it('does not display "NewWord" component', () => {
        expect(wrapper.findAllComponents({ name: 'NewWord' })).toHaveLength(0);
      });

      it('displays 4 "EditWord" components one for each word', () => {
        expect(wrapper.findAllComponents({ name: 'EditWord' })).toHaveLength(4);
      });

      it('triggers event "updateWord" when receives it ' +
        'from child component "EditWord"', async () => {
        await triggerCompEvent('EditWord', 'updateWord');
        expect(wrapper.emitted('updateWord')).toHaveLength(1);
      });

      it('triggers event "removeWord" when receives it ' +
        'from child component "EditWord"', async () => {
        await triggerCompEvent('EditWord', 'removeWord');
        expect(wrapper.emitted('removeWord')).toHaveLength(1);
      });
    });

    describe('when receives "showAddWord" event from child component "AddWordIcon" ' +
      'for lesson "Lección 1"', () => {
      beforeEach(async () => {
        await triggerCompEvent('AddWordIcon', 'showAddWord', { lesson: { id: 11 }});
      });

      it('hides "AddWordIcon" component', () => {
        // Earlier count was 2, which reduces by 1
        expect(wrapper.findAllComponents({ name: 'AddWordIcon' })).toHaveLength(1);
      });

      it('shows "NewWord" component ', () => {
        expect(wrapper.findAllComponents({ name: 'NewWord' })).toHaveLength(1);
      });

      it('triggers event "addWord" when receives it from child component "NewWord"', async () => {
        await triggerCompEvent('NewWord', 'addWord');
        expect(wrapper.emitted('addWord')).toHaveLength(1);
      });

      describe('when receives "hideAddWord" event from child component "NewWord"', () => {
        beforeEach(async () => {
          await triggerCompEvent('NewWord', 'hideAddWord');
        });

        it('hides "NewWord" component', async () => {
          expect(wrapper.findAllComponents({ name: 'NewWord' })).toHaveLength(0);
        });

        it('shows "AddWordIcon" component', async () => {
          // Earlier count was 1, which increases by 1
          expect(wrapper.findAllComponents({ name: 'AddWordIcon' })).toHaveLength(2);
        });
      });
    });
  });

  describe('when some lessons are not in-course', () => {
    describe('when viewAllLessons is true', () => {
      beforeEach(() => {
        const units = getSomeInCourseUnits();
        const props = { ...commmonProps, ...{ units }, ...{ viewAllLessons: true }};
        wrapper = getWrapper(props);
      });

      describe('when WordTableJr is mounted', () => {
        it('displays 4 tables one for each lesson', () => {
          expect(wrapper.findAll('.test-table-vocab-tools-lesson-words')).toHaveLength(4);
        });
      });
    });
  });

  describe('when viewAllLessons is false', () => {
    beforeEach(() => {
      const units = getSomeInCourseUnits();
      const props = { ...commmonProps, ...{ units }, ...{ viewAllLessons: false }};
      wrapper = getWrapper(props);
    });

    describe('when WordTableJr is mounted', () => {
      it('displays 2 tables one for each in-course lessons', () => {
        expect(wrapper.findAll('.test-table-vocab-tools-lesson-words')).toHaveLength(2);
      });
    });
  });
});
