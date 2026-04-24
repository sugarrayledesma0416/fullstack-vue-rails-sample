import { metaTagContent } from 'music';

/** Class for Course Category Model. */
export default class Category {
  /**
   * @typeDef CurrentScoringRulesetArgsObject
   * @property {boolean} ignore_accents
   * @property {boolean} ignore_capitalization
   * @property {boolean} ignore_punctuation
   */

  /**
   * @typeDef CategoryArgsObject
   * @property {number} id - category id
   * @property {string} name - category name
   * @property {number} weighting_percent - category weight percentage
   * @property {boolean} has_assessment_assignments - whether category has assessment assignments
   * @property {boolean} hasAssignments - whether category has assignments
   * @property {boolean} credit_only - whether category is credit only
   * @property {number} maxAttempts - maximum number of attempts
   * @property {boolean} enhanced_feedback_disabled - whether enhanced feedback is disabled
   * @property {boolean} accept_late_work - whether to accept late work
   * @property {'none' | 'flat_percent' | 'percent_per_day'} late_work_penalty - late work
   * penalty type
   * @property {number} penalty_percent - penalty percentage
   * @property {number} rank - rank
   * @property {CurrentScoringRulesetArgsObject} current_scoring_ruleset
   * @property {number} drop_low_scores
   */

  /**
   * @constructor
   * @param {CategoryArgsObject} args
   */
  constructor(args = {}) {
    this.id = args.id || null;
    this.name = args.name || '';
    this.weightingPercent = parseInt(args.weighting_percent) || 0;
    this.hasAssessmentAssignments = args.has_assessment_assignments || false;
    this.hasAssignments = args.has_assignments || false;
    this.creditOnly = args.credit_only || false;
    this.maxAttempts = parseInt(args.max_attempts) || 2;
    this.enhancedFeedbackDisabled = args.enhanced_feedback_disabled || false;
    this.acceptLateWork = (typeof args.accept_late_work === 'undefined') ?
      true : args.accept_late_work;
    this.lateWorkPenalty = args.late_work_penalty || 'percent_per_day';
    this.penaltyPercent = parseInt(args.penalty_percent) || 5;
    this.rank = parseInt(args.rank) || 0;
    this.languageCode = args.languageCode;
    this.langHasAccents = metaTagContent('VHL.program_accent_bar_enabled') === 'true';
    this.langHasCases = this.languageCode != 'zh';
    this.currentScoringRuleset = {
      mustMatchAccents: !this.langHasAccents ? false :
        this.rulesetFlag(args, 'ignore_accents', true),
      mustMatchCapitalization: !this.langHasCases ? false :
        this.rulesetFlag(args, 'ignore_capitalization', false),
      mustMatchPunctuation: this.rulesetFlag(args, 'ignore_punctuation', false),
    };
    this.dropLowScores = args.drop_low_scores || 0;
  }

  /**
   * @private
   * This method returns Current Scoring Ruleset's flag value from agument for the given flag.
   * This method inverts the flag because the flags on the server side
   * are negative (eg. ignore_accent instead of must_match_accents)
   * @param {CategoryArgsObject} args - Argument object having detail about Current Scoring Ruleset
   * @param {string} flag - Flag name
   * @param {boolean} defaultValue - Default value for the given flag
   * @return {boolean} - Value of the given flag
   */
  rulesetFlag(args, flag, defaultValue) {
    return args.current_scoring_ruleset ? !args.current_scoring_ruleset[flag] : defaultValue;
  }
}
