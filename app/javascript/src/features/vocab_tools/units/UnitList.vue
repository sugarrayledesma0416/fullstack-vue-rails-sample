<template>
  <div>
    <div v-show="enrolled" :class="testClass('lesson-view-controls')">
      <button
        v-show="!localState.viewAllLessons"
        class="c-button  u-bord-1  u-bord-gray-d  u-pad-lt-16  u-pad-rt-16  u-mar-bot-4"
        :class="testClass('program-lessons')"
        @click="setAllLessonView(true)">
        View all lessons in this program
      </button>
      <button
        v-show="localState.viewAllLessons"
        class="c-button  u-bord-1  u-bord-gray-d  u-pad-lt-16  u-pad-rt-16  u-mar-bot-4"
        :class="testClass('course-lessons')"
        @click="setAllLessonView(false)">
        View only lessons for this course
      </button>
    </div>
    <div class="c-gallery  js-gallery">
      <div
        v-for="unit in unitsData.units"
        v-show="localState.viewAllLessons || unit.in_course"
        :key="unit.id"
        class="c-gallery__image"
        :class="testClass(`gallery-images-${unit.id}`)">
        <Unit :unit="unit" />
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { testClass } from 'music';
  import Unit from './Unit';

  const unitsGallery = (currentProgram, localState) => {
    const setAllLessonView = (isAllLessonVisible) => {
      localState.viewAllLessons = isAllLessonVisible;
    };

    return { setAllLessonView };
  };

  export default {
    name: 'UnitList',
    components: { Unit },
    props: {
      enrolled: { required: true, type: Boolean },
      unitsData: { required: true, type: Object },
      viewAllLessons: { required: true, type: Boolean },
    },
    setup(props) {
      const currentProgram = inject('currentProgram');
      const localState = reactive(
        { viewAllLessons: props.viewAllLessons }
      );

      const { setAllLessonView } = unitsGallery(
        currentProgram, localState
      );

      return { localState, setAllLessonView, testClass };
    },
  };
</script>
