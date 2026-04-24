<template>
  <svg
    width="22"
    height="22"
    viewBox="0 0 22 22"
    xmlns="http://www.w3.org/2000/svg"
    :class="props.disabled ? 'svg-disabled' : 'svg-enabled'">
    <path d="M11 22C4.93 22 0 17.07 0 11C0 4.93 4.93 0 11 0C17.07 0 22 4.93 22 11C22 17.07 17.07 22 11 22ZM11 2C6.04 2 2 6.04 2 11C2 15.96 6.04 20 11 20C15.96 20 20 15.96 20 11C20 6.04 15.96 2 11 2ZM11 16C8.03 16 6.27 13.7 6.2 13.6C5.87 13.16 5.96 12.53 6.4 12.2C6.84 11.87 7.47 11.96 7.8 12.4C7.83 12.44 9.07 14 11 14C12.93 14 14.19 12.41 14.2 12.4C14.53 11.96 15.16 11.88 15.6 12.21C16.04 12.54 16.13 13.16 15.8 13.6C15.73 13.7 13.97 16 11 16ZM14 9.5C13.17 9.5 12.5 8.83 12.5 8C12.5 7.17 13.17 6.5 14 6.5C14.83 6.5 15.5 7.17 15.5 8C15.5 8.83 14.83 9.5 14 9.5ZM8 9.5C7.17 9.5 6.5 8.83 6.5 8C6.5 7.17 7.17 6.5 8 6.5C8.83 6.5 9.5 7.17 9.5 8C9.5 8.83 8.83 9.5 8 9.5Z" fill="inherit"/>
  </svg>
</template>

<script setup>
  const props = defineProps({
    disabled: {
      required: true,
      type: Boolean
    }
  });
</script>

<style lang="sass" scoped>
  .svg-enabled {
    fill: #1d873e;
    margin: 2px;
  }
 
  .svg-disabled {
    fill: #ccc;
    margin: 2px;
  }
</style>
