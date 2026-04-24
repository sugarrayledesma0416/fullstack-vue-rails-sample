<template>
  <div class="gradebook-summary">
    <div class="header">
      <CategoryTitle tagName="h3" class="title">
        Gradebook Categories
      </CategoryTitle>
      <div class="generate-pdf">
        <GeneratePdf />
      </div>
    </div>
    <div
      v-for="(category, index) in courseDataStore.store.course.categories"
      :key="index"
      class="category"
      :class="testClass('category')">
      <div class="category-info">
        <div class="category-name" :class="testClass('category-name')">
          {{ category.name }}
        </div>
        <div class="category-weight" :class="testClass('category-weight')">
          {{ category.weightingPercent }}
        </div>
      </div>

      <div class="category-settings">
        <CategorySetting class="category-setting" title="Organization">
          <div>
            Category will contain {{
              category.flat ?
                'a few assignments all listed together (such as quizzes or projects)' :
                'a lot of assignments grouped by lesson and strand (such as homework)'
            }}.
          </div>
          <div>
            For all assignments in this category, students will receive full
            credit regardless of their score:
            {{ category.creditOnly ? 'Yes' : 'No' }}
          </div>
        </CategorySetting>

        <CategorySetting class="category-setting" title="grading">
          <div :class="testClass('category-max-attempts')">
            Maximum Attempts: {{ maxAttemptsLabel(category.maxAttempts) }}
          </div>
          <div :class="testClass('drop-low-scores')">
            Number of lowest grades dropped: {{ category.dropLowScores }}
          </div>
          <div class="grading-strictness">
            <span>Grading Strictness</span>
            <ul class="grading-strictness-info">
              <li
                v-if="category.langHasAccents"
                :class="testClass('must-match-accent')">
                Accents must match:
                {{ category.currentScoringRuleset.mustMatchAccents ? 'Yes' : 'No' }}
              </li>
              <li
                v-if="category.langHasCases"
                :class="testClass('must-match-capitalization')">
                Capitalization must match:
                {{
                  category.currentScoringRuleset.mustMatchCapitalization ?
                    'Yes' :
                    'No'
                }}
              </li>
              <li :class="testClass('must-match-punctuation')">
                Punctuation must match:
                {{ category.currentScoringRuleset.mustMatchPunctuation ? 'Yes' : 'No' }}
              </li>
            </ul>
          </div>
          <div class="enhanced-feedback">
            <span>Fill in the Blank Feedback: </span>
            <div class="enhanced-feedback-info" :class="testClass('enhanced-feedback-info')">
              {{
                category.enhancedFeedbackDisabled ?
                  'Disabled (recommended for assessment items)' :
                  'Show where errors are'
              }}
            </div>
          </div>
        </CategorySetting>

        <CategorySetting class="category-setting" title="Lateness">
          <div>
            Students can submit overdue assignments for credit:
            {{ category.acceptLateWork ? 'Yes' : 'No' }}
          </div>
          <div>
            <div>
              <div>
                Penalty assessed: {{ humanize(category.lateWorkPenalty) }}
              </div>
              <div v-if="category.lateWorkPenalty !== 'none' ">
                Penalty amount: {{ category.penaltyPercent }}
              </div>
            </div>
          </div>
        </CategorySetting>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { inject } from 'vue';
  import { humanize } from 'shared/utils';
  import { testClass } from 'music';
  import GeneratePdf from './GeneratePdf';
  import CategorySetting from './CategorySetting';
  import CategoryTitle from './CategoryTitle';

  const courseDataStore = inject('courseDataStore');

  /**
   * returns the max attempt label a category.
   * @param {number} maxAttemptsNum - max attempt number
   * @return {string|number}
   */
  function maxAttemptsLabel(maxAttemptsNum) {
    return maxAttemptsNum === -1 ? 'Unlimited' : maxAttemptsNum;
  }
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .gradebook-summary {
    color: #565656;
  }

  .header {
    display: flex;
    align-items: center;
    margin-bottom: 0.1875rem;
  }

  .title {
    display: inline-flex;
    flex-basis: rpx(300);
  }

  .generate-pdf {
    flex-basis: auto;
  }

  .category {
    display: grid;
    grid-template-columns: 18.75rem auto;
  }

  .category-info {
    padding-right: 2rem;
  }

  .category-name {
    background-color: $gray-e;
    border: 0.0625rem solid $gray-e;
    font-size: 1rem;
    font-weight: bold;
    max-width: rpx(200);
    padding: 0.6rem;
    text-align: center;
  }

  .category-weight {
    border-bottom: 0.0625rem solid $gray-e;
    border-left: 0.0625rem solid $gray-e;
    border-right: 0.0625rem solid $gray-e;
    color: $gray-9;
    font-weight: normal;
    max-width: rpx(200);
    padding: 0.7rem;
    text-align: center;
  }

  .category-settings {
    padding-top: rpx(36);
  }

  .category-setting {
    margin-bottom: 1.3rem;
  }

  .grading-strictness-info {
    list-style: none;
  }
</style>
