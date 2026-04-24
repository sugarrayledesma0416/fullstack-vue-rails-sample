<template>
  <div
    v-if="currentNote"
    ref="disclosureElm"
    class="c-disclosure  c-disclosure--end  c-instructor-note  js-disclosure-instructor-notes">
    <button
      type="button"
      data-content-type="note_body_header"
      class="c-disclosure__header  c-no-button  c-instructor-note__header"
      aria-expanded="false">
      <div class="u-dis-flex">
        <div aria-labelledby="a11y-instructor-note-icon">
          <Icon
            class="c-embedded-icon--md-lg  u-pad-2"
            :class="testClass('instructor-note-icon')"
            :svg="fileSvgInstructorNoteIcon" />
          <span id="a11y-instructor-note-icon" class="u-screen-reader-only">
            Instructor note
          </span>
        </div>
        <div
          v-if="currentNote.recording_path"
          aria-labelledby="a11y-audio-note-icon">
          <Icon
            class="c-embedded-icon--md-lg  u-pad-2"
            :class="testClass('audio-note-icon')"
            :svg="fileSvgAudioPresent" />
          <span id="a11y-audio-note-icon" class="u-screen-reader-only">
            Audio note present
          </span>
        </div>
        <span class="c-intructor-note-title" :class="testClass('intructor-note-title')">
          {{ currentNote.title }}
        </span>
      </div>

      <div class="c-disclosure__marker  u-mar-6">
        <Icon
          class="c-embedded-icon--md-lg  u-pad-2"
          :class="testClass('disclosure-marker')"
          :svg="fileSvgDisclosureMarker" />
      </div>
    </button>

    <div class="c-disclosure__body  c-instructor-note__body  u-mar-lt-0">
      <div
        class="c-instructor-note-text"
        :class="testClass('instructor-note-text')"
        data-content-type="note_body_text"
        v-html="currentNote.body_text" />

      <div class="c-instructor-note-action-item">
        <div
          v-if="currentNote.recording_path"
          class="c-audio-note-container"
          aria-labelledby="a11y-audio-note">
          <MusicMediaButton
            ref="refPlaybackButton"
            variant="listen"
            :classes="[testClass('note-player')]"
            text="Play"
            toggle="stop"
            :state="audioButtonState.playerState"
            :onActivate="recordingControlsManager.onPlayBackActivate"
            :onDeactivate="recordingControlsManager.onPlayBackDeactivate" />
          <span id="a11y-instructor-note" class="u-screen-reader-only">
            Audio note
          </span>
        </div>
        <div
          v-if="canEditInstructorNotes"
          class="c-instructor-note-action-link"
          :class="testClass('instructor-note-action-link')">
          <button
            type="button"
            class="c-no-button  is-navigable  u-txt-upper  u-mar-rt-16"
            :class="testClass('edit-note')"
            @click="onEditClick()">
            Edit
          </button>
          <button
            type="button"
            class="c-no-button  is-navigable  u-txt-upper  u-mar-rt-16"
            :class="testClass('delete-note')"
            @click="onDeleteClick()">
            Delete
          </button>
        </div>
      </div>
    </div>

    <EditActivityNote
      v-if="editMode && canEditInstructorNotes"
      :note="currentNote"
      :class="testClass('edit-modal')"
      @close="onEditClose"
      @update="onNoteUpdate" />
  </div>
</template>

