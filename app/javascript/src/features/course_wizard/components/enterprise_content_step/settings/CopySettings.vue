<template>
  <div>
    <div class="u-mar-bot-8  u-txt-body-1">
      Copy settings from a previous course.
    </div>

    <div class="l-simple-grid-v3  l-simple-grid-v3--1-1  u-mar-top-32  u-mar-bot-16">
      <music-select-field-v3>
        <label for="previous_course_id">
          Course
        </label>
        <select
          id="previous_course_id"
          v-model="courseDataStore.store.settingsCourses.contentSettingsCourse">
          <option
            v-for="(course, index) in prevCourseOptions"
            :key="index"
            :value="course.value">
            {{ course.text }}
          </option>
        </select>
      </music-select-field-v3>
    </div>

    <div v-if="isIdPresentInContentSettingsCourse && courseDataStore.newCourseMode">
      <input
        id="copy_igc_activities"
        v-model="courseDataStore.store.course.copySharedActivitiesFromPreviousCourse"
        class="c-form-item__checkbox"
        type="checkbox">
      <label
        class="c-form-item__label  u-txt-16  u-txt-gray-3"
        for="copy_igc_activities">
        Copy shared instructor-created activities
      </label>
    </div>
  </div>
</template>

<script setup>
  import { computed, inject, onMounted } from 'vue';

  const courseDataStore = inject('courseDataStore');

  /**
   * This gets options for Previous Courses dropdown in the required format
   * @return {Array.<VhlSelectOptionForPrevCourse>}
   */
  const prevCourseOptions = computed(() => {
    const courseOpts = courseDataStore.store.courseOptions.settings?.map(
      (prevCourse, index) => ({
        text: prevCourse.name,
        value: prevCourse,
      })
    ) ?? [];
    return [{ text: '', value: undefined }].concat(courseOpts);
  });

  // Set the Default option (index  1) as the default if exists
  onMounted(() => {
    if (!courseDataStore.store.settingsCourses.contentSettingsCourse &&
      prevCourseOptions.value[1]
    ) {
      courseDataStore.store.settingsCourses.contentSettingsCourse = prevCourseOptions.value[1].value;
    }
  })

  /**
   * This returns whether contentSettingsCourse has id
   * @return {boolean}
   */
  const isIdPresentInContentSettingsCourse = computed(() => {
    return courseDataStore.store.settingsCourses.contentSettingsCourse?.id;
  });
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;
  @import 'features/shared/form_element_settings';

  .inputs {
    display: flex;
    flex-wrap: wrap;
  }

  [class*="c-select-field__label"] {
    font-size: rpx(16);
    --dropdown-label-minified-top-offset: -0.56rem;
    top: var(--dropdown-label-minified-top-offset);
  }
</style>
