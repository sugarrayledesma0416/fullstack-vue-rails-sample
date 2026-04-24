<template>
  <div>
    <button
      class="c-activity-header__action  js-toggle-mapped-standards-modal"
      :class="testClass('show-standards-modal-button')"
      @click="showStandardModal()">
      <span class="c-activity-header__action-text" lang="en">Standards</span>
    </button>
    <StandardsListModal
      v-if="standardModal"
      :standardsList="standardsList"
      :unitId="unitId"
      :instructorStandardsAssigningPath="instructorStandardsAssigningPath"
      @close="standardModal = false" />
  </div>
</template>
<script setup>
  import { ref } from 'vue';
  import { testClass } from 'music';
  import StandardsListModal from '../../shared/standards/StandardsListModal';

  const props = defineProps({
    unitId: { required: true, type: String },
    activityId: { required: true, type: String },
    instructorStandardsAssigningPath: { required: true, type: String },
    mappedStandards: { type: String, default: '' },
  });

  const standardModal = ref(false);
  const standardsList = ref({});

  /**
   * Get Standars by asset path.
   */
  function showStandardModal() {
    if (props.mappedStandards) {
      standardsList.value = JSON.parse(props.mappedStandards);
      standardModal.value = true;
    }
  }
</script>
