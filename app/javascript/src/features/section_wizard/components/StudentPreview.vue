<template>
  <div class="c-box  c-box--outlined" :class="testClass('section-preview')">
    <p class="u-txt-gray-6" :class="testClass('preview-table-caption')">
      When your students enroll, they will see this:
    </p>
    <table class="c-table">
      <thead>
        <tr class="c-header-row">
          <th class="u-txt-bold" scope="col">
            Instructor
          </th>
          <th class="u-txt-bold" scope="col">
            Course
          </th>
          <th class="u-txt-bold" scope="col">
            Section
          </th>
          <th class="u-txt-bold" scope="col">
            More Info
          </th>
        </tr>
      </thead>
      <tbody>
        <tr class="c-row" :class="testClass('section-row-preview')">
          <td :class="testClass('section-row-preview-instructor')">
            {{ instructorLastNames() }}
          </td>
          <td :class="testClass('section-row-preview-course')">
            {{ datastore.section.course.name }}
          </td>
          <td :class="testClass('section-row-preview-section')">
            {{ datastore.section.name }}
          </td>
          <td :class="testClass('section-row-preview-more-info')">
            {{ datastore.section.additionalInfo }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'StudentPreview',
    setup(props) {
      const datastore = inject('datastore');

      /**
       * This method returns instructor last names string by joining array elements
       * @return {string}
       */
      function instructorLastNames() {
        return datastore.section.instructorLastNames?.join(', ');
      }

      return { datastore, instructorLastNames, testClass };
    },
  };
</script>
