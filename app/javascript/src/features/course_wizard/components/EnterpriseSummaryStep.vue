<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="summary-step">
      <EnterpriseStepHeader headingLevel="3" :isEditable="courseDataStore.editCourseMode" />

      <h1 class="step-title">
        Review Course Setup
      </h1>
      <div class="l-simple-grid-v3  l-simple-grid-v3--1-1-1">
        <dl class="summary-step__info">
          <div
            class="summary-step__info-item"
            :class="testClass('summary-name')">
            <dt class="summary-step__info-term">
              Course Name
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-start-name')">
              {{ courseDataStore.store.course.name }}
            </dd>
          </div>
          <div
            class="summary-step__info-item"
            :class="testClass('summary-name')">
            <dt class="summary-step__info-term">
              Course Length
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-start-name')">
              {{ classWeeks }} weeks
            </dd>
          </div>
          <div
            class="summary-step__info-item"
            :class="testClass('summary-name')">
            <dt class="summary-step__info-term">
              Days the class meets
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-start-name')">
              {{ classDays.join(', ') }}
            </dd>
          </div>
        </dl>
        <dl class="summary-step__info">
          <div
            class="summary-step__info-item"
            :class="testClass('summary-dates')">
            <dt class="summary-step__info-term">
              Start date
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-start-date')">
              {{ courseDataStore.store.course.startDate }}
            </dd>
            <dt class="summary-step__info-term">
              End date
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-end-date')">
              {{ courseDataStore.store.course.endDate }}
            </dd>
          </div>
          <div
            class="summary-step__info-item"
            :class="testClass('summary-access-level')">
            <dt class="summary-step__info-term">
              Access level
            </dt>
            <dd class="summary-step__info-details">
              {{ accessLevel }}
            </dd>
          </div>
        </dl>
        <dl class="summary_step__info">
          <div
            class="summary-step__info-item"
            :class="testClass('summary-lessons')">
            <dt
              class="summary-step__info-term"
              :class="testClass('summary-first-unit')">
              First {{ courseDataStore.store.courseOptions.program.unit_label || 'Unit' }}
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-first-unit-id')">
              {{ findUnitLabel(courseDataStore.store.course.firstUnitId) }}
            </dd>

            <dt
              class="summary-step__info-term"
              :class="testClass('summary-last-unit')">
              Last {{ courseDataStore.store.courseOptions.program.unit_label || 'Unit' }}
            </dt>
            <dd
              class="summary-step__info-details"
              :class="testClass('summary-last-unit-id')">
              {{ findUnitLabel(courseDataStore.store.course.lastUnitId) }}
            </dd>
          </div>
        </dl>
        <dl class="summary-step__info">
          <div
            v-if="courseDataStore.store.courseOptions.supported_standard_sets.length"
            class="summary-step__info-item"
            :class="testClass('summary-standard-sets')">
            <dt class="summary-step__info-term">
              Standards selected
            </dt>
            <dd class="summary-step__info-details">
              <template v-if="hasSelectedStandardSets">
                <div
                  v-for="standard_set_group in selectedStandardSetGroups">
                  <MusicIcon variant="checkmark" size="lg" />
                  <span :class="testClass('summary-standard-set-name')">
                    {{ standard_set_group.name }}
                  </span>
                </div>
              </template>
              <template v-else>
                None
              </template>
            </dd>
          </div>
        </dl>
      </div>
      <hr class="hr">

      <EnterpriseGradebookSummary />

      <div class="summary-step-loader">
        <img
          v-if="courseDataStore.store.saving"
          :src="loadingIconPath">
      </div>
    </div>
    <EnterpriseSetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isSaveDisabled="disableSaveButton"
      previousStep="enterprise-gradebook-step"
      :showSaveBtn="true"
      @save="courseDataStore.save()" />
  </div>
</template>

