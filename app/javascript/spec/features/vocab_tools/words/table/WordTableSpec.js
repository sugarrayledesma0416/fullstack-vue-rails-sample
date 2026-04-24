import { shallowMount } from '@vue/test-utils';
import WordTable from 'features/vocab_tools/words/table/WordTable';

const commmonProps = {
  isTranslationHidden: false,
  ssjrStudent: false,
  targetLanguage: 'French',
  targetLanguageCode: 'fr',
  units: [],
  viewAllLessons: true,
  vocabHasDefinition: true,
};

let wrapper;
const getWrapper = (propsData) => {
  return shallowMount(WordTable, {
    propsData,
    stubs: ['WordTableJr', 'WordTableSr'],
  });
};

const triggerCompEvent = async (wrapper, compName, eventName) => {
  const comp = wrapper.findComponent({ name: compName });
  await comp.vm.$emit(eventName);
};

describe('WordTable', () => {
  describe('when "ssjrStudent" value is false', () => {
    beforeEach(() => {
      const propsSr = { ...commmonProps, ...{ ssjrStudent: false }};
      wrapper = getWrapper(propsSr);
    });

    describe('when WordTable is mounted', () => {
      it('displays 1 "WordTableSr" component', () => {
        expect(wrapper.findAllComponents({ name: 'WordTableSr' })).toHaveLength(1);
      });

      it('does not display "WordTableJr" component', () => {
        expect(wrapper.findAllComponents({ name: 'WordTableJr' })).toHaveLength(0);
      });

      it('triggers event "addWord" when receives it ' +
        'from child component "WordTableSr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableSr', 'addWord');
        expect(wrapper.emitted('addWord')).toHaveLength(1);
      });

      it('triggers event "removeWord" when receives it ' +
        'from child component "WordTableSr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableSr', 'removeWord');
        expect(wrapper.emitted('removeWord')).toHaveLength(1);
      });

      it('triggers event "updateWord" when receives it ' +
        'from child component "WordTableSr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableSr', 'updateWord');
        expect(wrapper.emitted('updateWord')).toHaveLength(1);
      });
    });
  });

  describe('when "ssjrStudent" value is true', () => {
    beforeEach(() => {
      const propsJr = { ...commmonProps, ...{ ssjrStudent: true }};
      wrapper = getWrapper(propsJr);
    });

    describe('when WordTable is mounted', () => {
      it('displays 1 "WordTableJr" component', () => {
        expect(wrapper.findAllComponents({ name: 'WordTableJr' })).toHaveLength(1);
      });

      it('does not display "WordTableSr" component', () => {
        expect(wrapper.findAllComponents({ name: 'WordTableSr' })).toHaveLength(0);
      });

      it('triggers event "addWord" when receives it ' +
        'from child component "WordTableJr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableJr', 'addWord');
        expect(wrapper.emitted('addWord')).toHaveLength(1);
      });

      it('triggers event "removeWord" when receives it ' +
        'from child component "WordTableJr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableJr', 'removeWord');
        expect(wrapper.emitted('removeWord')).toHaveLength(1);
      });

      it('triggers event "updateWord" when receives it ' +
        'from child component "WordTableJr"', async () => {
        await triggerCompEvent(wrapper, 'WordTableJr', 'updateWord');
        expect(wrapper.emitted('updateWord')).toHaveLength(1);
      });
    });
  });
});
