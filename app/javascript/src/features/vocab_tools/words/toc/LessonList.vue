<template>
  <li
    :id="`id-${unit.id}`"
    :key="unit.id"
    ref="refDisclosureElm"
    item-type="lesson"
    :parent-id="unit.id"
    aria-describedby="a11y-level-1"
    :class="[
      `js-lesson-list-disclosure-${unit.id}`,
      testClass('lesson-list-disclosure')
    ]">
    <!-- Disclosure showing a unit and lessons in it -->
    <div
      class="c-disclosure  c-disclosure--start
             flex-align-ctr  flex-justify-between  js-error-disclosure">
      <!-- Button to toggle unit disclosure -->
      <button
        role="button"
        :aria-expanded="unit.expanded"
        :aria-controls="`disclosure-body-${unit.id}`"
        :aria-describedby="`a11y-unit-extra-info-${unit.id}`"
        :lang="targetLanguageCode"
        class="c-disclosure__header  c-disclosure__header--vocab
                  c-no-button  flex-order-0  u-txt-nodec"
        :class="`js-unit-${unit.id}-disclosure-button`">
        <div class="c-disclosure__marker  c-disclosure__marker--reverse" />
        <h3
          class="u-dis-inline  u-pad-rt-8  u-txt-white"
          :class="testClass(`unit-name-${unit.id}`)"
          :innerHTML="unit.name"/>
      </button>

      <!-- Unit word count info -->
      <UnitWordCount :unit="unit" />
    </div>

    <!-- List of lesson with topics in it -->
    <ul
      :id="`disclosure-body-${unit.id}`"
      class="c-vocab-tree-list  c-vocab-tree-list__lesson  c-disclosure__body  u-pad-0">
      <template v-for="(lesson, lessonIndex) in unit.lessons">
        <li
          v-if="viewAllLessons || lesson.inCourse"
          :key="lesson.id"
          class="u-mar-bot-8"
          :class="testClass('lesson-list-item')"
          item-type="topic"
          :parent-id="lesson.id">
          <TopicList
            :id="`id-${lesson.id}`"
            :key="lesson.id"
            :lesson="lesson"
            :lessonIndex="lessonIndex"
            :level="2"
            :ssjrStudent="ssjrStudent"
            :targetLanguageCode="targetLanguageCode"
            :unitId="unit.id"
            @retrieveLesson="$emit('retrieveLesson', $event)"
            @toggleLessonSelection="$emit('toggleLessonSelection', $event)"
            @toggleTopicSelection="$emit('toggleTopicSelection', $event)" />
        </li>
      </template>
    </ul>
  </li>
</template>

<script>
  import { onMounted, ref } from 'vue';
  import { testClass } from 'music';
  import TopicList from 'features/vocab_tools/words/toc/TopicList';
  import UnitWordCount from 'features/vocab_tools/words/toc/UnitWordCount';

  export default {
    name: 'LessonList',
    components: { TopicList, UnitWordCount },
    props: {
      ssjrStudent: { default: false, type: Boolean },
      targetLanguageCode: { default: '', type: String },
      unit: { required: true, type: Object },
      viewAllLessons: { default: false, type: Boolean },
    },
    emits: ['retrieveLesson', 'toggleLessonSelection', 'toggleTopicSelection'],
    setup(props) {
      const refDisclosureElm = ref(null);
      const initializeDisclosure = () => new VHL.Music.V1.Disclosure(refDisclosureElm.value);

      onMounted(initializeDisclosure);

      return { refDisclosureElm, testClass };
    },
  };
</script>
