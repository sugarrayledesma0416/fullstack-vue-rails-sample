<template>
  <div>
    <div><span class="u-txt-bold">Activity:</span> {{ props.entry.activityTitle }}</div>
    <div><span class="u-txt-bold">Direction line:</span> <span v-html="props.entry.directionLine" /></div>
    <div><span class="u-txt-bold">Question Prompt:</span> <span v-html="props.entry.questionPrompt" /></div>
    <div><span class="u-txt-bold">Student Response:</span> {{ props.entry.studentResponse }}</div>
    <ButtonSecondary
      theme="vol"
      :disabled="isSaved"
      @click="props.saveEntry">
      Save Response
    </ButtonSecondary>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import ButtonSecondary from
  'music/app/javascript/src/components/button_secondary/v1.2/ButtonSecondary';

  const props = defineProps({
    /**
     * The raw data for the entry.
     */
    entry: { required: true, type: Object },
    /**
     * Reference to a function that, when called, will save the entry.
     */
    saveEntry: { required: true, type: Function },
  });

  const isSaved = computed(() => {
    return props.entry.isSaved;
  });
</script>
