<template>
  <div>
  </div>
</template>

<script setup>
  import { onMounted } from 'vue';
  import useTourGuideStore from './models/use_tour_guide_store';

  const props = defineProps({
    user: { type: String, required: true },
    programId: { type: String, default: null },
    customTriggers: { type: String, default: '[]' },
  });

  const user = JSON.parse(props.user);
  const customTriggers = JSON.parse(props.customTriggers);
  const store = useTourGuideStore();

  onMounted(() => {
    // store.init requires window to be fully loaded for attaching to DOM elements
    store.init(user, props.programId, customTriggers);
  });
</script>
