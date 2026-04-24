<template>
  <div>
    <Heading
      variant="page-title"
      :class="testClass('course-name')"
      :level="headingLevel">
      <span v-if="courseDataStore.editCourseMode">
        Editing "{{ courseDataStore.store.course.displayName }}"
      </span>
      <span v-else>
        {{ courseDataStore.store.course.displayName }}
      </span>
    </Heading>
    <StepBreadcrumbs
      v-if="!config.instAdmin"
      class="breadcrumbs"
      :currentStepId="$route.name"
      :isVol="config.isVol"
      :pathType="courseDataStore.store.course.pathType" />
  </div>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import Heading from '../../shared/Heading';
  import StepBreadcrumbs from './SetupBreadcrumbs';

  defineProps({
    headingLevel: {
      type: String,
      default: '1',
    },
  });

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
</script>

<style lang="scss" scoped>
  .breadcrumbs {
    // The negative value is intended as a non-destructive way of closing the
    // gap between the heading text and the breadcrumbs without modifiying H tag
    // styles.
    margin: -0.8rem 0 3rem 0;
  }
</style>
