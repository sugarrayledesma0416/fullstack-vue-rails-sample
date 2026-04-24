<template>
  <div class="c-box  c-box--outlined">
    <p class="u-txt-gray-6  preview-table__caption" :class="testClass('preview-table-caption')">
      When your students enroll, they will see this:
    </p>
    <table class="c-table">
      <thead>
        <tr class="c-header-row" :class="{ 'is-vol': config.isVol }">
          <th class="u-txt-bold" scope="col" :class="testClass('instructor-heading')">
            Instructor
          </th>
          <th class="u-txt-bold" scope="col" :class="testClass('course-heading')">
            Course
          </th>
          <th class="u-txt-bold" scope="col" :class="testClass('section-heading')">
            Section
          </th>
          <th class="u-txt-bold" scope="col">
            More Info
          </th>
        </tr>
      </thead>
      <template v-if="!courseDataStore.store.course.id && courseType === 'express'">
        <tbody>
          <tr
            v-for="sect in courseDataStore.store.course.sections"
            :key="sect"
            class="c-row"
            :class="testClass('current-section')">
            <td class="test-current-user" :class="testClass('section-row-preview-instructor')">
              {{ config.currentUser.last_name }}
            </td>
            <td :class="testClass('preview-table-course-name')">
              {{ courseDataStore.store.course.name }}
            </td>
            <td :class="testClass('preview-table-section-name')">
              {{ sect.name }}
            </td>
            <td :class="testClass('section-row-preview-more-info')">
              {{ sect.additionalInfo }}
            </td>
          </tr>
        </tbody>
      </template>
      <template v-if="!courseDataStore.store.course.id && courseType === 'advanced'">
        <tr
          class="c-row"
          :class="testClass('current-section')">
          <td
            :class="`${testClass('current-user')}`">
            <div class="c-form-item  c-form-item--radio  u-mar-0" inert>
              <input class="c-form-item__radio" type="radio">
              <label class="c-form-item__label" :class="testClass('preview-table-instructor-name')">
                {{ config.currentUser.last_name }}
              </label>
            </div>
          </td>
          <td :class="testClass('preview-table-course-name')">
            {{ courseDataStore.store.course.name }}
          </td>
          <td :class="testClass('preview-table-section-name')">
            Section...
          </td>
          <td :class="testClass('section-row-preview-more-info')" />
        </tr>
      </template>
      <template v-if="courseDataStore.store.courseOptions">
        <tbody
          v-for="previousCourse in courseDataStore.store.courseOptions.settings"
          :key="previousCourse"
          :class="testClass('previous-courses')">
          <tr
            v-for="(section) in previousCourse.sections"
            :key="section"
            class="c-row"
            :class="testClass('previous-sections')">
            <td :class="previewTableInstructorClasses()">
              {{ config.currentUser.last_name }}
            </td>
            <td :class="testClass('preview-table-course-name')">
              {{ previousCourse.name }}
            </td>
            <td :class="testClass('preview-table-section-name')">
              {{ section.name }}
            </td>
            <td :class="testClass('section-row-preview-more-info')">
              {{ section.additionalInfo }}
            </td>
          </tr>
        </tbody>
      </template>
    </table>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { inject, onMounted, ref } from 'vue';
  import IconInfo from './IconInfo';
  import tippy from 'tippy.js';

  export default {
    name: 'PreviewTable',
    components: { IconInfo },
    props: {
      courseType: { required: true, type: String },
    },
    setup() {
      const tooltipIcons = ref([]);
      const tooltips = ref([]);
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');

      /**
       * @param {Array<string>} lastNames
       * returns formatted string of last names.
       * @return {string}
       */
      const formatLastNames = function(lastNames) {
        return lastNames.join(', ');
      };

      /**
       * @param {number} sectionInstructorsLength
       * formats the string of instructor labels
       * @return {string}
       */
      const formatInstructorLabel = function(sectionInstructorsLength) {
        return sectionInstructorsLength > 1 ? 'Instructors' : 'Instructor';
      };

      const previewTableInstructorClasses = function() {
        return testClass('preview-table-instructor-name') +
          '  ' +
          testClass('current-user');
      };

      onMounted(() => {
        for (const index in tooltipIcons.value) {
          if (Object.prototype.hasOwnProperty.call(tooltipIcons.value, index)) {
            tippy(
              tooltipIcons.value[index],
              {
                allowHTML: true,
                content: tooltips.value[index].outerHTML,
              }
            );
          }
        }
      });

      return {
        config,
        courseDataStore,
        formatInstructorLabel,
        formatLastNames,
        previewTableInstructorClasses,
        testClass,
        tooltips,
        tooltipIcons,
      };
    },
  };
</script>

<style lang="css">
  @import 'tippy.js/dist/tippy';
</style>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .preview-table__wrap {
    width: 100%;
    overflow: auto;
  }

  .preview-table {
    --cell-padding: #{mod(0.3) mod(0.3) mod(0.3) mod(0.5)};
    --table-border: #{rpx(1) solid $gray-c};

    background-color: $white;
    border: var(--table-border);
    font-size: var(--font-2, $font-size-14);
    margin-bottom: 0;
    table-layout: fixed;
    width: auto;
  }

  .preview-table__caption {
    color: $gray-6;
  }

  .preview-table__instructor {
    position: relative;
  }

  .preview-table__instructor-label {
    display: inline;
    font-weight: normal;
    margin-left: rpx(4);
  }

  .preview-table__label {
    margin: 0;
    padding: 0;
  }

  .preview-table__moreinfo {
    float: right;
  }

  .preview-table__popup-inner {
    border: 0;
    padding: 0.313rem;
  }

  .preview-table__popup-label {
    font-weight: bold;
    line-height: 1.8em;
  }

  .preview-table__section {
    background-color: $selected;
    border-top: 0;
  }

  .preview-table__th {
    background-color: $gray-f5;
    color: $black;
    text-transform: uppercase;
    font-weight: bold;
    padding: var(--cell-padding);
  }

  .preview-table__wrap-course {
    border-left: rpx(1) solid $gray-c;
    border-right: rpx(1) solid $gray-c;
    word-wrap: break-word;
  }

  .preview-table__wrap-td {
    padding: var(--cell-padding);
  }
</style>
