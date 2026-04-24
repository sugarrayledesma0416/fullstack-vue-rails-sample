<template>
  <!-- Lesson word count info -->
  <span :id="`a11y-lesson-extra-info-${lesson.id}`">
    <span v-if="wordsCount > 0" class="c-lesson-word-count  u-mar-rt-8">
      <span class="u-screen-reader-only">
        {{ selectedWordsCount }}
        out of
        {{ wordsCount }}
        words selected
      </span>
      <span aria-hidden="true" :class="testClass('lesson-word-count-info')">
        {{ ssjrStudent ?
          `${selectedWordsCount} / ${wordsCount}` : `${selectedWordsCount}/${wordsCount}`
        }}
      </span>
    </span>
    <span
      :id="`a11y-level-${level}`"
      class="u-screen-reader-only">
      Level {{ level }}
    </span>
  </span>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import useWordCounting from './use_word_counting';

  export default {
    name: 'LessonWordCount',
    props: {
      lesson: { required: true, type: Object },
      level: { default: 0, type: Number },
      ssjrStudent: { default: false, type: Boolean },
    },
    setup(props) {
      const { lessonSelectedWordsCount, lessonWordCount } = useWordCounting();
      const selectedWordsCount = computed(() => lessonSelectedWordsCount(props.lesson));
      const wordsCount = computed(() => lessonWordCount(props.lesson));

      return { selectedWordsCount, wordsCount, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-lesson-word-count {
    color: $white;
  }
</style>
