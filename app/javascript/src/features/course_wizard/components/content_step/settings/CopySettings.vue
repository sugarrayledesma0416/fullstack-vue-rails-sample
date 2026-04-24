<template>
  <div>
    <div class="inputs">
      <ContentSetting
        title="Use settings from"
        class="u-mar-rt-24"
        :class="testClass('copy-settings')">

        <div v-if="config.instAdmin">
          <div class="mar-bot-10">
            <!-- eslint-disable vue/no-v-model-argument -->
            <VhlRadioButton
              id="copy_settings_from_course"
              v-model:modelValue="courseDataStore.store.course.contentSettingsCourseSource"
              name="copy_settings_from_course"
              testSelectorInput="settings-from-course-rb"
              text="Course"
              value="course" />
            <VhlRadioButton
              id="copy_settings_from_template"
              v-model:modelValue="courseDataStore.store.course.contentSettingsCourseSource"
              class="mar-lt-12"
              name="copy_settings_from_template"
              testSelectorInput="settings-from-template-rb"
              text="Template"
              value="template" />
            <!-- eslint-enable vue/no-v-model-argument -->
          </div>
        </div>

        <div v-if="courseDataStore.store.course.contentSettingsCourseSource === 'course'">
          <VhlSelectDataWrapper
            id="previous_course_id"
            v-model="courseDataStore.store.settingsCourses.contentSettingsCourse"
            class="content-step-select"
            :class="testClass('settings-from-prev-course-select')"
            :options="prevCourseOptions" />
        </div>

        <div v-else-if="courseDataStore.store.course.contentSettingsCourseSource === 'template'">
          <VhlSelectDataWrapper
            id="previous_course_template_id"
            v-model="courseDataStore.store.settingsCourses.contentSettingsCourse"
            :options="prevCourseTemplateOptions"
            class="content-step-select"
            :class="testClass('settings-from-prev-course-template-select')" />
        </div>
      </ContentSetting>

      <ContentSetting
        v-if="isIdPresentInContentSettingsCourse"
        title="include">
        <div
          v-if="!config.instAdmin && isIdPresentInContentSettingsCourse"
          :class="testClass('content-step-copy-created')">
          <!-- eslint-disable vue/no-v-model-argument -->
          <VhlCheckbox
            id="Copy instructor created activities"
            v-model:checked="courseDataStore.store.course.copyCreatedActivitiesFromPreviousCourse"
            testSelectorInput="copy-instructor-created-activities-checkbox">
            Copy instructor-created activities
          </VhlCheckbox>
          <!-- eslint-enable vue/no-v-model-argument -->
        </div>

        <div v-if="config.instAdmin && isIdPresentInContentSettingsCourse">
          <!-- eslint-disable vue/no-v-model-argument -->
          <VhlCheckbox
            id="Copy instructor created activities"
            v-model:checked="courseDataStore.store.course.copySharedActivitiesFromPreviousCourse"
            testSelectorInput="copy-shared-instructor-created-activities-checkbox">
            Copy shared instructor-created activities
          </VhlCheckbox>
          <!-- eslint-enable vue/no-v-model-argument -->
        </div>
      </ContentSetting>
    </div>
  </div>
</template>

<script setup>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from '../../VhlCheckbox';
  import VhlRadioButton from '../../VhlRadioButton';
  import VhlSelectDataWrapper from '../../VhlSelectDataWrapper';

  const config = inject('config');
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

  /**
   * This gets options for Previous Course Templates dropdown in the required format
   * @return {Array.<VhlSelectOptionForPrevCourse>}
   */
  const prevCourseTemplateOptions = computed(() => {
    const courseOpts = courseDataStore.store.courseOptions.template_settings?.map(
      (prevCourseTemplate, index) => ({
        text: prevCourseTemplate.name,
        value: prevCourseTemplate,
      })
    ) ?? [];
    return [{ text: '', value: undefined }].concat(courseOpts);
  });

  /**
   * This returns whether contentSettingsCourse has id
   * @return {boolean}
   */
  const isIdPresentInContentSettingsCourse = computed(() => {
    return courseDataStore.store.settingsCourses.contentSettingsCourse?.id;
  });
</script>

<style lang="scss" scoped>
  .inputs {
    display: flex;
    flex-wrap: wrap;
  }
</style>
