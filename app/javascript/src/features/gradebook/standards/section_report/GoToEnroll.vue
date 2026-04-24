<template>
  <div class="container-fluid  u-bg-white u-pad-top-16">
    <h3 class="u-txt-ctr">
      Students
    </h3>
    <p
      class="u-txt-ctr  u-mar-bot-24  u-txt-gray-6"
      :class="testClass('no-students-msg')">
      No students enrolled in this section yet. Go<br>
      to Enroll to see your student data below.
    </p>
    <div class="c-button-group  c-button-group--ctr  u-pad-bot-24">
      <a
        id="go-to-enroll"
        :class="[
          'go-to-enrroll-button',
          testClass('go-to-enroll-link')]"
        :href="newInstructorEnrollmentPath">
        Go to Enroll
      </a>
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  defineProps({
    newInstructorEnrollmentPath: { required: true, type: String },
  });
</script>
