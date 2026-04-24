<template>
  <ContentSetting title="Components" :class="testClass('components')">
    <div
      v-for="component in courseDataStore.store.courseOptions.components"
      :key="component.name"
      class="mar-bot-10">
      <VhlCheckbox
        :id="`component_${component.name}`"
        :checked="isComponentSelected(component)"
        name="component"
        testSelectorInput="component-checkbox"
        @update:checked="toggleComponent(component);">
        {{ component.name }}
      </VhlCheckbox>
    </div>
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from '../../VhlCheckbox';

  const courseDataStore = inject('courseDataStore');

  /**
   * This method returns whether a component is selected based on course data
   * @param {ComponentInResponseDataType} component
   * @return {boolean}
   */
  function isComponentSelected(component) {
    return courseDataStore.store.course.components.indexOf(component.id) > -1;
  }

  /**
   * This method updates components in the course data
   * and shows warning for access change
   * @param {ComponentInResponseDataType} component
   */
  function toggleComponent(component) {
    const index = courseDataStore.store.course.components.indexOf(component.id);
    if (index > -1) {
      courseDataStore.store.course.components.splice(index, 1);
    } else {
      courseDataStore.store.course.components.push(component.id);
    }
    maybeWarnAccessChange();
  }

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
