<template>
  <ContentSetting title="Components" :class="testClass('components')">
    <p>
      Select the components your students must have for this course.
    </p>
    <div
      v-for="component in allowedComponents"
      :key="component.name"
      class="mar-bot-10">
      <VhlCheckbox
        v-if="!isPortfolio(component)"
        :id="`component_${component.name}`"
        :checked="isComponentSelected(component)"
        name="component"
        testSelectorInput="component-checkbox"
        @update:checked="toggleComponent(component);">
        <span class="u-txt-bold">{{ component.name }}</span>
      </VhlCheckbox>
      <Portfolio
        v-else-if="isPortfolio(component)"
        :class="testClass('portfolio-comp')" 
        :component="component"
        :is_enterprise="false"/>
    </div>
  </ContentSetting>
</template>

<script setup>
  import { inject, computed } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from '../../VhlCheckbox';
  import Portfolio from '../settings/Portfolio';

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

  function isPortfolio(component) {
    return component.license_groups.some(
      (licenseGroup) => licenseGroup.name == 'Portfolio'
    );
  }

  const allowedComponents = computed(() => {
    if (courseDataStore.store.course.canShareToPortfolio) {
      return courseDataStore.store.courseOptions.components;
    } else {
      return courseDataStore.store.courseOptions.components.filter(
        (component) => !component.license_groups.some(
          (licenseGroup) => licenseGroup.name === 'Portfolio'
        )
      );
    }
  });
</script>
