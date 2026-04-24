<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="course-details__step-content">
      <EnterpriseStepHeader headingLevel="0" :isEditable="courseDataStore.editCourseMode" />

      <h1 v-if="courseDataStore.editCourseMode" class="step-title">
        Edit Course
      </h1>
      <h1 v-else class="step-title">
        Create a New Course
      </h1>

      <p class="u-txt-body-1">
        Courses are groups of sections that are the same number of weeks and meet on the
        same days of the week.  Due dates should be the same days of the week.
      </p>

      <EnterpriseSettingsSection class="with-divider">
        <Fieldset class="u-mar-top-32">
          <div class="u-mar-bot-8  u-txt-body-1  u-dis-flex">
            Course names are visible to instructors and students.
            <music-icon-asterisk-v3 class="icon u-fill-util-error c-icon-v3" size="md" />
          </div>
          <form-item>
            <music-text-field-v3>
              <label :class="nameLabelClasses()" for="course_name">
                Course Name
              </label>
              <input
                id="course_name"
                v-model="courseDataStore.store.course.name"
                type="text"
                required
                size="30"
                :class="testClass('course-name-input')"
                :readonly="courseDataStore.courseValidator.isNameReadonly"
                @input="courseDataStore.store.courseNameValidator = true">
            </music-text-field-v3>
          </form-item>
          <FormFeedback
            v-if="courseDataStore.store.courseNameValidator
              && courseDataStore.courseValidator.hasCourseError('name').value"
            :class="testClass('course-name-validation-error')"
            type="error">
            {{ courseDataStore.courseValidator.hasCourseError('name').msg }}
          </FormFeedback>
        </Fieldset>
        <div
          v-if="courseDataStore.newCourseMode ||
            (courseDataStore.editCourseMode && courseDataStore.store.courseOptions.allow_copy)">
          <Fieldset class="u-mar-top-32">
            <div class="u-mar-bot-8  u-txt-body-1">
              Use date settings from another course.
            </div>
            <music-select-field-v3>
              <label for="enterprise_previous_course" class="course_label">
                Course
              </label>
              <select
                id="enterprise_previous_course"
                v-model="courseDataStore.store.settingsCourses.dateSettingsCourse"
                @change="onCourseChange">
                <option
                  v-for="course in prevCourseOptions"
                  :key="course.id"
                  :value="course.value">
                  {{ course.text }}
                </option>
              </select>
            </music-select-field-v3>
          </Fieldset>
        </div>
        <Fieldset class="course-details__date-range  u-mar-top-32  u-mar-bot-12">
          <div class="u-mar-bot-8  u-txt-body-1  u-dis-flex">
            Select the course start and end dates.
            <music-icon-asterisk-v3 class="icon u-fill-util-error c-icon-v3" size="md" />
          </div>
          <div class="course-dates">
            <div class="course-date">
              <VhlDate
                :key="dateKey"
                inputId="start_date"
                testSelector="start-date"
                :modelValue="courseDataStore.store.course.startDate"
                :isDisabled="courseDataStore.store.courseOptions.has_one_roster_academic_session"
                @update:modelValue="courseDataStore.store.course.startDate = $event" />
              <FormFeedback
                v-if="courseDataStore.courseValidator.hasCourseError('date').value"
                type="error"
                :class="testClass('course-date-validation-error')">
                {{ courseDataStore.courseValidator.hasCourseError('date').msg }}
              </FormFeedback>
            </div>
            <div class="course-date">
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
            </div>
          </div>
        </Fieldset>

        <EnterpriseClassDays
          class="u-mar-top-32"
          :disableNextButton="disableNextButton" />

        <Fieldset class="u-mar-top-32">
          <div class="u-mar-bot-8  u-txt-body-1">
            The Course Owner controls all course settings for all sections of
            the course. Individual sections may have different
            co-instructors or assistants.
          </div>
          <music-select-field-v3>
            <label for="course_owner">
              Course Owner
            </label>
            <select
              id="course_owner"
              v-model="courseDataStore.store.course.courseOwnerUserId">
              <option
                v-for="instructor in courseDataStore.store.course.potentialInstructors"
                :key="instructor.id"
                :value="instructor.id">
                {{ instructor.first_name }} {{ instructor.last_name }} ({{ instructor.email }})
              </option>
            </select>
          </music-select-field-v3>
        </Fieldset>

        <Fieldset class="u-mar-top-32  u-mar-bot-32">
          <input
            id="course_display_on_dashboard"
            v-model="courseDataStore.store.course.displayOnDashboard"
            class="c-form-item__checkbox"
            type="checkbox">
          <label
            class="c-form-item__label  u-txt-16  u-txt-gray-3"
            for="course_display_on_dashboard">
            Display this course on my instructor dashboard
          </label>
        </Fieldset>
      </EnterpriseSettingsSection>
    </div>

    <EnterpriseSetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isNextDisabled="isNextButtonDisabled()"
      nextStep="enterprise-content-step" />
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { computed, inject, onMounted, onUnmounted, ref } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import EnterpriseSetupControls from './EnterpriseSetupControls';
  import VhlDate from './VhlDate';
  import { Fieldset, FormFeedback } from 'features/shared/FormElements';
  import EnterpriseSettingsSection from './EnterpriseSettingsSection';
  import EnterpriseStepHeader from './EnterpriseStepHeader';
  import EnterpriseClassDays from './EnterpriseClassDays';

  /**
   * @typedef {
   *  import(
   *    'features/course_wizard/models/new_course_data_store.js'
   *  ).ContentSettingsCourseDataType
   * } ContentSettingsCourseDataType
   */

  const courseDataStore = inject('courseDataStore');
  const dateKey = ref(0);
  const disableNextButton = ref(true);

  /**
   * Computes the list of options for previous courses to populate the dropdown menu.
   * Each option includes the course name, full course object, and associated dates.
   *
   * @returns {Array<Object>} Array of objects with:
   *   - `text`: The course name (string).
   *   - `value`: The full course object.
   *   - `startDate`: The course's start date.
   *   - `endDate`: The course's end date.
   */
  const prevCourseOptions = computed(() => {
    return courseDataStore.store.courseOptions.settings?.map((prevCourse) => ({
      text: prevCourse.name,
      value: prevCourse,
      start_date: prevCourse.start_date,
      end_date: prevCourse.end_date,
    })) ?? [];
  });

  /**
   * Handles the date settings from other courses changes in the course creation wizard
   */
  const onCourseChange = () => {
    const selectedCourse = courseDataStore.store.settingsCourses.dateSettingsCourse;

    setStartEndDate(selectedCourse.value);
  };

  /**
   * Updates the course's start and end dates based on the selected course from the dropdown.
   * This ensures the selected dates are reflected in the form inputs.
   *
   * @param {Object} event - The selected course or template data containing
   * `start_date` and `end_date`.
   */
  const setStartEndDate = (selectedCourse) => {
    if (selectedCourse && selectedCourse.start_date && selectedCourse.end_date) {
      courseDataStore.store.course.startDate = selectedCourse.start_date;
      courseDataStore.store.course.endDate = selectedCourse.end_date;
      dateKey.value++;
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

  function nameLabelClasses() {
    return courseDataStore.editCourseMode ? 'u-screen-reader-only' : ''
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
    selectDefaultAccessLevel();
    nextButtonEnableWithScroll();
    window.addEventListener('scroll', nextButtonEnableWithScroll);
  });

  function selectDefaultAccessLevel() {
    if (
      !courseDataStore.store.course.level &&
      courseDataStore.store.courseOptions.levels.length > 0
    ) {
      courseDataStore.store.course.level = courseDataStore.store.courseOptions.levels[0].id;
    }
  }

  onUnmounted(() => {
    window.removeEventListener('scroll', nextButtonEnableWithScroll);
  });
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;
  @import 'features/shared/form_element_settings';

  .course-details__step-content {
    background-color: var(--music-true-gray-50, #f5f5f5);
    clear: both;
    font-size: 1.3em;
    min-height: music.rpx(480);
    overflow: auto;
    padding: 0.25rem;
    position: relative;
    text-align: left;
    margin-bottom: 3rem;
  }

  [class*="c-select-field__label"] {
    font-size: rpx(16);
    --dropdown-label-minified-top-offset: -0.56rem;
    top: var(--dropdown-label-minified-top-offset);
  }

  .edit-course .course-details__step-content {
    padding: 0.938rem;
  }

  .course-dates {
    display: flex;
    gap: music.mod(2.5);
  }

  .course-date {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap;
    width: music.rpx(200);
  }

  .step-title {
    color: #595959;
    font-size: music.rpx(38);
    font-weight: 300;
    line-height: music.rpx(46);
    margin-top: music.rpx(32); 
    margin-bottom: music.rpx(28); 
  }

  .with-divider {
    border-bottom: music.rpx(1) solid music.$grey-d;
  }
</style>
