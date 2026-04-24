<template>
  <div class="standard-details">
    <div
      v-if="hasDataToShow"
      class="standard-details__container">
      <div class="standard-details__title">
        Standard
      </div>
      <div class="standard-details__label">
        <h2 :class="testClass('standard-details-label')">{{ props.standardDetails.label}}</h2>
      </div>
      <div class="standard-details__title">
        Description
      </div>
      <div class="standard-details__description">
        <p :class="testClass('standard-details-description')">
          {{ props.standardDetails.description}}
        </p>
      </div>
      <div class="standard-details__title">
        <tippy
          :content="props.tooltipInfo.score.text"
          :placement="props.tooltipInfo.score.position">
          Scores
        </tippy>
      </div>
      <div class="standard-details__table">
        <table class="c-table">
          <thead>
            <tr class="c-header-row">
              <th scope="col">Mid-Unit</th>
              <th scope="col">End-of-Unit</th>
              <th scope="col">Mid-Book</th>
              <th scope="col">End-of-Book</th>
            </tr>
          </thead>
          <tbody>
            <tr class="c-row">
              <td v-for="(value, key) in assessmentsUnit" :key="key">
                <template v-if="scoreData.list[value]">
                  {{ scoreData.list[value].percent_correct % 1 === 0
                      ? scoreData.list[value].percent_correct
                      : scoreData.list[value].percent_correct.toFixed(2)
                  }}%
                  <button
                    class="score-circle-value"
                    :class="testClass(`assessment-percent-${value}`)"
                    @click="openReviewModal(value)">
                    {{ scoreData.list[value].items_count }}
                  </button>
                </template>
                <template v-else>
                  --
                </template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="u-txt-upper  u-txt-16  u-txt-gray-6">
        Content
      </div>
      <a
        :class="testClass('search-matching-content')"
        :href="standardsAssigningPath"
        target="_blank"
        rel="noopener noreferrer">
        Find Matching Content
      </a>
      <AssessmentItemsModal
        v-show="showAssessmentItems"
        :assessmentItemModalConfig="assessmentItemModalConfig"
        :reviewPath="props.reviewPath"
        :standardDetails="props.standardDetails"
        :errorIconPath="errorIconPath"
        :successIconPath="successIconPath"
        @toggle-assessment-items-modal-visibility="toggleAssessmentItemsModalVisibility()" />
    </div>
    <div
      v-else
      class="standard-details__container-default">
      <StandardsDetailsIcon class="standards-details-icon" />
      <h2 class="standard-details__default-title">
        Please Select a Standard
      </h2>
      <p>Select a standard on the left in the table to view the standard definition.</p>
    </div>
  </div>
</template>
<script setup>
  import { computed, ref, reactive, onUpdated, watch } from 'vue';
  import { testClass } from 'music';
  /* eslint-disable-next-line max-len*/
  import StandardsDetailsIcon from './StandardsDetailsIcon.vue';
  import { Tippy } from 'vue-tippy';
  import AssessmentItemsModal from '../../share_feature/AssessmentItemsModal';

  const props = defineProps({
    errorIconPath: { required: true, type: String },
    reviewPath: { required: true, type: String },
    standardDetails: { required: true, type: Object },
    standardsAssigningUrl: { required: true, type: String },
    successIconPath: { required: true, type: String },
    summary: { required: true, type: Object },
    tooltipInfo: { required: true, type: Object },
    unitId: { type: Number, default: 0 },
  });

  const showAssessmentItems = ref(false);
  const standardsAssigningPath = ref('#');
  const scoreData = reactive({ list: {}});
  const assessmentsUnit = ['Mid-Unit', 'End-of-Unit', 'Mid-Book', 'End-of-Book'];

  const hasDataToShow = computed(() => {
    return Object.keys(props.standardDetails).length > 0;
  });

  const assessmentItemModalConfig = ref(
    {
      isModalOpen: false,
      itemGuids: [],
      standardLabel: '',
    }
  );

  watch(() => props.standardDetails.standard_guid, () => {
    fillScoreData();
  });

  onUpdated(() => {
    standardsAssigningPath.value = `${props.standardsAssigningUrl}?standards=${props.standardDetails.id}&selected_unit=${props.unitId}`;
  });

  /**
   * Create an object with the structure to render the assessment breakdown unit info.
   */
  function fillScoreData() {
    const standardSelected = props.summary[props.standardDetails.standard_guid];
    const data = {};
    scoreData.list = {};
    if (standardSelected) {
      Object.values(standardSelected).forEach((activity) => {
        data[activity.label] = activity;
      });
      scoreData.list = data;
    }
  }

  /**
   * Opens review items modal for the clicked assessment.
   * @param { string } assessmentSelected
   */
  function openReviewModal(assessmentSelected) {
    const itemGuids = Object.values(scoreData.list[`${assessmentSelected}`].assessment_item_guids);
    assessmentItemModalConfig.value.itemGuids = itemGuids;
    assessmentItemModalConfig.value.isModalOpen = true;
    assessmentItemModalConfig.value.standardLabel = props.standardDetails.label;
  }

  /**
   * Toggle the assessment items visibility
   */
  function toggleAssessmentItemsModalVisibility() {
    assessmentItemModalConfig.value.isModalOpen = false;
    showAssessmentItems.value = !showAssessmentItems.value;
  }
</script>
<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .standards-modal-header {
    border-bottom: rpx(1) solid $gray-e;
  }

  .standard-details {
    background-color: rgba($gray-f5, 0.5);

    &__container,
    &__container-default {
      display: flex;
      flex-direction: column;
      padding: 2rem 2.5rem;
      font-size: 1rem;
      min-height: 30rem;
    }

    &__container-default {
      padding: 5rem;
      align-items: center;

      p {
        margin-top: 1rem;
        max-width: 21rem;
      }
    }

    &__label {
      text-align: left;
      font-weight: bold;
      margin-bottom: rpx(23);
    }

    &__description {
      text-align: justify;
      margin-bottom: rpx(23);

      p {
        margin: 0;
      }
    }

    &__default-title {
      color: $gray-9;
      font-size: rpx(20);
      text-align: center;
    }

    &__title {
      text-transform: uppercase;
      font-size: rpx(16);
      color: $gray-6;
    }

    &__table {
      background-color: $white;
      border-radius: rpx(6);
      box-shadow: 0 rpx(2) rpx(10) rpx(0) rgba(0, 0, 0, 0.10);
      padding: rpx(8);
      margin-bottom: rpx(30);

      .c-table {
        margin: 0;

        th,
        td {
          text-align: center;
          color: $gray-3;
        }

        .c-row:last-child > td {
          border-bottom: 0;
        }

        .score-circle-value {
          background-color: $white;
          border-radius: 50%;
          border: 0;
          box-shadow: 0 rpx(2) rpx(10) rpx(0) rgba(0, 0, 0, 0.25);
          color: $link-color;
          cursor: pointer;
          display: inline-block;
          height: 2rem;
          margin-left: rpx(9);
          padding: 0;
          width: 2rem;
        }
      }
    }
  }
</style>
