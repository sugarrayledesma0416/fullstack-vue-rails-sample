<template>
  <ContentSetting
    :class="testClass('standards')">
    <p>
      Select the standards you would like to include in your course.
    </p>
    <div v-for="standard_set_group in availableStandardSetGroups()">
      <VhlCheckbox
      :id="`standard_set_${standard_set_group.ids.join('_')}`"
      :checked="courseDataStore.store.course.isStandardSetGroupSelected(standard_set_group)"
      @update:checked="check(standard_set_group.ids, $event)"
      >
      {{ standard_set_group.name }}
      </VhlCheckbox>
    </div>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import ContentSetting from '../ContentSetting';

  const courseDataStore = inject('courseDataStore');
  const check = (ids, checked) => {
    let updatedValue = [...courseDataStore.store.course.standardSetIds];
    if (checked) {
      ids.forEach(id => updatedValue.push(id));
    } else {
      updatedValue = updatedValue.filter(id => {
        return !ids.includes(id);
      });
    }
    courseDataStore.store.course.standardSetIds = updatedValue;
  };

  /**
   * Returns the available standard set groups sorted alphabetically.
   */
  const availableStandardSetGroups = () => {
    return courseDataStore.store.courseOptions.supported_standard_sets.sort(
      (left, right) => left.name.localeCompare(right.name)
    );
  };
</script>
