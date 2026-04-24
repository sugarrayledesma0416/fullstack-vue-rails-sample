<template>
  <div v-if="addMode" ref="refModalContainerElm" :class="testClass('instructor-note-modal')">
    <ModalComponent title="Add Instructor Note" @close="onCloseClick">
      <template #body>
        <div v-show="currentNote.note_item_id">
          <FlashBannerComponent :message="addModalMessage" @reset="resetAddModalMessage" />

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
            :disabled="isSubmitDisabled"
            :class="testClass('submit-button')"
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
  import { dispatchCustomEvent } from 'shared/utils';
  import { testClass } from 'music';
  import { computed, reactive, nextTick, ref } from 'vue';
  import ModalComponent from '../modal/ModalComponent';
  import ckeditor from 'shared/directives/ckeditor';
  import FlashBannerComponent from '../flash_banner/FlashBannerComponent';
  import InstructorNoteAudioControls from 'views/instructor_notes/audio_controls/InstructorNoteAudioControls';
  import accentBarHelper from 'shared/accent_bar_helper';
  import useCkeditorOptions from './use_ckeditor_options';

  const useAddModal = (
    activityId,
    accentBarComponent,
    noteItemId,
    programId,
    allowsExpandedNotes,
    addMode,
    addModalMessage,
    currentNote,
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

    const showDialog = (itemId) => {
      noteItemId.value = itemId;
      addMode.value = true;

      nextTick(() => {
        if (titleElm.value) {
          moveAccentBarToRequestModal();
          attachToAccentBarEvents(titleElm.value, currentNote, 'title');
        }
      });
    };

    const hideDialog = () => {
      setDefaultNoteValues();

      if (titleElm.value && accentBarComponent.value) {
        accentBarComponent.value.deactivateAll();
        detachFromAccentBarEvents(titleElm.value);
      }

      addMode.value = false;
      resetAddModalMessage();

      const noteItemElm = document.querySelector(`#${noteItemId.value}`);
      dispatchCustomEvent({
        name: 'unselect_notable',
        detail: noteItemElm,
      });
    };

    const resetAddModalMessage = () => {
      addModalMessage.shown = false;
      addModalMessage.text = '';
      addModalMessage.className = '';
    };

    const onCloseClick = () => {
      hideDialog();
    };

    const getSaveNoteParams = () => ({
      noteVariants: {
        collapsed: { name: 'collapsed', oldName: 'sidebar' },
        expanded: { name: 'expanded', oldName: 'inline' },
      },
      note_type: currentNote.note_type,
      body_text: currentNote.body_text,
      note_item_id: currentNote.note_item_id,
      title: currentNote.title,
      recording_path: currentNote.recording_path,
    });

    const setDefaultNoteValues = () => {
      currentNote.note_type = allowsExpandedNotes ? 'expanded' : 'collapsed';
      currentNote.body_text = '';
      currentNote.note_item_id = noteItemId;
      currentNote.title = '';
      currentNote.recording_path = '';
    };

    const onSuccess = (data) => {
      setDefaultNoteValues();
      hideDialog();
      dispatchCustomEvent({
        name: 'activityNoteAdded',
        detail: { note: data },
      });
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: 'Note successfully saved!' },
      });
    };

    const onError = (data) => {
      addModalMessage.shown = true;
      addModalMessage.text = data;
      addModalMessage.className = 'error';
    };

    const onSubmitClick = () => {
      /* Set title if emplty */
      if (currentNote.title === '') {
        currentNote.title = 'Instructor Note.';
      }

      const params = getSaveNoteParams();
      const url = `/instructor/${programId}/activity/${activityId}/activity_notes`;
      ajaxUtils.postToEndpoint(
        url,
        params,
        (data) => {
          data.id ? onSuccess(data) : onError(data);
        }
      );
    };

    const onRecordingPathChange = (newRecordingPath) => {
      currentNote.recording_path = newRecordingPath;
    };

    const onRecorderStateChange = (newValue) => {
      recordingInProgress.value = newValue;
    };

    return {
      showDialog,
      setDefaultNoteValues,
      resetAddModalMessage,
      onCloseClick,
      onSubmitClick,
      onRecordingPathChange,
      onRecorderStateChange,
    };
  };

  export default {
    name: 'AddActivityNote',
    components: { ModalComponent, FlashBannerComponent, InstructorNoteAudioControls },
    directives: { ckeditor },
    props: {
      activityId: { required: true, type: Number },
      programId: { required: true, type: Number },
      allowsExpandedNotes: { required: true, type: Boolean },
    },
    setup(props) {
      const addMode = ref(false);
      const refModalContainerElm = ref(null);
      const titleElm = ref(null);
      const accentBarComponent = ref(null);
      const { activityId } = props;
      const { programId } = props;
      const { allowsExpandedNotes } = props;
      const noteItemId = ref('');

      const currentNote = reactive({});
      const recordingInProgress = ref(false);
      const isSubmitDisabled = computed(() => {
        return (currentNote.title === '' && currentNote.body_text === '') || recordingInProgress.value;
      });
      const addModalMessage = reactive({
        shown: false,
        text: '',
        className: '',
      });

      const {
        showDialog,
        setDefaultNoteValues,
        resetAddModalMessage,
        onCloseClick,
        onSubmitClick,
        onRecordingPathChange,
        onRecorderStateChange,
      } = useAddModal(
        activityId,
        accentBarComponent,
        noteItemId,
        programId,
        allowsExpandedNotes,
        addMode,
        addModalMessage,
        currentNote,
        recordingInProgress,
        refModalContainerElm,
        titleElm
      );

      setDefaultNoteValues();

      return {
        addModalMessage,
        addMode,
        allowsExpandedNotes,
        currentNote,
        isSubmitDisabled,
        onCloseClick,
        onRecordingPathChange,
        onRecorderStateChange,
        onSubmitClick,
        resetAddModalMessage,
        showDialog,
        testClass,
        accentBarComponent,
        refModalContainerElm,
        titleElm,
        useCkeditorOptions,
      };
    },
  };
</script>
