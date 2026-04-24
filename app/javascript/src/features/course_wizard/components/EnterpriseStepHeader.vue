<template>
  <div class="container-fluid">
    <music-tab-set-v3
      id="course_steps_tab_set"
      class="u-pad-top-20"
      :style="{ pointerEvents: isEditable ? 'auto' : 'none' }">
      <button 
        aria-controls="enterprise-course-body-setup"
        @click="navigateTo('enterprise-course-step')">
        Course Setup
      </button>
      <button 
        aria-controls="enterprise-course-body-settings"
        @click="navigateTo('enterprise-content-step')">
        Settings
      </button>
      <button 
        aria-controls="enterprise-course-body-gradebook"
        @click="navigateTo('enterprise-gradebook-step')">
        Gradebook
      </button>
      <button 
        aria-controls="enterprise-course-body-review"
        @click="navigateTo('enterprise-summary-step')">
        Review
      </button>
    </music-tab-set-v3>

    <div id="enterprise-course-body-setup"></div>
    <div id="enterprise-course-body-settings"></div>
    <div id="enterprise-course-body-gradebook"></div>
    <div id="enterprise-course-body-review"></div>
  </div>
</template>

<script setup>
  import { onMounted, nextTick } from 'vue';
  import { useRoute, useRouter } from 'vue-router';

  const props = defineProps({
    headingLevel: { type: String, required: true },
    isEditable: { type: Boolean, default: false },
  });

  const router = useRouter();
  const route = useRoute();

  function navigateTo(targetRouteName) {
    if (route.name !== targetRouteName) {
      router.push({ name: targetRouteName })
    }
  }

  onMounted(
    () => {
      nextTick(() => {
        const tabSet = document.getElementById('course_steps_tab_set');
        tabSet.setActiveTab(Number(props.headingLevel));
      });
    }
  );
</script>
