<template>
  <!-- Unit word count info -->
  <span :id="`a11y-unit-extra-info-${unit.id}`">
    <span v-show="wordCount > 0" class="u-txt-white  u-mar-rt-8">
      <span class="u-screen-reader-only">
        {{ selectedWordCount }} out of {{ wordCount }} words selected
      </span>
      <span aria-hidden="true" :class="testClass('unit-word-count-info')">
        {{ selectedWordCount }}/{{ wordCount }}
      </span>
    </span>
    <span id="a11y-level-1" class="u-screen-reader-only">
      Level 1
    </span>
  </span>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import useWordCounting from './use_word_counting';

  export default {
    name: 'UnitWordCount',
    props: {
      unit: { required: true, type: Object },
    },
    setup(props) {
      const { unitSelectedWordsCount, unitWordCount } = useWordCounting();
      const selectedWordCount = computed(() => unitSelectedWordsCount(props.unit));
      const wordCount = computed(() => unitWordCount(props.unit));

      return { testClass, selectedWordCount, wordCount };
    },
  };
</script>