<script>
  import { inject, onMounted, onUnmounted, ref } from 'vue';
  import { toSentence, scrollToTopOfPage } from 'shared/utils';
  import { numberOfWeeksBetweenDateStrings } from 'shared/date_utils.js';
  import { testClass } from 'music';
  import EnterpriseGradebookSummary from './EnterpriseGradebookSummary';
  import EnterpriseSetupControls from './EnterpriseSetupControls';
  import EnterpriseStepHeader from './EnterpriseStepHeader';
  import MusicIcon from 'shared/vue/MusicIcon';

  export default {
    name: 'SummaryStep',
    components: { EnterpriseGradebookSummary, MusicIcon, EnterpriseSetupControls, EnterpriseStepHeader },
    props: {
      loadingIconPath: { default: '', type: String },
    },
    setup() {
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');
      const accessLevel = toSentence(courseDataStore.courseSerializer.coursePackagesNames(
        courseDataStore.store.courseOptions.levels,
        courseDataStore.store.courseOptions.components
      ));
      const disableSaveButton = ref(true);

      const cancelUrl = config.instAdmin ?
        `/institution_admin/templates/${config.programId}}?school_id={{config.schoolId}}` :
        `/instructor/dashboard/${config.programId}`;

      /**
       * returns the unit label for the course units.
       * @param {number} unitId - Id of the unit
       * @return {string}
       */
      function findUnitLabel(unitId) {
        const unit = courseDataStore.store.courseOptions.units.find((unit) => {
          return unit.id === unitId;
        });
        return unit.label;
      }

      /**
       * Sets a variable that indicates that the user scrolled near the
       * bottom of the page.
       * @param {event} event - The scroll event of the window.
       */
      function saveButtonEnableWithScroll(event) {
        if (
          (window.innerHeight + Math.ceil(window.pageYOffset + 120) ) >= document.body.offsetHeight
        ) {
          disableSaveButton.value = false;
        }
      }

      onMounted(() => {
        scrollToTopOfPage();
        saveButtonEnableWithScroll();
        window.addEventListener('scroll', saveButtonEnableWithScroll);
      });

      onUnmounted(() => {
        window.removeEventListener('scroll', saveButtonEnableWithScroll);
      });

      return {
        accessLevel,
        cancelUrl,
        config,
        courseDataStore,
        disableSaveButton,
        findUnitLabel,
        testClass,
      };
    },
    computed: {
      hasSelectedStandardSets() {
        return this.courseDataStore.store.courseOptions.supported_standard_sets.some(
          (standardSetGroup) =>
            this.courseDataStore.store.course.isStandardSetGroupSelected(standardSetGroup));
      },
      /**
       * Returns the selected standard set groups sorted alphabetically.
       */
      selectedStandardSetGroups() {
        return this.courseDataStore.store.courseOptions.supported_standard_sets.filter(
          standardSetGroup => this.courseDataStore.store.course.isStandardSetGroupSelected(
            standardSetGroup
          )
        ).sort(
          (left, right) => left.name.localeCompare(right.name)
        );
      },
      classWeeks() {
        return numberOfWeeksBetweenDateStrings(
          this.courseDataStore.store.course.startDate,
          this.courseDataStore.store.course.endDate
        );
      },
      classDays() {
        const days = this.courseDataStore.store.course.classDays;
        const possibleClassDays = [
          'Sunday', 'Monday', 'Tuesday', 'Wednesday',
          'Thursday', 'Friday', 'Saturday',
        ];
        return possibleClassDays.filter((_, i) => days[i]);
      },
    },
  };
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .summary-step {
    background-color: var(--music-true-gray-50, #f5f5f5);
    clear: both;
    font-size: 1.3em;
    min-height: music.rpx(480);
    overflow: auto;
    padding: 0.25rem;
    position: relative;
    text-align: left;
    margin-bottom: 3rem;
  }

  .edit-course .summary-step {
    padding: 0.9375rem;
  }

  .summary-course-name {
    color: var(--ui-text-color, #333);
    font-size: var(--font-7, 1.875rem);
    font-weight: normal;
  }

  .summary-step__info-term {
    font-size: 1rem;
    font-weight: 400;
    color: #595959;
  }

  .summary-step__info-details {
    font-size: 1rem;
    font-weight: 600;
    margin-bottom: 2.5rem;
  }

  .step-title {
    color: #595959;
    font-size: music.rpx(38);
    font-weight: 300;
    line-height: music.rpx(46);
    margin-top: music.rpx(32); 
    margin-bottom: music.rpx(28);
  }

  .hr {
    margin: 2.8rem 0 3.5rem 0;
  }

  .summary-step-loader {
    text-align: center;
  }
</style>
