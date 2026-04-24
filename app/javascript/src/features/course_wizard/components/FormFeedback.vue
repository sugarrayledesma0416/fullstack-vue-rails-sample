<template>
  <div
    v-if="invalidValidations.length"
    class="feedback">
    <div class="summary">
      <div class="summary__icon">
        <IconError class="error-icon" />
      </div>
      <p class="summary__text">
        {{ summary }}
      </p>
    </div>
    <ul
      class="validations  validations--invalid">
      <li
        v-for="validation in invalidValidations"
        :key="validation.id"
        class="validation-message  validation-message--invalid">
        {{ validation.description }}
      </li>
    </ul>
  </div>
</template>

<script setup>
  import { inject, computed } from 'vue';
  import IconError from './IconError';

  const defaultValidations = [];
  const courseDataStore = inject('courseDataStore', {
    validations: defaultValidations,
  });

  /**
   * Returns an array of all invalid validations.
   */
  const invalidValidations = computed(() => {
    return courseDataStore.validations.filter((validation) =>
      validation.status === 'invalid'
    );
  });

  const summary = computed(() => {
    const errorsCount = invalidValidations.value.length;
    let phrase = '';
    if (errorsCount === 1) {
      phrase = '1 error is preventing changes from being saved.';
    } else if (errorsCount > 1) {
      phrase = `${errorsCount} errors are preventing changes from being saved.`;
    }
    return phrase;
  });

</script>

<style lang="scss" scoped>
  @use '~MusicAssets/stylesheets/music/library/v1/base/main' as *;

  .feedback {
    background-color: $light-orange;
    padding: 1rem;
  }

  .summary {
    display: flex;
    flex-wrap: nowrap;
    margin-bottom: 1rem;
  }

  .summary__icon {
    flex-basis: rpx(30);
    font-size: 1.2rem;
    line-height: 1.6;
  }

  .summary__text {
    font-size: 1.2rem;
    margin-bottom: 0;
  }

  .validations {
    padding: 0;
    margin-left: 3rem;
  }

  .validation-message {
    padding: 0;
    margin: 0;
  }

  .error-icon {
    position: relative;
    top: 0.2rem;
    width: 1.2rem;
  }
</style>
