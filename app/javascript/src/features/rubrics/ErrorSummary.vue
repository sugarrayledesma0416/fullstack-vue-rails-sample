<template>
  <div
    v-show="rubric.errorValidatorCount > 0"
    class="rubric-validation-error-container">
    <span class="rubric-validation-error-message">
      {{ rubric.errorValidatorCount }}
      <span v-if="rubric.errorValidatorCount === 1">error</span>
      <span v-else>errors</span>
      prevented saving.
    </span>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const rubric = inject('rubric');

</script>

<style>
  .rubric-validation-error-container {
    margin-top: 1rem;
    padding: 0.5rem;
    border: 0.0625rem solid #CE0C24;
    background-color: #ffe2e5;
  }

  .rubric-validation-error-message {
    color: #CE0C24;
    font-weight: bold;
  }

  .ns-supersites-jr {
    --jr-text-error-color: #E8172F;
  }

  .ns-supersites-jr .rubric-validation-error-container {
    border: 0.0625rem solid #FF003D;
    background-color: #FF003D10;
  }

  .ns-supersites-jr .rubric-validation-error-message {
    color: var(--jr-text-error-color);
  }
</style>
