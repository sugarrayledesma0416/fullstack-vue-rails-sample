<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="gradebook-step">
      <EnterpriseStepHeader headingLevel="2" :isEditable="courseDataStore.editCourseMode" />

      <h1 class="step-title">
        Gradebook Settings
      </h1>

      <VStack spacing="lg" class="u-mar-bot-20">
        <div class="u-mar-bot-8  u-txt-body-1">
          Here you will create categories and customize the layout and
          settings of your course gradebook.
          <!-- eslint-disable vue/no-v-html -->
          <span v-html="config.gradebookCategories" />
          <!-- eslint-enable vue/no-v-html -->
        </div>

        <div
          v-if="courseDataStore.newCourseMode ||
            (courseDataStore.editCourseMode && courseDataStore.store.courseOptions.allow_copy)">
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
                v-model="courseDataStore.store.settingsCourses.categorySettingsCourse">
                <option
                  v-for="(course, index) in prevCourseOptions"
                  :key="index"
                  :value="course.value">
                  {{ course.text }}
                </option>
              </select>
            </music-select-field-v3>
          </div>
        </div>

        <div>
          <div key="1" class="gradebook-step__tutorial-link">
            <Expander
              key="2"
              class="u-mar-bot-32"
              headerTextOpen="Hide Tutorial"
              headerTextClosed="View Tutorial"
              :class="testClass('tutorial-disclosure')"
              :headerClass="testClass('tutorial-disclosure-text')"
              :expanded="tutorial.store.active"
              @expanderClick="tutorial.toggleTutorial()">
              <Tutorial />
            </Expander>
            <div key="3">
              <GradebookTableContainer
                @openAddCategory="localStore.showAddCategory = true"
                @openEditCategory="openEditCategory($event)" />
              <AddCategory
                v-if="localStore.showAddCategory"
                @closeAdd="localStore.showAddCategory = false" />
              <EditCategory
                v-if="localStore.showEditCategory"
                :categoryIndex="localStore.editCategoryIndex"
                @closeEdit="closeEditCategory" />
            </div>
          </div>
        </div>

        <div v-if="courseDataStore.store.course.categorySettingsCourseSource === 'template'">
          <!-- eslint-disable vue/no-v-model-argument -->
          <VhlSelectDataWrapper
            id="previous_course_template_id"
            v-model="courseDataStore.store.settingsCourses.categorySettingsCourse"
            :options="prevCourseTemplateOptions" />
          <!-- eslint-enable vue/no-v-model-argument -->
        </div>
      </VStack>
    </div>

    <EnterpriseSetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isNextDisabled="isNextButtonDisabled()"
      nextStep="enterprise-summary-step"
      previousStep="enterprise-content-step" />
  </div>
</template>

