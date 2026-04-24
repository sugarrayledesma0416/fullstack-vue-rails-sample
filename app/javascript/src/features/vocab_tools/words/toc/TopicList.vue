<template>
  <!-- Disclosure showing a lesson and topics in it -->
  <div
    ref="refDisclosureElm"
    class="c-disclosure  c-disclosure--start  flex-align-ctr  flex-justify-between"
    :class="[
      `js-topic-list-disclosure-${lesson.id}`,
      testClass('topic-list-disclosure')
    ]">
    <!-- Button to toggle lesson disclosure -->
    <button
      :aria-controls="`disclosure-body-${lesson.id}-${lessonIndex}`"
      :aria-expanded="initialAriaVal"
      :aria-describedby="`a11y-lesson-extra-info-${lesson.id}`"
      :lang="targetLanguageCode"
      role="button"
      type="button"
      class="c-disclosure__header  c-disclosure__header--vocab
            c-no-button  flex-order-0  u-txt-nodec"
      :class="testClass('disclosure-lesson-opener')"
      @click="$emit('retrieveLesson', { lessonId: lesson.id, unitId })">
      <div class="c-disclosure__marker  c-disclosure__marker--reverse" />
      <h3
        class="c-lesson-display-name  u-dis-inline  u-pad-rt-8"
        :class="testClass(`lesson-display-name-${lesson.id}`)"
        :innerHTML="lesson.displayName" />
    </button>
    <LessonWordCount :lesson="lesson" :level="level" :ssjrStudent="ssjrStudent" />

    <!-- List to enable lesson or topic selection for word filtering -->
    <ul
      :id="`disclosure-body-${lesson.id}-${lessonIndex}`"
      class="checklist c-vocab-tree-list  c-vocab-tree-list__topic
            c-disclosure__body  u-pad-0  u-mar-0"
      :class="testClass(`disclosure-body-lesson-${lesson.id}`)">
      <!-- List item to display Select All Topic or lesson selection checkbox -->
      <li
        v-if="!ssjrStudent || filterEmptyTopics.length > 1"
        class="c-form-item  u-pad-8"
        :class="[
          {
            'c-bg-select-all-selected' : lesson.selected,
            'u-bg-gray-f5': !ssjrStudent,
          },
          `js-lesson-${lesson.id}-select-all`,
          testClass(`lesson-${lesson.id}-select-all`)
        ]">
        <input
          :id="`lesson-${lesson.id}-checkbox`"
          :checked="lesson.selected"
          type="checkbox"
          :aria-describedby="`a11y-lesson-${lesson.id}-level-${level + 1}`"
          class="c-form-item__checkbox"
          :class="testClass(`lesson-${lesson.id}-name`)"
          @click="$emit('toggleLessonSelection', { event: $event, lessonId: lesson.id, unitId });">
        <label
          :for="`lesson-${lesson.id}-checkbox`"
          class="c-form-item__label  u-mar-0  u-txt-gray-3">
          Select all
        </label>
        <span :id="`a11y-lesson-${lesson.id}-level-${level + 1}`" class="u-screen-reader-only">
          Level {{ level + 1 }}
        </span>
      </li>

      <!-- List items to display topics with word count and topic selection checkbox  -->
      <Topic
        v-for="(topic, topicIndex) in filterEmptyTopics"
        :key="topicIndex"
        :lessonId="lesson.id"
        :lessonIndex="lessonIndex"
        :level="level"
        :targetLanguageCode="targetLanguageCode"
        :topic="topic"
        :topicIndex="topicIndex"
        :unitId="unitId"
        @toggleTopicSelection="$emit('toggleTopicSelection', $event)" />
    </ul>
  </div>
</template>

<script>
  import { computed, onMounted, ref } from 'vue';
  import { testClass } from 'music';
  import LessonWordCount from 'features/vocab_tools/words/toc/LessonWordCount';
  import Topic from 'features/vocab_tools/words/toc/Topic';

  export default {
    name: 'TopicList',
    components: { LessonWordCount, Topic },
    props: {
      lesson: { required: true, type: Object },
      lessonIndex: { required: true, type: Number },
      level: { default: 0, type: Number },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguageCode: { default: '', type: String },
      unitId: { required: true, type: Number },
    },
    emits: ['retrieveLesson', 'toggleLessonSelection', 'toggleTopicSelection'],
    setup(props) {
      const refDisclosureElm = ref(null);
      const initializeDisclosure = () => new VHL.Music.V1.Disclosure(refDisclosureElm.value);
      const initialAriaVal = props.lesson.expanded;

      const filterEmptyTopics = computed(() => {
        return props.lesson?.topics?.filter((topic) => !topic.isEmpty) ?? [];
      });

      onMounted(initializeDisclosure);

      return { filterEmptyTopics, initialAriaVal, refDisclosureElm, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .ns-music-v1 h3 {
    color: $white;
  }
</style>
