<template>
  <div>Hello, {{ name }}!</div>
</template>

<script setup>
  defineProps({
    name: {
      type: String,
      required: true
    }
  })
</script>
