<template>
  <ContentSetting :class="testClass('individualized-assigning')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="individual-assign"
      v-model:checked="courseDataStore.store.course.allowIndividualAssign"
      name="allow_individual_assign"
      testSelectorInput="allow-individual-assign-checkbox"
      :title="courseDataStore.store.courseHasIndividualAssignments ? disabledIndAssignMsg : ''"
      :disabled="disableIndividualizedAssigningCb()">
      Enable Individualized Assigning to manage assignments specifically for selected students.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
    <span
      v-if="displaySpinner"
      class="individual-assign-loading"
      :class="testClass('individual-assign-loading')">
      <img class="loader-image" :src="spinnerImage"> Calculating if you can change this option.
    </span>
  </ContentSetting>
</template>

<script setup>
  import { computed, inject } from 'vue';
  import ContentSetting from '../ContentSetting';
  import { testClass } from 'music';
  import spinnerImage from 'images/loading_32.gif';
  import VhlCheckbox from '../../VhlCheckbox';

  const courseDataStore = inject('courseDataStore');

  const disabledIndAssignMsg = 'This setting is disabled because you already have ' +
    'individually assigned activities in your course.';

  const displaySpinner = computed(() => {
    const editCourseMode = courseDataStore.editCourseMode;
    const fetchState = courseDataStore.store.contentStepDataFetchState;
    return editCourseMode && fetchState === 'loading';
  });

  /**
   * This returns whether to disable Individualized Assigning checkbox.
   * For edit course use case, data call related to this configuration is
   * optimized via separate async call to avoid delay on page load.
   * @return {boolean}
   */
  function disableIndividualizedAssigningCb() {
    if (courseDataStore.editCourseMode) {
      return courseDataStore.store.contentStepDataFetchState !== 'success' ||
        courseDataStore.store.courseHasIndividualAssignments;
    }
    return false;
  }
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .individual-assign-loading {
    align-items: center;
    color: #969696;
    display: inline-flex;
    font-size: rpx(12);
    font-style: italic;
    margin-left: rpx(8);
  }

  .loader-image {
    margin-right: rpx(4);
  }
</style>
