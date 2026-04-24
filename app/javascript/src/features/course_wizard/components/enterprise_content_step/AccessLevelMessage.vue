<template>
  <p :class="testClass('access-level-message')">
    The access level at
    <strong :class="testClass('school')">{{ selectedSchoolName() }}</strong> is
    <strong :class="testClass('levels')">{{ coursePackagesNames() }}</strong>
  </p>
</template>

<script setup>
  import { testClass } from 'music';
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');

  /**
   * This method returns selected school name
   * @return {string}
   */
  function selectedSchoolName() {
    const school = courseDataStore.store.courseOptions.schools?.find(
      (sch) => sch.id === courseDataStore.store.course.schoolId
    );
    return school?.name;
  }

  /**
   * This method returns course package names from course options
   * @return {string}
   */
  function coursePackagesNames() {
    return courseDataStore.courseSerializer.coursePackagesNames(
      courseDataStore.store.courseOptions.levels,
      courseDataStore.store.courseOptions.components
    ).join(', ');
  }
</script>
