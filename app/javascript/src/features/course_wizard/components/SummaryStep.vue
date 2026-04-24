<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="summary-step">
      <StepHeader headingLevel="1" />
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

      <hr class="hr">

      <GradebookSummary />

      <div class="summary-step-loader">
        <img
          v-if="courseDataStore.store.saving"
          :src="loadingIconPath">
      </div>

      <SectionModal v-if="courseDataStore.store.courseSaved" />
    </div>
    <SetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isSaveDisabled="disableSaveButton"
      previousStep="gradebook-step"
      :showSaveBtn="true"
      @save="courseDataStore.save()" />
  </div>
</template>

<script>
  import { inject, onMounted, onUnmounted, ref } from 'vue';
  import { toSentence, scrollToTopOfPage } from 'shared/utils';
  import { testClass } from 'music';
  import GradebookSummary from './GradebookSummary';
  import SectionModal from './SectionModal';
  import SetupControls from './SetupControls';
  import StepHeader from './StepHeader';
  import MusicIcon from 'shared/vue/MusicIcon';

  export default {
    name: 'SummaryStep',
    components: { GradebookSummary, MusicIcon, SectionModal, SetupControls, StepHeader },
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
          standardSetGroup => this.courseDataStore.store.course.isStandardSetGroupSelected(standardSetGroup)
        ).sort(
          (left, right) => left.name.localeCompare(right.name)
        );
      },
    },
  };
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .summary-step {
    clear: both;
    color: #565656;
    min-height: 30rem;
    padding: 0.25rem;
    position: relative;
  }

  .edit-course .summary-step {
    border: #ebebeb solid 0.625rem;
    padding: 0.9375rem;
  }

  .summary-course-name {
    color: var(--ui-text-color, #333);
    font-size: var(--font-7, 1.875rem);
    font-weight: normal;
  }

  .summary-step__info-item {
    display: grid;
    grid-template-columns: rpx(220) auto;
  }

  .summary-step__info-term {
    font-size: 1rem;
    font-weight: 400;
    margin: 0 0 0.75rem 0;
    text-transform: uppercase;
  }

  .summary-step__info-details {
    font-size: 1rem;
  }

  .hr {
    margin: 2.8rem 0 3.5rem 0;
  }

  .summary-step-loader {
    text-align: center;
  }
</style>
