<template>
  <div>
    <ChooseTemplate :loadingIconPath="loadingIconPath" class="mar-bot-16" />
    <SelectContent class="mar-bot-16" />
    <DueDatesStep class="mar-bot-16" />
    <ReviewAssignmentsStep :loadingIconPath="loadingIconPath" />
  </div>
</template>

<script>
  import { inject, provide, ref } from 'vue';
  import { testClass } from 'music';
  import ChooseTemplate from './components/ChooseTemplate';
  import ReviewAssignmentsStep from './components/ReviewAssignmentsStep';
  import SelectContent from './components/SelectContent';
  import DueDatesStep from './components/DueDatesStep';
  import useLearningTrack from './use_learning_track';
  import useLearningTrackWatchers from './use_learning_track_watchers';
  import LearningTrackDataStore from './learning_track_data_store';
  import UnitRange from './models/unit_range';

  export default {
    name: 'LearningTrackApp',
    components: { ChooseTemplate, DueDatesStep, ReviewAssignmentsStep, SelectContent },
    props: {
      loadingIconPath: { required: true, type: String },
      parentModel: { required: true, type: Object },
    },
    setup(props) {
      const assignmentCalendar = inject('assignmentCalendar');
      const config = inject('config');
      assignmentCalendar.unitRange = new UnitRange(undefined, undefined, []);

      const reviewComponentKey = ref(0);
      const learningTrackData = new LearningTrackDataStore(props.parentModel, reviewComponentKey);
      const { addWatchers } = useLearningTrackWatchers(
        assignmentCalendar, learningTrackData, reviewComponentKey
      );
      addWatchers();

      const { updateDataStore } = useLearningTrack(
        assignmentCalendar, config, learningTrackData
      );
      updateDataStore();
      provide('learningTrackData', learningTrackData);
      provide('reviewComponentKey', reviewComponentKey);

      return { learningTrackData, reviewComponentKey, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  .mar-bot-16 {
    margin-bottom: 1rem;
  }
</style>
