<template>
  <div ref="targetEl">
    <slot v-if="shouldRender" />
  </div>
</template>

<script setup>
  import { ref } from 'vue';
  import { useIntersectionObserver } from '@vueuse/core';

  const shouldRender = ref(false);
  const targetEl = ref();

  const { stop } = useIntersectionObserver(
    targetEl,
    ([{ isIntersecting }]) => {
      shouldRender.value = true;
      stop();
    },
    {
      rootMargin: '600px',
    }
  );
</script>
