<template>
  <div class="c-instructor-note-audio-recorder">
    <div v-show="!hideRecordReviewSection" class="c-instructor-note-record-review">
      <div class="ns-music-v1" data-content-type="audio_recorder">
        <div
          class="instructor_note_recorder  l-inline-group"
          :class="testClass('instructor-note-audio-controls')">
          <MusicMediaButton
            variant="speak"
            :classes="[testClass('instructor-note-audio-recorder')]"
            text="Record"
            toggle="stop"
            :volume="true"
            :state="localState.recorderState"
            :onActivate="recordingControlsManager.onRecorderActivate"
            :onDeactivate="recordingControlsManager.onRecorderDeactivate"
            :onVolume="recordingControlsManager.onRecorderVolume" />
          <MusicMediaButton
            ref="refPlaybackButton"
            variant="listen"
            :classes="[testClass('instructor-note-audio-player')]"
            text="Play"
            toggle="stop"
            :state="localState.playerState"
            :onActivate="recordingControlsManager.onPlayBackActivate"
            :onDeactivate="recordingControlsManager.onPlayBackDeactivate" />
        </div>
      </div>
    </div>
    <div class="c-instructor-note-delete-record">
      <div class="c-instructor-note-delete-icon">
        <a
          href="javascript://"
          :class="{ 'is-disabled': localState.disableDelete }"
          @click.prevent="onDelete">
          <MusicIcon variant="delete" size="lg" />
        </a>
      </div>
      <div>
        <p class="c-media-button__label">
          Delete Recording
        </p>
      </div>
    </div>
  </div>
</template>

<script>
  import MusicMediaButton from 'shared/vue/MusicMediaButton';
  import MusicIcon from 'shared/vue/MusicIcon';
  import { testClass } from 'music';
  import { onMounted, reactive, ref, toRef, toRefs, watch } from 'vue';

  import RecordingControlsManager from 'shared/vue/recording_controls_manager';
  import useDeleteRecordingSetup from './use_delete_recording_setup';

  export default {
    name: 'InstructorNoteAudioControls',
    components: {
      MusicIcon,
      MusicMediaButton,
    },
    props: {
      // If this prop's value is true then Recorder and playback buttons would be hidden.
      hideRecordReviewSection: {
        type: Boolean,
        required: false,
        default: false,
      },
      recordingPath: {
        type: String,
        required: false,
        default: '',
      },
    },
    emits: ['recorderStateChange', 'recordingPathChange'],
    setup(props, { emit }) {
      const { recordingPath: recordingPathProp } = toRefs(props);

      const refPlaybackButton = ref(null);

      // This component state is passed in composables and would be updated by their code
      const localState = reactive({
        recorderState: 'default',
        playerState: 'disabled',
        disableDelete: recordingPathProp.value ? false : true,
        recordingCdnPrefix: VHL.InstructorNotes.Config.cdnPrefix,
        recordingEndpoint: VHL.InstructorNotes.Config.endpoint,
        recordingPath: recordingPathProp.value,
        isRecordingInProgress: false,
      });
      const refIsRecordingInProgress = toRef(localState, 'isRecordingInProgress');
      const refRecordingPath = toRef(localState, 'recordingPath');

      const recordingControlsManager = new RecordingControlsManager(
        localState,
        VHL.InstructorNotes.Config,
        null,
        refPlaybackButton
      );

      // Include methods related to delete recording
      const { onDelete, resetRecordingControls } = useDeleteRecordingSetup(
        recordingControlsManager.refPlayerInstance,
        localState,
        recordingControlsManager.resetPlayerMediaButton,
        () => emit('recordingPathChange', localState.recordingPath)
      );

      const onRecordingPathPropChange = (recordingPath) => {
        if (recordingPath) {
          // Initialize recording controls
          recordingControlsManager.setupAudioPlayBack(localState.recordingPath);
          localState.disableDelete = false;
          emit('recordingPathChange', recordingPath);
        } else {
          resetRecordingControls();
        }
      };

      watch(
        refRecordingPath,
        (newValue) => onRecordingPathPropChange(newValue)
      );

      watch(
        refIsRecordingInProgress,
        (newValue) => emit('recorderStateChange', newValue)
      );

      onMounted(() => {
        recordingControlsManager.setupAudioRecorder(VHL.InstructorNotes.Config);
        recordingControlsManager.setupAudioPlayBack(localState.recordingPath);
      });

      return {
        localState,
        onDelete,
        recordingControlsManager,
        refPlaybackButton,
        testClass,
      };
    },
  };
</script>
