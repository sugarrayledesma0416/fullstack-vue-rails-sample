import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryStrictness from
  'features/category_wizard/components/add_category/CategoryStrictness';

const metaAccent = document.createElement('meta');
metaAccent.setAttribute('name', 'VHL.program_accent_bar_enabled');
metaAccent.setAttribute('content', 'true');
document.querySelector('head').appendChild(metaAccent);

/**
 * This method gets wrapper for CategoryStrictness component
 * @param {string} languageCode - program language code
 * @return {Wrapper}
 */
const getWrapper = (languageCode) => {
  const category = reactive(new Category({ languageCode }));
  const config = { languageCode: languageCode };

  return mount(CategoryStrictness, {
    global: {
      provide: {
        category,
        config,
      },
    },
  });
};

describe('CategoryStrictness', () => {
  let wrapper;

  describe('mounted with language code en', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper('en');
    });

    it('does not display accent marks count option', () => {
      expect(
        wrapper.find('.test-grading-accents-input').exists()
      ).toBe(false);
    });

    it('displays "Capitalization will be taken into account." as must' +
       ' match capitalization label', () => {
      expect(wrapper.get('.test-grading-capitalization-label').text()).toBe(
        'Capitalization will be taken into account.'
      );
    });

    it('displays must match capitalization as not checked', () => {
      expect(
        wrapper.get('.test-grading-capitalization-input').element.checked
      ).toBeFalsy();
    });

    it('displays "Punctuation will be taken into account." as must' +
       ' match punctuation label', () => {
      expect(wrapper.get('.test-grading-punctuation-label').text()).toBe(
        'Punctuation will be taken into account.'
      );
    });

    it('displays must match punctuation as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('mounted with language code es', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'true');
      wrapper = getWrapper('es');
    });

    it('displays "Accent marks will be taken into account." as must' +
       ' match accents label', () => {
      expect(
        wrapper.find('.test-grading-accents-label').text()
      ).toBe('Accent marks will be taken into account.');
    });

    it('displays must match accents as checked', () => {
      expect(
        wrapper.find('.test-grading-accents-input').element.checked
      ).toBe(true);
    });

    it('displays "Capitalization will be taken into account." as must' +
       ' match capitalization label', () => {
      expect(wrapper.get('.test-grading-capitalization-label').text()).toBe(
        'Capitalization will be taken into account.'
      );
    });

    it('displays must match capitalization as not checked', () => {
      expect(
        wrapper.find('.test-grading-capitalization-input').element.checked
      ).toBeFalsy();
    });

    it('displays "Punctuation will be taken into account." as must' +
       ' match punctuation label', () => {
      expect(wrapper.get('.test-grading-punctuation-label').text()).toBe(
        'Punctuation will be taken into account.'
      );
    });

    it('displays must match punctuation as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('mounted with language code zh', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper('zh');
    });

    it('does not display accent marks count option', () => {
      expect(
        wrapper.find('.test-grading-accents-input').exists()
      ).toBeFalsy();
    });

    it('does not display capitalization counts option', () => {
      expect(
        wrapper.find('.test-grading-capitalization-input').exists()
      ).toBeFalsy();
    });

    it('displays "Punctuation will be taken into account." as must' +
      ' match punctuation label', () => {
      expect(
        wrapper.get('.test-grading-punctuation-label').text()
      ).toBe('Punctuation will be taken into account.');
    });

    it('displays must match punctuation as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('mounted with language code ru', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper('ru');
    });

    it('does not display accent marks count option', () => {
      expect(wrapper.find('.test-grading-accents-input').exists()).toBeFalsy();
    });

    it('displays "Capitalization will be taken into account." as must' +
       ' match capitalization label', () => {
      expect(wrapper.get('.test-grading-capitalization-label').text()).toBe(
        'Capitalization will be taken into account.'
      );
    });

    it('displays "Punctuation will be taken into account." as must' +
      ' match punctuation label', () => {
      expect(wrapper.get('.test-grading-punctuation-label').text()).toBe(
        'Punctuation will be taken into account.'
      );
    });

    it('displays must match punctuation as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });
});
