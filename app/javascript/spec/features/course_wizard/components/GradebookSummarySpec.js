import { mount } from '@vue/test-utils';
import CourseSerializer from 'features/course_wizard/services/course_serializer.js';
import GradebookSummary from 'features/course_wizard/components/GradebookSummary';

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  vol: true,
};

const category = {
  acceptLateWork: true,
  creditOnly: false,
  currentScoringRuleset: {
    mustMatchAccents: true,
    mustMatchCapitalization: false,
    mustMatchPunctuation: false,
  },
  dropLowScores: 1,
  enhancedFeedbackDisabled: false,
  lateWorkPenalty: 'percent_per_day',
  langHasAccents: true,
  langHasCases: true,
  maxAttempts: 2,
  name: 'Homework',
  penaltyPercent: 5,
  rank: 1,
  weightingPercent: 100,
};

const course = {
  name: 'Test Course',
  categories: [category],
};

const courseDataStore = {
  store: {
    course,
    courseOptions: {
      components: [],
      levels: [{ id: 64, name: 'Portales' }],
      program: {
        unit_label: 'Lession',
      },
      units: [
        { id: 1, label: 'Lession 1' },
        { id: 2, label: 'Lession 2' },
      ],
    },
  },
};
courseDataStore.courseSerializer = new CourseSerializer(course);

function updateScoringRuleset(changes) {
  return Object.assign(
    {},
    courseDataStore.store.course.categories[0].currentScoringRuleset,
    changes
  );
}

const getWrapper = (gradingStrictnessDelta) => {
  courseDataStore.store.course.categories[0].currentScoringRuleset =
    updateScoringRuleset(gradingStrictnessDelta);
  return mount(GradebookSummary, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
};

describe('GradebookSummary', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays GeneratePdf Component', () => {
      expect(wrapper.findComponent({ name: 'GeneratePdf' }).exists()).toBeTruthy();
    });

    it('displays category name ', () => {
      expect(wrapper.get('.test-category-name').text()).toBe('Homework');
    });

    it('displays category weight', () => {
      expect(wrapper.get('.test-category-weight').text()).toBe('100');
    });

    it('displays category number of lowest grades dropped', () => {
      expect(wrapper.get('.test-drop-low-scores').text()).toBe(
        'Number of lowest grades dropped: 1'
      );
    });
  });

  describe('when max attempt number for category is -1', () => {
    beforeEach(() => {
      category.maxAttempts = -1;
      wrapper = getWrapper();
    });

    it('displays "Unlimited" as max attempts', () => {
      expect(wrapper.get('.test-category-max-attempts').text()).toBe(
        'Maximum Attempts: Unlimited'
      );
    });
  });

  describe('when max attempt number for category is not -1', () => {
    beforeEach(() => {
      category.maxAttempts = 2;
      wrapper = getWrapper();
    });

    it('displays max attempt number as max attempts', () => {
      expect(wrapper.get('.test-category-max-attempts').text()).toBe('Maximum Attempts: 2');
    });
  });

  describe('when must match accent is true for a category', () => {
    beforeEach(() => {
      wrapper = getWrapper({ mustMatchAccents: true });
    });

    it('displays "Yes" as "Accents must match"', () => {
      expect(wrapper.get('.test-must-match-accent').text()).toBe('Accents must match: Yes');
    });
  });

  describe('when must match accent is false for a category', () => {
    beforeEach(() => {
      wrapper = getWrapper({ mustMatchAccents: false });
    });

    it('displays "No" as "Accents must match"', () => {
      expect(wrapper.get('.test-must-match-accent').text()).toBe('Accents must match: No');
    });
  });

  describe('when must match capitalization is true for a category', () => {
    beforeEach(() => {
      category.currentScoringRuleset.mustMatchCapitalization = true;
      wrapper = getWrapper();
    });

    it('displays "Yes" as "Capitalization must match"', () => {
      expect(wrapper.get('.test-must-match-capitalization').text()).toBe(
        'Capitalization must match: Yes'
      );
    });
  });

  describe('when must match capitalization is false for a category', () => {
    beforeEach(() => {
      category.currentScoringRuleset.mustMatchCapitalization = false;
      wrapper = getWrapper();
    });

    it('displays "No" as "Capitalization must match"', () => {
      expect(wrapper.get('.test-must-match-capitalization').text()).toBe(
        'Capitalization must match: No'
      );
    });
  });

  describe('when must match punctuation is true for a category', () => {
    beforeEach(() => {
      category.currentScoringRuleset.mustMatchPunctuation = true;
      wrapper = getWrapper();
    });

    it('displays "Yes" as "Punctuation must match"', () => {
      expect(wrapper.get('.test-must-match-punctuation').text()).toBe(
        'Punctuation must match: Yes'
      );
    });
  });

  describe('when must match punctuation is false for a category', () => {
    beforeEach(() => {
      category.currentScoringRuleset.mustMatchPunctuation = false;
      wrapper = getWrapper();
    });

    it('displays "No" as "Punctuation must match"', () => {
      expect(wrapper.get('.test-must-match-punctuation').text()).toBe(
        'Punctuation must match: No'
      );
    });
  });

  describe('when enhanced feedback is disabled', () => {
    beforeEach(() => {
      category.enhancedFeedbackDisabled = true;
      wrapper = getWrapper();
    });

    it('displays "Fill in the Blank Feedback" as "Disabled (recommended "' +
       '"for assessment items)"', () => {
      expect(wrapper.get('.test-enhanced-feedback-info').text()).toBe(
        'Disabled (recommended for assessment items)'
      );
    });
  });

  describe('when enhanced feedback is enabled', () => {
    beforeEach(() => {
      category.enhancedFeedbackDisabled = false;
      wrapper = getWrapper();
    });

    it('displays "Fill in the Blank Feedback" as "Show where errors are"', () => {
      expect(wrapper.get('.test-enhanced-feedback-info').text()).toBe('Show where errors are');
    });
  });
});
