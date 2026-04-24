<template>
  <div ref="refModalContainerElm" :class="testClass('instructor-note-modal')">
    <ModalComponent title="Edit Instructor Note" @close="onCloseClick">
      <template #body>
        <div v-show="currentNote.note_item_id">
          <FlashBannerComponent :message="editModalMessage" @reset="resetEditModalMessage" />
          <div
            v-if="allowsExpandedNotes"
            data-content-type="note_type">
            <div class="u-dis-flex" :class="testClass('note-type')">
              <div class="c-form-item">
                <input
                  id="note_type_expanded"
                  v-model="currentNote.note_type"
                  class="c-form-item__radio"
                  :class="testClass('note-type-expanded')"
                  type="radio"
                  name="note_type"
                  value="expanded">
                <label class="c-form-item__label" for="note_type_expanded">
                  Expand by default
                </label>
              </div>
              <div class="c-form-item">
                <input
                  id="note_type_collapsed"
                  v-model="currentNote.note_type"
                  class="c-form-item__radio"
                  :class="testClass('note-type-collapsed')"
                  type="radio"
                  name="note_type"
                  value="collapsed">
                <label class="c-form-item__label" for="note_type_collapsed">
                  Minimized by default
                </label>
              </div>
            </div>
          </div>

          <div data-content-type="note_title" class="note_title_container">
            <div class="c-form-item">
              <label class="c-form-item__label  u-txt-reg" for="title">
                Title (Preview)
              </label>
              <input
                id="title"
                ref="titleElm"
                v-model="currentNote.title"
                class="c-form-item__input  u-width-full  u-dis-block"
                :class="testClass('note-title-input')"
                type="text">
            </div>
          </div>

          <InstructorNoteAudioControls
            :recordingPath="currentNote.recording_path"
            @recordingPathChange="onRecordingPathChange"
            @recorderStateChange="onRecorderStateChange" />

          <div data-content-type="ckeditor_container" class="instructor-note-text-entry">
            <textarea
              id="current_note_body_text"
              v-model="currentNote.body_text"
              v-ckeditor="useCkeditorOptions"
              :class="testClass('note-body-text')" />
          </div>
        </div>
      </template>
      <template #footer>
        <div class="c-button-group u-mar-0  u-txt-rt">
          <button
            aria-hidden="false"
            type="button"
            class="c-button  js-modal-a11y__last-focus-element"
            :class="testClass('cancel-button')"
            @click.stop="onCloseClick">
            Cancel
          </button>

          <button
            type="button"
            class="c-button  c-button--primary  js-modal-a11y__last-focus-element"
            :class="testClass('submit-button')"
            :disabled="isSubmitDisabled"
            @click.stop="onSubmitClick">
            Submit
          </button>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import * as ajaxUtils from 'shared/ajax_utils';
  import { testClass } from 'music';
  import { computed, inject, reactive, onMounted, nextTick, ref } from 'vue';
  import ModalComponent from '../modal/ModalComponent';
  import ckeditor from 'shared/directives/ckeditor';
  import FlashBannerComponent from '../flash_banner/FlashBannerComponent';
  import InstructorNoteAudioControls from 'views/instructor_notes/audio_controls/InstructorNoteAudioControls';
  import accentBarHelper from 'shared/accent_bar_helper';
  import useCkeditorOptions from './use_ckeditor_options';

  const useEditModal = (
    accentBarComponent,
    emit,
    currentNote,
    editModalMessage,
    recordingInProgress,
    refModalContainerElm,
    titleElm
  ) => {
    const {
      attachToAccentBarEvents,
      detachFromAccentBarEvents,
      moveAccentBarToRequestModal,
    } = accentBarHelper(
      accentBarComponent,
      refModalContainerElm,
      titleElm
    );

    const attachToAccentBar = () => {
      nextTick(() => {
        if (titleElm.value) {
          moveAccentBarToRequestModal();
          attachToAccentBarEvents(titleElm.value, currentNote, 'title');
        }
      });
    };

    const deactivateAccentBar = () => {
      if (titleElm.value && accentBarComponent.value) {
        accentBarComponent.value.deactivateAll();
        detachFromAccentBarEvents(titleElm.value);
      }
    };

    const onCloseClick = (event) => {
      deactivateAccentBar();
      emit('close', event);
    };

    const onSuccess = (data) => {
      emit('update', data);
    };

    const onError = (data) => {
      editModalMessage.shown = true;
      editModalMessage.text = data;
      editModalMessage.className = 'error';
    };

    const onSubmitClick = () => {
      /* Set title if emplty */
      if (currentNote.title === '') {
        currentNote.title = 'Instructor Note.';
      }

      const url = `/instructor/${currentNote.program_id}/activity/${currentNote.activity_id}/activity_notes/${currentNote.id}`;

      ajaxUtils.putToEndpoint(
        url,
        currentNote,
        (data) => {
          data.id ? onSuccess(data) : onError(data);
        }
      );
      deactivateAccentBar();
    };

    const onRecordingPathChange = (newRecordingPath) => {
      currentNote.recording_path = newRecordingPath;
    };

    const onRecorderStateChange = (newValue) => {
      recordingInProgress.value = newValue;
    };

    const resetEditModalMessage = () => {
      editModalMessage.shown = false;
      editModalMessage.text = '';
      editModalMessage.className = '';
    };

    return {
      attachToAccentBar,
      onCloseClick,
      onSubmitClick,
      onRecordingPathChange,
      onRecorderStateChange,
      resetEditModalMessage,
    };
  };

  export default {
    name: 'EditActivityNote',
    components: { ModalComponent, FlashBannerComponent, InstructorNoteAudioControls },
    directives: { ckeditor },
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    emits: ['close', 'update'],
    setup(props, { emit }) {
      const currentNote = reactive({ ...props.note });
      const recordingInProgress = ref(false);
      const editModalMessage = reactive({});
      const allowsExpandedNotes = inject('allowsExpandedNotes');
      const isSubmitDisabled = computed(() => {
        return (currentNote.title === '' && currentNote.body_text === '') || recordingInProgress.value;
      });

      const accentBarComponent = ref(null);
      const refModalContainerElm = ref(null);
      const titleElm = ref(null);

      const {
        attachToAccentBar,
        onCloseClick,
        onSubmitClick,
        onRecordingPathChange,
        onRecorderStateChange,
        resetEditModalMessage,
      } = useEditModal(
        accentBarComponent,
        emit,
        currentNote,
        editModalMessage,
        recordingInProgress,
        refModalContainerElm,
        titleElm
      );

      onMounted(() => {
        attachToAccentBar();
      });

      return {
        allowsExpandedNotes,
        currentNote,
        editModalMessage,
        isSubmitDisabled,
        onCloseClick,
        onRecordingPathChange,
        onRecorderStateChange,
        onSubmitClick,
        resetEditModalMessage,
        testClass,
        attachToAccentBar,
        accentBarComponent,
        refModalContainerElm,
        titleElm,
        useCkeditorOptions,
      };
    },
  };
</script>

