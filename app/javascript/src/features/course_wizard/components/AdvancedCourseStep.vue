<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="course-details__step-content">
      <StepHeader headingLevel="1" />

      <VStack spacing="lg">
        <Fieldset>
          <FormItem
            inputId="course_name"
            label="Course Name">
            <input
              id="course_name"
              v-model="courseDataStore.store.course.name"
              placeholder="New course"
              type="text"
              required
              size="30"
              class="text-input"
              :class="testClass('course-name-input')"
              :readonly="courseDataStore.courseValidator.isNameReadonly"
              @input="courseDataStore.store.courseNameValidator = true">
            <FormFeedback
              v-if="courseDataStore.store.courseNameValidator
                && courseDataStore.courseValidator.hasCourseError('name').value"
              :class="testClass('course-name-validation-error')"
              type="error">
              {{ courseDataStore.courseValidator.hasCourseError('name').msg }}
            </FormFeedback>
          </FormItem>
        </Fieldset>

        <Expander
          :expanded="previewVisibility"
          headerTextOpen="Hide Preview"
          headerTextClosed="Preview as Student"
          variant="end"
          class="c-expander--course-preview"
          :class="testClass('vhl-expander')"
          @click="() => previewVisibility = !previewVisibility">
          <PreviewTable
            courseType="advanced"
            class="u-mar-top-8" />
        </Expander>

        <div
          v-if="courseDataStore.newCourseMode ||
            (courseDataStore.editCourseMode && courseDataStore.store.courseOptions.allow_copy)">
          <Fieldset v-if="config.instAdmin" legend="Use date settings from...">
            <span>
              <input
                id="copy_course"
                v-model="courseDataStore.store.course.dateSettingsCourseSource"
                class="c-form-item__radio"
                type="radio"
                value="course">
              <label
                class="c-form-item__label  c-form-item__label--radio"
                for="copy_course">Course</label>
            </span>
            <span>
              <input
                id="copy_template"
                v-model="courseDataStore.store.course.dateSettingsCourseSource"
                class="c-form-item__radio"
                type="radio"
                value="template">
              <label
                class="c-form-item__label  c-form-item__label--radio"
                for="copy_template">Template</label>
            </span>
          </Fieldset>

          <Fieldset>
            <div v-if="courseDataStore.store.course.dateSettingsCourseSource === 'course'">
              <div class="c-form-item">
                <label v-if="!config.instAdmin" for="previous_course" class="c-form-item__label">
                  Copy date settings from...
                </label>
                <!-- eslint-disable vue/no-v-model-argument -->
                <VhlSelectDataWrapper
                  id="previous_course"
                  v-model="courseDataStore.store.settingsCourses.dateSettingsCourse"
                  :options="prevCourseOptions"
                  @update:modelValue="setStartEndDate($event)" />
                <!-- eslint-enable vue/no-v-model-argument -->
              </div>
            </div>
            <div v-if="courseDataStore.store.course.dateSettingsCourseSource === 'template'">
              <div class="c-form-item">
                <!-- eslint-disable vue/no-v-model-argument -->
                <VhlSelectDataWrapper
                  id="previous_course_template"
                  v-model="courseDataStore.store.settingsCourses.dateSettingsCourse"
                  :options="prevCourseTemplateOptions"
                  @update:modelValue="dateKey = dateKey + 1" />
                <!-- eslint-enable vue/no-v-model-argument -->
              </div>
            </div>
          </Fieldset>
        </div>

        <Fieldset class="course-details__date-range">
          <VStack>
            <FormItem
              inputId="start_date"
              label="Start Date">
              <VhlDate
                :key="dateKey"
                inputId="start_date"
                testSelector="start-date"
                :modelValue="courseDataStore.store.course.startDate"
                :isDisabled="courseDataStore.store.courseOptions.has_one_roster_academic_session"
                @update:modelValue="courseDataStore.store.course.startDate = $event" />
            </FormItem>
            <FormItem
              inputId="end_date"
              label="End Date">
              <VhlDate
                :key="dateKey"
                inputId="end_date"
                testSelector="end-date"
                :modelValue="courseDataStore.store.course.endDate"
                :isDisabled="courseDataStore.store.courseOptions.has_one_roster_academic_session"
                @update:modelValue="courseDataStore.store.course.endDate = $event" />
              <FormFeedback
                v-if="courseDataStore.courseValidator.hasCourseError('endDate').value"
                type="error"
                :class="testClass('course-end-date-validation-error')">
                {{ courseDataStore.courseValidator.hasCourseError('endDate').msg }}
              </FormFeedback>
              <FormFeedback
                v-if="courseDataStore.courseValidator.hasCourseError('date').value"
                type="error"
                :class="testClass('course-date-validation-error')">
                {{ courseDataStore.courseValidator.hasCourseError('date').msg }}
              </FormFeedback>
            </FormItem>
          </VStack>
        </Fieldset>
      </VStack>
    </div>

    <SetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isNextDisabled="isNextButtonDisabled()"
      nextStep="content-step"
      :previousStep="config.isVol ? 'path-selector-step' : ''" />
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { computed, inject, onMounted, onUnmounted, ref } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import PreviewTable from './PreviewTable';
  import SetupControls from './SetupControls';
  import VhlDate from './VhlDate';
  import { Fieldset, FormItem, FormFeedback }
    from 'features/shared/FormElements';
  import VStack from 'features/shared/VStack';
  import VhlSelectDataWrapper from 'features/learning_tracks/components/VhlSelectDataWrapper';
  import StepHeader from './StepHeader';
  import Expander from 'features/shared/expander/Expander';

  /**
   * @typedef {
   *  import(
   *    'features/course_wizard/models/new_course_data_store.js'
   *  ).ContentSettingsCourseDataType
   * } ContentSettingsCourseDataType
   */

  /**
   * @typeDef VhlSelectOptionForPrevCourse
   * @property {string} text
   * @property {ContentSettingsCourseDataType} value
   */
  const config = inject('config');
  const courseDataStore = inject('courseDataStore');
  const dateKey = ref(0);
  const previewVisibility = ref(false);
  const disableNextButton = ref(true);

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
   * This updates the course start/end dates from the previous course dropdown
   * @param {Event} event
   */
  const setStartEndDate = (event) => { // eslint-disable-line no-unused-vars
    dateKey.value = dateKey.value + 1;

    if (event && Object.hasOwn(event, 'start_date')) {
      courseDataStore.store.course.startDate = event.start_date;
      courseDataStore.store.course.endDate = event.end_date;
    }
  };

  /**
   * Sets a variable that indicates that the user scrolled near the
   * bottom of the page.
   * @param {event} event - The scroll event of the window.
   */
  function nextButtonEnableWithScroll(event) {
    if (
      (window.innerHeight + Math.ceil(window.pageYOffset + 120) ) >= document.body.offsetHeight
    ) {
      disableNextButton.value = false;
    }
  }

  /**
   * Should the next button be disabled. Based on the course dates, name value
   * or if the user has scrolled to the end of the page or not.
   * @return {boolean}
   */
  function isNextButtonDisabled() {
    return courseDataStore.courseValidator.isCourseNameOrDatesInvalid() || disableNextButton.value;
  }

  onMounted(() => {
    scrollToTopOfPage();
    nextButtonEnableWithScroll();
    window.addEventListener('scroll', nextButtonEnableWithScroll);
  });

  onUnmounted(() => {
    window.removeEventListener('scroll', nextButtonEnableWithScroll);
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  @import 'features/shared/form_element_settings';

  .c-expander--course-preview {
    width: 75%;
  }

  .course-details__step-content {
    margin-bottom: 14rem;
  }
</style>
