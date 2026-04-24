<template>
  <div class="u-mar-bot-24">
    <div class="u-mar-bot-20  u-txt-body-1">
      Select lessons for this course.
    </div>

    <div class="dropdown-group">
      <div class="unit-dropdown">
        <music-select-field-v3>
          <label for="first_unit">
            First Lesson
          </label>
          <select
            id="first_unit"
            v-model.number="courseDataStore.store.course.firstUnitId">
            <option
              v-for="unit in courseDataStore.store.courseOptions.units"
              :key="unit.id"
              :value="unit.id">
              {{ unit.label }}
            </option>
          </select>
        </music-select-field-v3>
      </div>

      <div> - </div>

      <div class="unit-dropdown">
        <music-select-field-v3>
          <label for="last_unit">
            Last Lesson
          </label>
          <select
            id="last_unit"
            v-model.number="courseDataStore.store.course.lastUnitId">
            <option
              v-for="unit in courseDataStore.store.courseOptions.units"
              :key="unit.id"
              :value="unit.id">
              {{ unit.label }}
            </option>
          </select>
        </music-select-field-v3>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;
  @use 'music/app/styles/library/base';
  @import 'features/shared/form_element_settings';

  .dropdown-group {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .unit-dropdown {
    display: flex;
  }

  [class*="c-select-field__label"] {
    font-size: rpx(16);
    --dropdown-label-minified-top-offset: -0.56rem;
    top: var(--dropdown-label-minified-top-offset);
  }

  [class*="c-select-field__input"] {
    font-size: rpx(14);
  }
</style>
