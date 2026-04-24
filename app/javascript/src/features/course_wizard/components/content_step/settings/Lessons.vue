<template>
  <ContentSetting title="Lessons" :class="testClass('lessons')">
    <BasicSelect
      v-model.number="courseDataStore.store.course.firstUnitId"
      :options="firstUnitOptions"
      :class="testClass('first-unit-select')" />&mdash;
    <BasicSelect
      v-model.number="courseDataStore.store.course.lastUnitId"
      :options="lastUnitOptions"
      :class="testClass('last-unit-select')" />
  </ContentSetting>
</template>

<script setup>
  import { testClass } from 'music';
  import { computed, inject } from 'vue';
  import ContentSetting from '../ContentSetting';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';

  const courseDataStore = inject('courseDataStore');

  /**
   * This gets options for First Unit dropdown in the required format
   * @return {Array.<VhlSelectOptionType>}
   */
  const firstUnitOptions = computed(() => {
    return courseDataStore.store.courseOptions.units?.map(
      (unit, index) => ({ text: unit.label, value: unit.id })
    );
  });

  /**
   * This gets options for Last Unit dropdown in the required format
   * @return {Array.<VhlSelectOptionType>}
   */
  const lastUnitOptions = computed(() => {
    return courseDataStore.store.unitOptions?.map(
      (unit, index) => ({ text: unit.label, value: unit.id })
    );
  });
</script>
