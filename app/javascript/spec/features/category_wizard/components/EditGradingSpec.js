import EditGrading from 'features/category_wizard/components/EditGrading';
import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import { metaTagContent } from 'music';

/**
 * @typeDef CategoryObject
 * @property {boolean} creditOnly
 * @property {Object} currentScoringRuleset
 * @property {number} dropLowScores
 * @property {boolean} enhancedFeedbackDisabled
 * @property {number} maxAttempts
 */

const category = reactive({
  creditOnly: true,
  currentScoringRuleset: {
    mustMatchAccents: true,
    mustMatchCapitalization: false,
    mustMatchPunctuation: false,
  },
  dropLowScores: 0,
  enhancedFeedbackDisabled: true,
  languageCode: 'en',
  maxAttempts: 2,
  langHasAccents: true,
  langHasCases: true,
});

const metaAccent = document.createElement('meta');
metaAccent.setAttribute('name', 'VHL.program_accent_bar_enabled');
metaAccent.setAttribute('content', 'true');
document.querySelector('head').appendChild(metaAccent);

/**
 * This method gets wrapper for Category component
 * @param {CategoryObject} category - vue provide object required for Category component
 * @param {'es'|'fr'|'de'|'it'|'en'|'ru'|'zh'} lang - program language
 * @return {Wrapper}
 */
function getWrapper(category, lang = 'en') {
  const config = { languageCode: lang };
  const hasAccents = metaTagContent('VHL.program_accent_bar_enabled') === 'true';
  const hasCases = !(lang === 'zh');
  category.languageCode = lang;
  category.langHasAccents = hasAccents;
  category.currentScoringRuleset.mustMatchAccents = hasAccents;
  category.langHasCases = hasCases;
  return mount(EditGrading, {
    global: { provide: { category, config }},
  });
}

describe('EditGrading Component', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper(category, 'en');
    });

    it('displays max attempts category.', () => {
      expect(
        wrapper.get('.test-max-attempts').text()
      ).toBe('Maximum attempts*');
    });

    it('displays grading strictness category', () => {
      expect(
        wrapper.get('.test-grading-strictness').text()
      ).toBe('Grading Strictness');
    });

    it('displays assignment category', () => {
      expect(
        wrapper.get('.test-assignment-category').text()
      ).toBe('Assignments in this category will be:');
    });

    it('displays number of lowest grades category', () => {
      expect(
        wrapper.get('.test-lowest-grades').text()
      ).toBe('Number of lowest grades dropped:');
    });

    it('displays "For a grade" radio button selected', () => {
      expect(wrapper.get('.test-for-a-grade').element.checked).toBeFalsy();
    });

    it('displays "Provide students with enhanced feedback" radio button selected', () => {
      expect(
        wrapper.get('.test-enhanced-feedback-disabled').element.checked
      ).toBeTruthy();
    });
  });

  describe('in a Spanish program', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'true');
      wrapper = getWrapper(category, 'es');
    });

    it('displays accent marks count as checked', () => {
      expect(
        wrapper.get('.test-grading-accents-input').element.checked
      ).toBeTruthy();
    });

    it('displays capitalization count as not checked', () => {
      expect(
        wrapper.get('.test-grading-capitalization-input').element.checked
      ).toBeFalsy();
    });

    it('displays punctuation count as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('in an English program', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper(category, 'en');
    });

    it('does not display accent marks count option', () => {
      expect(
        wrapper.find('.test-grading-accents-input').exists()
      ).toBe(false);
    });

    it('displays capitalization count as not checked', () => {
      expect(
        wrapper.get('.test-grading-capitalization-input').element.checked
      ).toBeFalsy();
    });

    it('displays punctuation count as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('in a Russian program', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper(category, 'ru');
    });

    it('does not display accent marks count option', () => {
      expect(
        wrapper.find('.test-grading-accents-input').exists()
      ).toBe(false);
    });

    it('displays capitalization count as not checked', () => {
      expect(
        wrapper.get('.test-grading-capitalization-input').element.checked
      ).toBeFalsy();
    });

    it('displays punctuation count as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('in a Chinese program', () => {
    beforeEach(() => {
      metaAccent.setAttribute('content', 'false');
      wrapper = getWrapper(category, 'zh');
    });

    it('does not display accent marks count option', () => {
      expect(
        wrapper.find('.test-grading-accents-input').exists()
      ).toBe(false);
    });

    it('does not display capitalization count option', () => {
      expect(
        wrapper.find('.test-grading-capitalization-input').exists()
      ).toBe(false);
    });

    it('displays punctuation count as not checked', () => {
      expect(
        wrapper.get('.test-grading-punctuation-input').element.checked
      ).toBeFalsy();
    });
  });

  describe('click applicable details link', () => {
    beforeEach(async () => {
      wrapper = getWrapper(category, 'es');
      await wrapper.get('.test-applicable-details').trigger('click');
    });

    it('displays attempts details section', () => {
      expect(wrapper.find('.test-attempts-details').exists()).toBeTruthy();
    });
  });
});
