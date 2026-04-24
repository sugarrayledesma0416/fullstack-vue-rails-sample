<template>
  <ContentSetting title="Levels" :class="testClass('levels')">
    <p>
      Select the level of access you expect your students to have for this course.
    </p>
    <div class="options">
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        v-for="level in courseDataStore.store.courseOptions.levels"
        :id="`access_level_${level.name}`"
        :key="level.name"
        v-model:modelValue="courseDataStore.store.course.level"
        name="level"
        testSelectorInput="access-level-rb"
        :text="level.name"
        :value="level.id"
        @update:modelValue="maybeWarnAccessChange()" />
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlRadioButton from '../../VhlRadioButton';

  const courseDataStore = inject('courseDataStore');

  /**
   * This method shows warning for access change
   */
  function maybeWarnAccessChange() {
    if (!courseDataStore.newCourseMode) {
      window.alert(
        'This new access level may prevent students from ' +
          'completing work you have already assigned.'
      );
    }
  }
</script>
