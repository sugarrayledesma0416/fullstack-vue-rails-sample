<template>
  <li
    :id="`id-topic-${topicIndex}`"
    class="c-form-item  u-pad-8"
    :class="[
      { 'c-bg-topic-selected' : topic.selected },
      testClass(`topic-${lessonId}-${lessonIndex}`)
    ]">
    <input
      :id="`topic-${lessonId}-${topicIndex}-checkbox`"
      :checked="topic.selected"
      type="checkbox"
      :aria-describedby="`a11y-lesson-${lessonId}-level-${level + 1}`"
      class="c-form-item__checkbox"
      :class="testClass(`topic-${stringWithoutSpace(topic.name)}-checkbox`)"
      :lang="targetLanguageCode"
      @click="$emit(
        'toggleTopicSelection',
        { event: $event, lessonId, topicName: topic.name, unitId }
      )">

    <!-- Topic word count info -->
    <label
      :for="`topic-${lessonId}-${topicIndex}-checkbox`"
      class="c-form-item__label  l-splitter  u-dis-flex
              flex-align-start  u-mar-0  u-txt-gray-3">
      <span
        :class="testClass(`topic-${stringWithoutSpace(topic.name)}`)"
        :lang="topic.name?.toLowerCase().includes('my words') ? 'en' : targetLanguageCode"
        v-html="topic.name" />
      <span
        class="c-lesson-selector__word-count  u-mar-lt-3"
        :class="testClass(`topic-${stringWithoutSpace(topic.name)}-word-count`)">
        {{ topic.wordCount }}
        <span class="u-screen-reader-only">
          word{{ topic.wordCount > 1 ? 's' : '' }}
        </span>
      </span>
    </label>
  </li>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'Topic',
    props: {
      lessonId: { required: true, type: Number },
      lessonIndex: { required: true, type: Number },
      level: { default: 0, type: Number },
      targetLanguageCode: { default: '', type: String },
      topic: { required: true, type: Object },
      topicIndex: { required: true, type: Number },
      unitId: { required: true, type: Number },
    },
    emits: ['toggleTopicSelection'],
    setup(props) {
      const stringWithoutSpace = (str) => {
        return str?.replace(/ /g, '_');
      };

      return { stringWithoutSpace, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .ns-music-v1 .c-vocab-tree-list__topic li.c-bg-topic-selected {
    background-color: #e8efff;
  }
</style>