<script>
  import * as ajaxUtils from 'shared/ajax_utils';
  import { dispatchCustomEvent } from 'shared/utils';
  import { testClass } from 'music';
  import { computed, inject, onMounted, reactive, ref, toRef, watch } from 'vue';
  import MusicMediaButton from 'shared/vue/MusicMediaButton';
  import Icon from 'features/shared/Icon';
  import EditActivityNote from './EditActivityNote';
  import fileSvgInstructorNoteIcon from '!!raw-loader!MusicAssets/images/music/toc/instructor_note_icon_rounded.svg';
  import fileSvgAudioPresent from '!!raw-loader!MusicAssets/images/music/toc/audio.svg';
  import fileSvgDisclosureMarker from '!!raw-loader!MusicAssets/images/music/icons/caret.svg';
  import RecordingControlsManager from 'shared/vue/recording_controls_manager';

  const useActivityNote = (currentNote, emit, isExpanded, editMode) => {
    const onDeleteSuccess = () => {
      emit('deleted', currentNote.id);
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: 'Note successfully removed!' },
      });
    };

    const onDeleteError = () => {
      dispatchCustomEvent({
        name: 'showErrorMsg',
        detail: { text: 'Note removal error! ' },
      });
    };

    const initializeDisclosure = (disclosureElm, disclosure) => {
      disclosure.value = new VHL.Music.V1.Disclosure(disclosureElm.value);
      if (isExpanded.value) {
        disclosure.value.toggle();
      }
    };

    const onDeleteClick = () => {
      if (confirm('Are you sure you want to delete this note?')) {
        const url = `/instructor/${currentNote.program_id}/activity/${currentNote.activity_id}/activity_notes/${currentNote.id}`;
        ajaxUtils.deleteFromEndpoint(
          url,
          (data) => {
            data.status === 200 ? onDeleteSuccess() : onDeleteError();
          }
        );
      }
    };

    const onEditClose = () => {
      editMode.value = false;
    };

    const onEditClick = () => {
      editMode.value = true;
    };

    const onNoteUpdate = (note) => {
      editMode.value = false;
      currentNote.title = note.title;
      currentNote.note_type = note.note_type;
      currentNote.body_text = note.body_text;
      currentNote.recording_path = note.recording_path;
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: 'Note successfully saved!' },
      });
    };

    return {
      initializeDisclosure, onDeleteClick, onEditClose, onEditClick, onNoteUpdate,
    };
  };

  const useAudioButton = (currentNote) => {
    const refPlaybackButton = ref(null);
    const recordingPathRef = toRef(currentNote, 'recording_path');

    // This button state is passed as localState param in composable and would be updated there
    const audioButtonState = reactive({
      playerState: 'hidden',
      recordingCdnPrefix: VHL.InstructorNotes.Config.cdnPrefix,
      recordingPath: recordingPathRef.value,
    });

    const recordingControlsManager = new RecordingControlsManager(
      audioButtonState,
      VHL.InstructorNotes.Config,
      null,
      refPlaybackButton
    );

    const resetPlaybackControl = () => {
      if (recordingControlsManager.refPlayerInstance.value?.is_playing()) {
        recordingControlsManager.refPlayerInstance.value.stop();
      }

      resetPlayer();
      audioButtonState.playerState = 'disabled';
    };

    const resetPlayer = () => {
      // Media button callbacks 'activate' and 'deactivate' won't execute due to this null value
      recordingControlsManager.refPlayerInstance.value = null;
    };

    const onRecordingPathChange = (recordingPath) => {
      if (recordingPath) {
        audioButtonState.recordingPath = recordingPath;
        recordingControlsManager.setupAudioPlayBack(recordingPath);
      } else {
        resetPlaybackControl();
      }
    };

    watch(
      recordingPathRef,
      (newValue) => onRecordingPathChange(newValue)
    );

    return {
      audioButtonState,
      recordingControlsManager,
      refPlaybackButton,
    };
  };

  export default {
    name: 'ActivityNote',
    components: {
      MusicMediaButton, Icon, EditActivityNote,
    },
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    emits: ['deleted'],
    setup(props, { emit }) {
      const { note } = props;
      const currentNote = reactive({ ...note });
      const allowsExpandedNotes = inject('allowsExpandedNotes');
      const controllerType = inject('controllerType');
      const userType = inject('userType');
      const disclosureElm = ref(null);
      const disclosure = ref(null);
      const editMode = ref(false);
      const canEditInstructorNotes = userType !== 'Student' && controllerType !== 'grading_styles';

      /**
       * Notes with old 'note_type' value (sidebar & inline) need
       * to be transformed to their new value,
       * for correctly rendering it in the note modal.
       * The transition is:-
       *   - 'sidebar' is  'collapsed'
       *   - 'inline'  is  'expanded'
       * When an old note is edited & saved its note_type will be
       * updated to the corresponding new value.
      */

      if (currentNote.note_type === 'sidebar') {
        currentNote.note_type = 'collapsed';
      }
      if (currentNote.note_type === 'inline') {
        currentNote.note_type = 'expanded';
      }

      const isExpanded = computed(() => allowsExpandedNotes && currentNote.note_type === 'expanded');

      const {
        initializeDisclosure, onDeleteClick, onEditClick, onEditClose, onNoteUpdate,
      } = useActivityNote(
        currentNote, emit, isExpanded, editMode
      );

      const {
        audioButtonState,
        recordingControlsManager,
        refPlaybackButton,
      } = useAudioButton(currentNote);

      watch(isExpanded, (newValue) => {
        if (newValue === false) {
          disclosure.value.toggle();
        }
      });

      onMounted(() => {
        initializeDisclosure(disclosureElm, disclosure);
        recordingControlsManager.setupAudioPlayBack(currentNote.recording_path);
      });

      return {
        audioButtonState,
        canEditInstructorNotes,
        currentNote,
        disclosureElm,
        editMode,
        fileSvgAudioPresent,
        fileSvgDisclosureMarker,
        fileSvgInstructorNoteIcon,
        onDeleteClick,
        onEditClick,
        onEditClose,
        onNoteUpdate,
        recordingControlsManager,
        refPlaybackButton,
        testClass,
      };
    },
  };
</script>
