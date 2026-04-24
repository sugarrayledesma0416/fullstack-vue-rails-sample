<template>
  <div>
    <div class="l-center-block  l-center-block--32">
      <div class="u-txt-ctr">
        <template v-if="anyAssessments">
          <div :class="testClass('assessment-to-do-list')">
            <h2 class="assessments-header  u-txt-ctr">
              To Do
            </h2>
            <template v-if="anyToDoAssessments">
              <Workset
                v-for="(assessment, index) in data['to-do']"
                :key="assessment.link"
                :assessment="assessment"
                :worksetIconPath="worksetIconPath"
                :index="index" />
            </template>
            <template v-else>
              <div class="l-line  l-line--ctr  l-line--wrap">
                <div
                  class="assessment__picture">
                  <vhl-icon size="xxxl" :path="finishedIconPath" />
                </div>

                <div class="assessments-all-finished-message">
                  You finished all your assessments. Good job!
                </div>
              </div>
            </template>
          </div>
          <div
            v-if="anyFinishedAssessments"
            :class="testClass('assessment-finished-list')">
            <h2 class="assessments-header  u-txt-ctr">
              Finished
            </h2>
            <AssessmentList :assessments="data['finished']" />
          </div>
        </template>
        <template v-else>
          <div class="u-txt-bold  u-txt-24">
            Hooray!
          </div>
          <div>You have no assessments.</div>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import Workset from './Workset';
  import AssessmentList from './AssessmentList';

  export default {
    name: 'AssignmentsApp',
    components: {
      Workset,
      AssessmentList,
    },
    props: {
      assessmentsData: { required: true, type: String },
      finishedIconPath: { required: true, type: String },
      worksetIconPath: { required: true, type: String },
    },
    setup(props) {
      const data = JSON.parse(props.assessmentsData);

      const anyFinishedAssessments = computed(
        () => data['finished']?.length
      );

      const anyToDoAssessments = computed(
        () => data['to-do']?.length
      );

      const anyAssessments = computed(
        () => anyFinishedAssessments.value || anyToDoAssessments.value
      );

      return {
        anyAssessments,
        anyFinishedAssessments,
        anyToDoAssessments,
        data,
        testClass,
      };
    },
  };
</script>

<style lang="sass" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

.assessment__picture {
  width: 8rem;
  max-width: 8rem;
}

.assessments-all-finished-message {
  line-height: 2;
  color: var(--ui-tertiary-darkest);
  font-size: var(--font-4);
  width: 20rem;
}

/* ================================================================================= *

    Layout blocks:

    Simple layout components like insets, etc.

 * ================================================================================= */
.l-center-block {
  max-width: mod(40);
  margin-left: auto;
  margin-right: auto;

  &--16 { max-width: mod(16); }
  &--24 { max-width: mod(24); }
  &--32 { max-width: mod(32); }
}

/* ================================================================== *

    Pill -- shared skin

* =================================================================== */

/*
  Pill

  Used for components like tags/badges.
*/
@mixin pill() {
  display: inline-block;
  text-transform: uppercase;
  font-size: var(--font-2);
  background-color: var(--ui-fill-color);
  border-radius: mod(1);
  color: var(--ui-text-color);
  padding: 0 rpx(8);
  vertical-align: rpx(2);
  min-width: 5rem;
  white-space: nowrap;
  width: min-content; /* shrink-wrap */
 }

.assessments-header {
  @include pill();
  text-transform: unset;
  font-size: var(--font-5);
  font-weight: normal;
  border-radius: mod(0.75);
  padding: rpx(8) rpx(32);
  margin-top: 1rem;
  margin-bottom: 1.5rem;
  // TODO: replace literal color names with UI Role properties.
  --brown-lightest: #ede2d5;
  --brown-darker: #593a15;
  --ui-fill-color: var(--brown-lightest);
  --ui-text-color: var(--brown-darker);

  @include viewport-min(md) {
    margin-top: 2rem;
  }
}
</style>
