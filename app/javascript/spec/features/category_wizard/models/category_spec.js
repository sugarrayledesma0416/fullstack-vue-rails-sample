import Category from 'features/category_wizard/models/category';
import { pick } from 'shared/utils';

const categoryArgs = {
  accept_late_work: false,
  credit_only: true,
  current_scoring_ruleset: {
    ignore_accents: true,
    ignore_capitalization: false,
    ignore_punctuation: false,
  },
  drop_low_scores: 10,
  enhanced_feedback_disabled: true,
  has_assessment_assignments: true,
  has_assignments: true,
  id: 100,
  late_work_penalty: 'flat_percent',
  max_attempts: 1,
  name: 'some category name',
  penalty_percent: 10,
  rank: 1,
  weighting_percent: 50,
};

let category;

function setAccentMeta(langHasAccents) {
  const metaTag = document.createElement('meta');
  metaTag.name = 'VHL.program_accent_bar_enabled';
  metaTag.content = String(langHasAccents);
  document.querySelector('head').appendChild(metaTag);
}

describe('Category Model', () => {
  describe('constructor with empty arguments in a Spanish program', () => {
    beforeEach(() => {
      setAccentMeta(true);
      category = new Category();
    });

    it('initializes category with default values', () => {
      const defaultValues = {
        acceptLateWork: true,
        creditOnly: false,
        currentScoringRuleset: {
          mustMatchAccents: true,
          mustMatchCapitalization: false,
          mustMatchPunctuation: false,
        },
        dropLowScores: 0,
        enhancedFeedbackDisabled: false,
        hasAssessmentAssignments: false,
        hasAssignments: false,
        id: null,
        lateWorkPenalty: 'percent_per_day',
        maxAttempts: 2,
        name: '',
        penaltyPercent: 5,
        rank: 0,
        weightingPercent: 0,
      };
      const valuesInCategory = pick(
        category,
        'acceptLateWork',
        'creditOnly',
        'currentScoringRuleset',
        'dropLowScores',
        'enhancedFeedbackDisabled',
        'hasAssessmentAssignments',
        'hasAssignments',
        'id',
        'lateWorkPenalty',
        'maxAttempts',
        'name',
        'penaltyPercent',
        'rank',
        'weightingPercent'
      );

      expect(valuesInCategory).toEqual(defaultValues);
    });
  });

  describe('constructor with arguments', () => {
    beforeEach(() => {
      category = new Category(categoryArgs);
    });

    it('initializes category with provided values', () => {
      const expextedValues = {
        acceptLateWork: false,
        creditOnly: true,
        currentScoringRuleset: {
          mustMatchAccents: false,
          mustMatchCapitalization: true,
          mustMatchPunctuation: true,
        },
        dropLowScores: 10,
        enhancedFeedbackDisabled: true,
        hasAssessmentAssignments: true,
        hasAssignments: true,
        id: 100,
        lateWorkPenalty: 'flat_percent',
        maxAttempts: 1,
        name: 'some category name',
        penaltyPercent: 10,
        rank: 1,
        weightingPercent: 50,
      };
      const valuesInCategory = pick(
        category,
        'acceptLateWork',
        'creditOnly',
        'currentScoringRuleset',
        'dropLowScores',
        'enhancedFeedbackDisabled',
        'hasAssessmentAssignments',
        'hasAssignments',
        'id',
        'lateWorkPenalty',
        'maxAttempts',
        'name',
        'penaltyPercent',
        'rank',
        'weightingPercent'
      );

      expect(valuesInCategory).toEqual(expextedValues);
    });
  });
});