<script>
  import { testClass } from 'music';
  import {
    computed,
    inject,
    onMounted,
    onUnmounted,
    provide,
    reactive,
    ref,
    toRef,
    watch,
  } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import AddCategory from 'features/category_wizard/components/add_category/AddCategory';
  import EditCategory from 'features/category_wizard/components/EditCategory';
  import Expander from 'features/shared/expander/Expander';
  import GradebookTableContainer from 'features/category_wizard/components/GradebookTableContainer';
  import Tutorial from 'features/category_wizard/components/Tutorial';
  import TutorialStore from 'features/category_wizard/models/tutorial_store';
  import VhlSelectDataWrapper from './VhlSelectDataWrapper';
  import EnterpriseSetupControls from './EnterpriseSetupControls';
  import EnterpriseStepHeader from './EnterpriseStepHeader';
  import VStack from 'features/shared/VStack';

  /**
   * @typedef {
   *  import(
   *    'features/course_wizard/components/AdvancedCourseStep.vue'
   *  ).VhlSelectOptionForPrevCourse
   * } VhlSelectOptionForPrevCourse
   */

  /**
   * @typedef {
   *  import('features/course_wizard/services/course_serializer.js').CategoryObject
   * } CategoryObject
   */

  export default {
    name: 'GradebookStep',
    components: {
      AddCategory,
      EditCategory,
      GradebookTableContainer,
      EnterpriseSetupControls,
      EnterpriseStepHeader,
      Tutorial,
      VhlSelectDataWrapper,
      Expander,
      VStack,
    },
    setup() {
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');
      const localStore = reactive({
        editCategoryIndex: -1,
        showAddCategory: false,
        showEditCategory: false,
      });
      const tutorial = new TutorialStore();
      const disableNextButton = ref(true);
      provide('tutorial', tutorial);

      const categoriesRef = toRef(courseDataStore.store.course, 'categories');
      watch(categoriesRef, () => {
        if (courseDataStore.store.course.categories.length > 0) {
          tutorial.closeTutorial();
        } else {
          tutorial.viewTutorial();
        }
      });

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
       * This method returns combined weight for all the categories
       * @return {number}
       */
      function totalWeight() {
        return courseDataStore.store.course.categories.reduce(function(memo, category) {
          // Undefined weights are zeroes instead.
          return memo + (category.weightingPercent || 0);
        }, 0);
      }

      /**
       * opens the edit category modal.
       * @param {CategoryObject} categoryObj - category object
       */
      function openEditCategory(categoryObj) {
        localStore.editCategoryIndex = courseDataStore.store.course.categories.findIndex(
          (category) => !category._destory && category.name === categoryObj.name
        );
        localStore.showEditCategory = true;
      }

      /**
       * closes the edit category modal.
       */
      function closeEditCategory() {
        localStore.editCategoryIndex = -1;
        localStore.showEditCategory = false;
      }

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
       * Should the next button be disabled. Based on the category weight sum
       * or if the user has scrolled to the end of the page or not.
       * @return {boolean}
       */
      function isNextButtonDisabled() {
        return !(totalWeight() === 100) || disableNextButton.value;
      }

      onMounted(() => {
        scrollToTopOfPage();
        setDefaultSettings();
        nextButtonEnableWithScroll();
        window.addEventListener('scroll', nextButtonEnableWithScroll);
      });

      // Set the Default option (index  1) as the default if exists
      function setDefaultSettings() {
        if (
          !courseDataStore.store.settingsCourses.categorySettingsCourse &&
          prevCourseOptions.value[1]
        ) {
          courseDataStore.store.settingsCourses.categorySettingsCourse = prevCourseOptions.value[1].value;
        }
      }

      onUnmounted(() => {
        window.removeEventListener('scroll', nextButtonEnableWithScroll);
      });

      return {
        closeEditCategory,
        config,
        courseDataStore,
        isNextButtonDisabled,
        localStore,
        openEditCategory,
        prevCourseOptions,
        testClass,
        tutorial,
        Expander,
        VStack,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;
  @import '~MusicAssets/stylesheets/music/library/v1/parts/utilities';
  @import 'features/shared/form_element_settings';

  .expander {
    --expander-header-fill-color: #{$white};
    --expander-body-fill-color: #{$gray-e};
  }

  .fade-enter-active,
  .fade-leave-active {
    transition: opacity 0.5s ease;
  }

  [class*="c-select-field__label"] {
    --dropdown-label-minified-top-offset: -0.56rem;
    top: var(--dropdown-label-minified-top-offset);
  }

  .fade-enter-from,
  .fade-leave-to {
    opacity: 0;
  }

  .gradebook-step {
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

  .step-title {
    color: #595959;
    font-size: music.rpx(38);
    font-weight: 300;
    line-height: music.rpx(46);
    margin-top: music.rpx(32); 
    margin-bottom: music.rpx(28);
  }

  .edit-course .gradebook-step {
    padding: 0.938rem;
  }

  .u-mar-lt-12 {
    margin-left: 0.75rem;
  }
</style>
