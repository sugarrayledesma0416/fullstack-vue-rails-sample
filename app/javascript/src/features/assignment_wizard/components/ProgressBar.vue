<template>
  <div
    class="c-progressbar"
    role="progressbar"
    aria-valuemin="0"
    aria-valuemax="100"
    :aria-valuenow="`value`">
    <div class="c-progress-label" :class="testClass('progress-label')">
      {{ label }}
    </div>
    <div
      class="c-progress-value  c-corner-left"
      :class="[
        { 'c-corner-right': value === 100 },
        testClass('progress-value'),
      ]"
      :style="`width: ${value}%`" />
  </div>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'ProgressBar',
    props: {
      value: { default: 0, type: Number },
      label: { default: '', type: String },
    },
    setup() {
      return { testClass };
    },
  };
</script>

<style scoped>
  .c-progressbar {
    border: #ccc 1px solid;
    border-radius: 6px;
    box-sizing: border-box;
    height: 2em;
    font-size: 1.1em;
    position: relative;
  }

  .c-progress-label {
    position: absolute;
    top: 5px;
    left: 10px;
    font-weight: bold;
    color: #fff;
  }

  .c-progress-value {
    width: 100%;
    height: 100%;
    background: #0076C0;
  }

  .c-corner-left {
    border-top-left-radius: 6px;
    border-bottom-left-radius: 6px;
  }

  .c-corner-right {
    border-top-right-radius: 6px;
    border-bottom-right-radius: 6px;
  }
</style>
