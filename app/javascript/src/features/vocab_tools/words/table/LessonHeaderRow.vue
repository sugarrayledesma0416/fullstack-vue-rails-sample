<template>
  <header
    class="c-header-row  c-header-row--vocab-tools  c-header-row--second"
    :class="lesson.selected ? '' : 'no-print'">
    <!-- eslint-disable vue/no-v-html -->
    <h3
      class="c-lesson-name  u-mar-0"
      :class="testClass('lesson-name')"
      :lang="targetLanguageCode"
      v-html="lesson.name"/>
    <!-- eslint-enable vue/no-v-html -->
  </header>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'LessonHeaderRow',
    props: {
      lesson: { required: true, type: Object },
      targetLanguageCode: { required: true, type: String },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .c-lesson-name {
    color: $gray-6;
  }
</style>
