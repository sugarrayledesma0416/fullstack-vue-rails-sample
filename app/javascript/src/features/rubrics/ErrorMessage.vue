<template>
  <div v-show="rubric.validationError[props.cellValidator].length > 0">
    <p
      v-for="error in rubric.validationError[props.cellValidator]"
      :key="error"
      class="c-form-item__error">
      {{ error }}
    </p>
  </div>
</template>

<script setup>
  import { inject } from 'vue';
  const props = defineProps(
    {
      cellValidator: { default: '', type: String },
    }
  );

  const rubric = inject('rubric');

</script>
