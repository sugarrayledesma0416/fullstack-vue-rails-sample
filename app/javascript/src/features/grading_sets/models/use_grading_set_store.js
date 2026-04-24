import { defineStore } from 'pinia';

/**
 * @typeDef RubricColumnHeader
 * @property {string} id - the rubric column header id
 * @property {string} label - the rubric column header label
 * This is generated from parsed JSON from rubric content object,
 * representing the column headers for each performance.
 */

/**
 * @typeDef RubricCriteria
 * @property {string} title
 * @property {number} max_score - the highest score from the list of performance scores
 * @property {Array<RubricCriteriaPerformance>} performances
 */

/**
 * @typeDef RubricCriteriaPerformance
 * @property {string} description
 * @property {string} header_id - id mapping to RubricColumnHeader
 * @property {number} score - score for this performance
 */

/**
 * @typeDef UserScores
 * @property {string} userId - user id
 * @property {string} attemptId - attempt id for user
 * @property {Object|null} rubric - existing rubric criteria scores
 * @property {string|null} manual - existing manual score
 */

/**
 * @typeDef GradingSetStoreConfig
 * @property {Array.<RubricColumnHeader>} rubricColumnHeaders
 * @property {Array.<RubriCriteria>} rubricCriterias
 * @property {boolean} isInitRubricGraded - whether or not to initialize
 * with rubric grading controls
 * @property {Array.<UserScores>} scores
 * @property {number} pointsPossible - points possible for the current question.
 */

/**
 * @param {GradingSetStoreConfig} config
 * @return {Function} A Pinia `useStore` function, which retrieves the Pinia store,
 *  defining it if necessary.
 */
const useGradingSetStore = function(config) {
  return defineStore(
    'store',
    {
      state: () => {
        return {
          rubricColumnHeaders: config.rubricColumnHeaders,
          rubricCriterias: config.rubricCriterias,
          focusedCriteriaIndex: null,
          earnedPoints: generatePointsMap(
            config.rubricCriterias,
            config.isInitRubricGraded,
            config.scores,
            config.pointsPossible,
          ),
          isRubricGraded: config.isInitRubricGraded,
          pointsPossible: config.pointsPossible,
        };
      },
      getters: {
      },
      actions: {
        updateFocusedCriteriaPoints(event) {
          const criteriaTitle = event.target.getAttribute('data-criteria-title');
          const pointsToAward = parseInt(event.target.getAttribute('data-points-to-award'));
          const focusedUserScore = this.earnedPoints.find((item) => item.userId === this.focusedUserId)
          focusedUserScore.criteria[criteriaTitle].earned = pointsToAward;
        },
        setNoPoints(score) {
          if (this.isRubricGraded) {
            // set each earned criteria to 0. Total is updated via $subscribe
            for (const crit in score.criteria) {
              if ({}.hasOwnProperty.call(score.criteria, crit)) {
                score.criteria[crit].earned = 0;
              }
            }
          } else {
            // set the earned total points to 0
            score.totalPoints = 0;
          }
        },
        setFullPoints(score) {
          if (this.isRubricGraded) {
            // Set each criteria to its max allowed points. Total is update via $subscribe.
            for (const crit in score.criteria) {
              if ({}.hasOwnProperty.call(score.criteria, crit)) {
                score.criteria[crit].earned =
                  score.criteria[crit].max_score;
              }
            }
          } else {
            // set the earned points to question points possible.
            score.totalPoints = this.pointsPossible;
          }
        },
        updateTotalPoints() {
          // Sums points of rubric criterias & assigns to totalPoints.
          if(this.isRubricGraded) {
            this.earnedPoints.forEach((item) => {
              const arr = [];
              for (const crit in item.criteria) {
                if ({}.hasOwnProperty.call(item.criteria, crit)) {
                  arr.push(item.criteria[crit].earned);
                  item.totalPoints = arr.reduce((prev, current) => prev + current, 0);
                }
              }
            });
          }
        },
        clearScores() {
          //TODO maybe remove this.
        },
        makeCriteriaScoresTemplate() {
          return makeCriteriaScoresTemplate(this.rubricCriterias);
        }
      },
    }
  );

  /* Private functions available only within this setup function. */

  /**
   * @param {Object} criterias - rubric criteria data.
   * @param {Object|null} existingRubricScores - A hash mapping of criteria titles to points,
   * if it exists.
   * @param {number|null} existingManualScore - an existing manual score if it exists.
   * @param {number} pointsPossible - the points possible for the score.
   * @return {Object} A hash mapping of criteria titles to points
   * and the total points. Example:
   * {
   *   criteria: {
   *     Content: { earned: null, max_score: 5 }
   *     Organization: { earned: null, max_score: 5 }
   *     Accuracy: { earned: null, max_score: 5 }
   *   },
   *   totalPoints: 0, //totalPoints is either the sum of criteria scores OR a manual score.
   * }
   */
  function generatePointsMap(criterias, rubricGraded, scores, pointsPossible) {
    return scores.map((score) => {
      const pointsMap = {
        userId: score.user_id,
        attemptId: score.attempt_id,
        studentName: score.student_name,
        commentBoxSelector: score.comment_box_class,
        isInstructor: score.instructor,
        isPracticing: score.practicing,
        isGradable: score.gradable,
        inputName: score.input_name,
        criteria: {},
        totalPoints: undefined,
      };
      if (score.rubric) {
        const rubricScores = JSON.parse(score.rubric);
        criterias.forEach((crit, index) => {
          pointsMap.criteria[crit.title] = {
            earned: parseFloat(rubricScores[crit.title]),
            max_score: parseFloat(criterias[index].max_score),
          }
        });
        updateTotalPoints(pointsMap);
      } else {
        pointsMap.criteria = makeCriteriaScoresTemplate(criterias);
      }
      if (score.manual) {
        pointsMap.totalPoints = score.manual;
      }
      if(pointsMap.totalPoints === 0) {
        pointsMap.isFullPointsDisabled = false;
        pointsMap.isNoPointsDisabled = true;
      }
      if (pointsMap.totalPoints === pointsPossible) {
        pointsMap.isFullPointsDisabled = true;
        pointsMap.isNoPointsDisabled = false;
      }
      return pointsMap;
    });
  }

  function makeCriteriaScoresTemplate(criterias) {
    const template = {};
    criterias.forEach((crit) => {
      template[crit.title] = {
        earned: null,
        max_score: parseFloat(crit.max_score),
      };
    });
    return template;
  }

  /**
   * @param {Object} earnedPoints
   * Updates the totalPoints key of earnedPoints
   */
  function updateTotalPoints(earnedPoints) {
    const arr = [];
    for (const crit in earnedPoints.criteria) {
      if ({}.hasOwnProperty.call(earnedPoints.criteria, crit)) {
        arr.push(earnedPoints.criteria[crit].earned);
      }
    }
    earnedPoints.totalPoints = arr.reduce((prev, current) => prev + current, 0);
  }
};
export default useGradingSetStore;
