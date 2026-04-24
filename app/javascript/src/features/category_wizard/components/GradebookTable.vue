<template>
  <div class="gradebook-table" :class="{'vol': config.isVol}">
    <div class="gradebook-table-students">
      <div class="student-names-column" :class="testClass('student-names-column')">
        <div class="student-name-controls">
          <div class="student-name-changes" />
          <div class="student-name-order" />
        </div>
        <div class="student-name-header">
          <span class="name">Students</span>
        </div>
        <div>
          <div
            v-for="studentNumber in [1, 2, 3, 4]"
            :key="studentNumber"
            class="student-name"
            :class="testClass('student-name')">
            Example Student {{ studentNumber }}
          </div>
        </div>
      </div>
    </div>
    <div class="gradebook-table-grades">
      <div
        :style="gradebookTableStyle"
        class="grades-scroll-container dynamic-gradebook-table-style">
        <div>
          <div
            v-for="(category, categoryIndex) in nonDestroyedCategories"
            :id="`course_category_fields_row_${categoryIndex}`"
            :key="category.id"
            class="grades-column"
            :class="testClass('grades-column')">
            <div class="category-controls">
              <GearMenu
                :menuItems="gearMenuItems"
                linkText="Edit"
                @click="onGearMenuClick($event, category)" />
              <div class="category-order">
                <a
                  class="rank-up-category"
                  :class="testClass('rank-up-category')"
                  @click="moveLeft(categoryIndex)">
                  UP
                </a>
                <a
                  class="rank-down-category"
                  :class="testClass('rank-down-category')"
                  @click="moveRight(categoryIndex)">
                  DN
                </a>
              </div>
            </div>
            <div class="category-name" :class="testClass('category-name')">
              <div class="name">
                <a
                  class="category-name-link"
                  href="javascript://"
                  :class="testClass('category-name-link')"
                  @click="editCategory(category)">
                  {{ category.name.substring(0, 20) }}
                </a>
              </div>
              <div>
                <input
                  v-model.number="category.weightingPercent"
                  type="number"
                  name="weighting_percent"
                  min="0"
                  max="100"
                  class="weighting-percent-input"
                  :class="testClass('weighting-percent-input')">%
              </div>
            </div>
            <div>
              <div
                v-for="(grade, gradeIndex) in grades[categoryIndex]"
                :key="gradeIndex"
                class="sample-grades"
                :class="testClass('sample-grades')">
                {{ grade }}
              </div>
            </div>
          </div>
        </div>
        <div
          v-show="courseDataStore.store.course.categories.length === 0"
          class="no-categories-message"
          :class="testClass('no-categories-message')">
          [ No gradebook categories yet ]
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';
  import GearMenu from './GearMenu';

  /**
   * @typedef {import('features/course_wizard/components/GearMenu.vue').GearMenuItem} GearMenuItem
   */

  const CATEGORY_WIDTH = 128;
  const gearMenuItems= [
    { text: 'Edit Category', id: 'edit-category' },
    { text: 'Delete Category', id: 'delete-category' },
  ];

  export default {
    name: 'GradebookTable',
    components: { GearMenu },
    emits: ['openEditCategory'],
    setup(props, { emit }) {
      const courseDataStore = inject('courseDataStore');
      const config = inject('config');

      const ASSIGNED_CATEGORY_DELETE_MSG = 'You cannot delete this category ' +
        'because it contains assignments';
      const DELETE_MSG = 'You are about delete this category. Are you Sure?';

      /**
       * computed array to get grades string for each category column
       * @return {Array.<Array.<string>>}
       */
      const grades = computed(()=> {
        return courseDataStore.store.course.categories?.map(
          (category) => ['A', 'B', 'C', 'D']);
      });

      /**
       * computed filtered array to get categories for which '_destroy' is not set true
       * @return {Array.<Category>}
       */
      const nonDestroyedCategories = computed(()=> {
        return courseDataStore.store.course.categories.filter(
          (category) => !category._destroy
        );
      });

      /**
       * This function swaps item at given indexs in an array
       * @param {Array.<Category>} arr
       * @param {number} i - index of the item to be swapped
       * @param {number} j - index of the item to be swapped
       */
      function swap(arr, i, j) {
        const temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }

      /**
       * This function emits 'openEditCategory' event with category information
       * @param {Category} category
       */
      function editCategory(category) {
        emit('openEditCategory', category);
      }

      /**
       * This function shows alert if category has assignments.
       * Else shows a confirmation alert before removing category.
       * @param {Category} category
       */
      function removeCategory(category) {
        if (category.hasAssignments) {
          window.alert(ASSIGNED_CATEGORY_DELETE_MSG);
        } else if (window.confirm(DELETE_MSG)) {
          courseDataStore.store.course.removeCategory(category);
        }
      }

      /**
       * This function moves a category to the left in the category array in the store
       * @param {number} categoryIndex - index of the category
       */
      function moveLeft(categoryIndex) {
        if (categoryIndex > 0) {
          swap(courseDataStore.store.course.categories, categoryIndex, categoryIndex - 1);
          courseDataStore.store.course.updateRank();
        }
      }

      /**
       * This function moves a category to the right in the category array in the store
       * @param {number} categoryIndex - index of the category
       */
      function moveRight(categoryIndex) {
        if (categoryIndex < (courseDataStore.store.course.categories.length - 1)) {
          swap(courseDataStore.store.course.categories, categoryIndex, categoryIndex + 1);
          courseDataStore.store.course.updateRank();
        }
      }

      /**
       * This method handles Gear Menu actions and update category in the store
       * @param {GearMenuItem} menuItem - information object about gear menu item
       * @param {Category} category
       */
      function onGearMenuClick(menuItem, category) {
        if (menuItem.id === 'edit-category') {
          editCategory(category);
        } else if (menuItem.id === 'delete-category') {
          removeCategory(category);
        }
      }

      /**
       * This returns style object with '--width-from-js' property
       * to set width of the table based on categories count
       * This will be used to update value of css variable '--width-from-js'
       * @return {Object.<string, string>}
       */
      const gradebookTableStyle = computed(() => {
        const width = courseDataStore.store.course.categories.length * CATEGORY_WIDTH;
        return {
          '--width-from-js': `${width}px`,
        };
      });

      return {
        config,
        courseDataStore,
        editCategory,
        gearMenuItems,
        gradebookTableStyle,
        grades,
        moveLeft,
        moveRight,
        nonDestroyedCategories,
        onGearMenuClick,
        removeCategory,
        testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  // This markup chunk depends on the default setting for box-sizing.
  // Fixes several spacing/layout issues caused by music v1 box-sizing setting.
  .gradebook-category-summary,
  .gradebook-category-summary * {
    box-sizing: content-box
  }

  .dynamic-gradebook-table-style {
    width: var(--width-from-js);
  }
  .mar-bot-20 {
    margin-bottom: rpx(20);
  }
  .gradebook-table-students {
    background: url('/images/category_object_bg.png') 0 0 repeat-x;
    display: inline-block;
    float: left;
    height: rpx(226);
    position: relative;
    width: rpx(125);
  }
  .vol.gradebook-table-students {
    background: url('/images/category_object_bg_vol.png') 0 0 repeat-x;
  }
  .student-names-column {
    background: url('/images/category_object_bg.png') 0 0 repeat-x;
    display: inline-block;
    font-size: rpx(12);
    position: relative;
    width: rpx(125);
  }
  .vol .student-names-column {
    background: url('/images/category_object_bg_vol.png') 0 0 repeat-x;
  }
  .student-name-controls,
  .category-controls {
    border-right: rpx(1) solid #BAC2C7;
    height: rpx(21);
    padding-left: rpx(5);
    padding-right: rpx(5);
    padding-top: rpx(5);
  }
  .student-name-changes,
  .category-changes {
    display: inline-block;
    float: left;
    position: relative;
  }
  .student-name-order,
  .category-order {
    display: inline-block;
    float: right;
  }
  .name {
    color: #fff;
    display: block;
    font-weight: bold;
  }
  .student-names-column .name {
    padding-left: rpx(17);
    text-align: left;
  }
  .grades-column .name {
    padding-bottom: rpx(3);
    padding-top: rpx(7);
  }
  .student-name-header,
  .category-name {
    border-right: rpx(1) solid #6F0506;
    color: #fff;
    font-size: rpx(11);
    line-height: rpx(13);
    text-align: center;
  }
  .student-name-header {
    height: rpx(32);
    font-weight: bold;
    margin-bottom: rpx(4);
    padding-bottom: rpx(2);
    padding-top: rpx(10);
  }
  .category-name {
    height: rpx(43);
    margin-bottom: rpx(3);
    padding-top: rpx(2);
  }
  .student-name,
  .sample-grades {
    border-right: rpx(1) solid #fff;
    color: #7C7C7C;
    font-size: rpx(11);
    height: rpx(28);
    line-height: rpx(13);
    padding-top: rpx(10);
    text-align: center;
  }
  .gradebook-table-grades {
    background: url('/images/category_object_bg.png') 0 0 repeat-x;
    display: inline-block;
    height: rpx(241);
    overflow-x: auto;
    overflow-y: hidden;
    position: relative;
    width: rpx(640);
  }
  .vol .gradebook-table-grades {
    background: url('/images/category_object_bg_vol.png') 0 0 repeat-x;
  }
  .grades-scroll-container {
    font-size: 0;
    height: rpx(241);
    min-width: rpx(640);
    overflow-x: auto;
    overflow-y: hidden;
    position: relative;
    white-space: nowrap;
  }
  .grades-column {
    background: url('/images/category_object_bg.png') 0 0 repeat-x;
    display: inline-block;
    float: left;
    font-size: rpx(12);
    position: relative;
    width: rpx(128);
  }
  .vol .grades-column {
    background: url('/images/category_object_bg_vol.png') 0 0 repeat-x;
  }
  .rank-up-category,
  .rank-down-category {
    background: url('/images/bkgd-scoreArrows.gif') transparent top right no-repeat;
    border: 0;
    cursor: pointer;
    display: inline-block;
    height: rpx(17);
    outline:0;
    text-indent: -222em;
    width: rpx(17);
  }
  .rank-up-category {
    background: transparent url('/images/course_wizard/category_arrows.png')
      rpx(2) rpx(3) no-repeat;
    float: left;
    height: rpx(18);
    width: rpx(12);

    &:hover {
      background-position: rpx(2) rpx(-15);
    }
  }
  .rank-down-category {
    background-position: top left;
  }
  .rank-down-category {
    background: transparent url('/images/course_wizard/category_arrows.png')
      rpx(-12) rpx(3) no-repeat;
    height: rpx(18);
    width: rpx(12);

    &:hover {
      background-position: rpx(-12) rpx(-15);
    }
  }
  .category-name-link {
    color: #fff;
  }
  .weighting-percent-input {
    background: transparent;
    border: 0;
    border-radius: 0;
    box-shadow: none;
    color: #fff;
    margin: 0 rpx(2) 0 0;
    padding: 0 rpx(1) 0 0;
    text-align: right;
    width: rpx(22);
  }
  /* Remove spin buttons for Chrome, Safari, Edge, Opera */
  .weighting-percent-input::-webkit-outer-spin-button,
  .weighting-percent-input::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }
  /* Remove spin buttons for Firefox */
  .weighting-percent-input {
    -moz-appearance: textfield;
  }
  .no-categories-message {
    color: #fff;
    font-size: rpx(14);
    font-weight: normal;
    height: rpx(30);
    line-height: rpx(16);
    padding-top: rpx(40);
    position: relative;
    text-align: center;
  }
</style>
