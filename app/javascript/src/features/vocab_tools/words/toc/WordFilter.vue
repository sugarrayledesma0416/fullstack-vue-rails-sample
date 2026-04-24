<template>
  <div class="js-word-filter">
    <!-- Two tier UI (showing units and lessons) -->
    <ul v-if="twoTier" class="c-vocab-tree-list  c-vocab-tree-list__unit">
      <template v-for="unit in filteredUnits">
        <LessonList
          v-if="shouldShowUnit(unit)"
          :key="unit.id"
          :ssjrStudent="ssjrStudent"
          :targetLanguageCode="targetLanguageCode"
          :unit="unit"
          :viewAllLessons="viewAllLessons"
          @retrieveLesson="$emit('retrieveLesson', $event)"
          @toggleLessonSelection="$emit('toggleLessonSelection', $event)"
          @toggleTopicSelection="$emit('toggleTopicSelection', $event)" />
      </template>
    </ul>

    <!-- Single tier UI (showing lessons only) -->
    <ul
      v-else
      class="c-vocab-tree-list  c-vocab-tree-list__lesson  c-lesson-selector  c-list--boxy">
      <template
        v-for="({ lesson, unit }, lessonIndex) in lessonsWithUnitInfo"
        :key="`${unit.id}-${lesson.id}`">
        <li
          class="c-lesson-list-item"
          :class="[
            { 'c-disclosure-expanded': lesson.expanded },
            testClass('lesson-list-item')
          ]"
          item-type="topic"
          :parent-id="lesson.id">
          <TopicList
            :id="`id-${unit.id}-${lesson.id}`"
            :lesson="lesson"
            :lessonIndex="lessonIndex"
            :level="1"
            :ssjrStudent="ssjrStudent"
            :targetLanguageCode="targetLanguageCode"
            :unitId="unit.id"
            @retrieveLesson="$emit('retrieveLesson', $event)"
            @toggleLessonSelection="$emit('toggleLessonSelection', $event)"
            @toggleTopicSelection="$emit('toggleTopicSelection', $event)" />
        </li>
      </template>
    </ul>
  </div>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import TopicList from 'features/vocab_tools/words/toc/TopicList';
  import LessonList from 'features/vocab_tools/words/toc/LessonList';

  export default {
    name: 'WordFilter',
    components: { LessonList, TopicList },
    props: {
      ssjrStudent: { default: false, type: Boolean },
      targetLanguageCode: { default: '', type: String },
      twoTier: { default: false, type: Boolean },
      units: { required: true, type: Array },
      viewAllLessons: { default: false, type: Boolean },
    },
    emits: ['retrieveLesson', 'toggleLessonSelection', 'toggleTopicSelection'],
    setup(props) {
      const shouldShowUnit = (unit) => props.viewAllLessons || unit.inCourse;
      const shouldShowLesson = (lesson) => props.viewAllLessons || lesson.inCourse;

      /**
       * This returns filtered array based on viewAllLessons and inCourse configuration
       */
      const filteredUnits = computed(() => props.units.filter(shouldShowUnit));

      /**
       * This returns flatten lessons array with unit info from units props
       * @return {Array.<{lesson: Object, unit: Object}>} - array with lesson and unit info
       */
      const lessonsWithUnitInfo = computed(() => {
        return filteredUnits.value.flatMap((unit) => {
          return unit.lessons.map((lesson) => {
            return { lesson, unit: { id: unit.id }};
          });
        });
      });

      return { filteredUnits, lessonsWithUnitInfo, shouldShowLesson, shouldShowUnit, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .ns-music-v1 .c-vocab-tree-list__lesson > li {
    margin-bottom: rpx(8);
  }
</style>
