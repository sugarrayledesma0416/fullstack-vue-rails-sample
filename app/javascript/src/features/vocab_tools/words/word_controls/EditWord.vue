<template>
  <tr
    :id="editUserWordId"
    class="c-row  c-row--vocab-tools">
    <td>
      <button
        v-if="userDefinedWord.topic === 'My Words'"
        type="button"
        :aria-controls="editUserWordId"
        :aria-expanded="userDefinedWord.isEditMode ? 'true' : 'false'"
        class="c-link  c-no-button  u-float-lt  test-user-word-edit  u-mar-lt-neg-24"
        :class="{ 'u-pad-top-5': ssjrStudent }"
        @click="toggleEditMode">
        <MusicIcon
          variant="edit"
          size="md"
          :class="testClass('music-icon-edit')"
          aria-hidden="true" />
        <span id="a11y-edit-word-form-label" class="u-screen-reader-only">
          {{ userDefinedWord.isEditMode ? 'Cancel' : '' }} Edit Word
        </span>
      </button>
      <EditableAttribute
        :modelValue="word.target"
        ariaLabeledBy="a11y-foreign-word-label"
        inputFieldType="L2"
        :ssjrStudent="ssjrStudent"
        :userDefinedWord="userDefinedWord"
        viewMode="edit"
        wordType="target-word"
        @input="userDefinedWord.new_target = $event.target.value" />
    </td>
    <td v-if="showPinyin">
      <EditableAttribute
        :modelValue="word.pinyin"
        ariaLabeledBy="a11y-pinyin-word-label"
        inputFieldType="L2"
        :userDefinedWord="userDefinedWord"
        viewMode="edit"
        wordType="pinyin-word"
        @input="userDefinedWord.new_pinyin = $event.target.value" />
    </td>
    <td v-if="!isTranslationHidden" :colspan="columnSpanInfo.l1ColumnSpan">
      <EditableAttribute
        :modelValue="word.translation"
        ariaLabeledBy="a11y-english-word-label"
        inputFieldType="L1"
        :userDefinedWord="userDefinedWord"
        viewMode="edit"
        wordType="translation-word"
        @input="userDefinedWord.new_translation = $event.target.value" />
    </td>
    <td v-if="vocabHasDefinition" :colspan="columnSpanInfo.definitionColumnSpan">
      <EditableAttribute
        :modelValue="word.definition"
        ariaLabeledBy="a11y-definition-header"
        inputFieldType="definition"
        :userDefinedWord="userDefinedWord"
        viewMode="edit"
        wordType="definition-word"
        @input="userDefinedWord.new_definition = $event.target.value" />
    </td>
    <td v-if="userDefinedWord.isEditMode" class="c-table__actions">
      <div class="c-link-group">
        <button
          :disabled="!isEditedWordValid()"
          :aria-controls="editUserWordId"
          type="button"
          class="c-button  u-pad-8  u-txt-upper"
          :class="[
            ssjrStudent ? 'c-jr-custom-word-button  u-mar-rt-16' : 'u-bord-1  u-bord-gray-d',
            testClass('user-word-edit-save'),
            { 'u-bord-0': !(ssjrStudent && isEditedWordValid()) }
          ]"
          @click="updateUserWord">
          save <span class="u-screen-reader-only">changes and close form</span>
        </button>
        <button
          :aria-controls="editUserWordId"
          type="button"
          class="c-button  u-pad-8  u-txt-upper"
          :class="[
            ssjrStudent ? 'c-jr-custom-word-button  u-mar-rt-16' : 'u-bord-1  u-bord-gray-d',
            testClass('user-word-delete')
          ]"
          @click="showDeleteConfirmation">
          delete <span class="u-screen-reader-only">custom word and close form</span>
        </button>
      </div>
    </td>
    <BasicDialog
      v-if="confirmDeleteModal.value"
      class="confirmation-delete-modal--no-min-width"
      :isConfirmationDialog="true"
      labelledBy="confirm-delete-modal-label"
      role="alert"
      ariaLive="assertive"
      :title="`Do you want to delete ${word.target}`">
      <template #body>
        <h1 id="confirm-delete-modal-label" class="c-heading c-heading--md ng-binding">
          Do you want to delete <span :lang="targetLanguageCode">{{ word.target }}</span>?
        </h1>
      </template>
      <template #footer>
        <div class="c-button-group  c-button-group--ctr  c-button-group--reverse  confirm-btns">
          <button
            class="c-button
                     confirm-yes  test-confirm-yes
                     ng-binding  js-dialog-a11y__default-focus
                     js-dialog-a11y__first-focus-elm"
            :class="ssjrStudent
              ? 'c-jr-custom-word-button  u-mar-rt-16'
              : 'c-button--primary'"
            @click="confirmAndRemoveUserWord(lesson)">
            Yes
          </button>
          <button
            class="c-button
                     confirm-no  test-confirm-no
                     ng-binding  js-dialog-a11y__last-focus-elm"
            :class="{ 'c-jr-custom-word-button': ssjrStudent }"
            @click="closeConfirmDialog">
            No
          </button>
        </div>
      </template>
    </BasicDialog>
  </tr>
</template>

<script>
  import { metaTagContent, testClass } from 'music';
  import { computed, nextTick, provide, reactive } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import EditableAttribute from './EditableAttribute';
  import MusicIcon from 'shared/vue/MusicIcon';
  import BasicDialog from 'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import useUserDefinedWord from './use_user_defined_word';

  const useInputWord = (
    attachToAccentBarEvents,
    confirmDeleteModal,
    detachFromAccentBarEvents,
    emit,
    isTranslationHidden,
    lesson,
    metaData,
    registerAccentBar,
    unit,
    word
  ) => {
    const cancelEditMode = () => {
      word.isEditMode = false;
      if (word.accentBarComponent) {
        word.accentBarComponent.deactivateAll();
        detachFromAccentBarEvents({
          target: `.js-target-word-edit-${word.id}`,
          translation: `.js-translation-word-edit-${word.id}`,
          definition: `.js-definition-word-edit-${word.id}`,
        });
      }
      document.querySelector(`.js-lesson-${lesson.id}-add-word`)?.focus();
      emit('cancelEditMode');
    };

    const updateUserWord = () => {
      if (isTranslationHidden) word.new_translation = word.new_target;
      const params = {
        target: word.new_target,
        pinyin: word.new_pinyin,
        translation: word.new_translation,
        definition: word.new_definition,
      };
      const url = `/${metaData.programId}/vocab_tools/user_defined_words/${word.id}.json`;
      ajaxUtils.putToEndpoint(
        url,
        params,
        (data) => {
          data.status === 200 ? onUpdateSuccess() : console.log(data);
        }
      );
    };

    const onUpdateSuccess = () => {
      word.target = word.new_target;
      word.pinyin = word.new_pinyin;
      word.translation = word.new_translation;
      word.definition = word.new_definition;

      emit('updateWord', { word: emitData(), unitId: unit.id, lessonId: lesson.id });
      cancelEditMode();
    };

    const isEditedWordValid = () => {
      const shouldEnableSave = isTranslationHidden ? word.new_definition : word.new_translation;
      return word && word.new_target && shouldEnableSave;
    };

    const showDeleteConfirmation = () => {
      confirmDeleteModal.value = true;
    };

    const confirmAndRemoveUserWord = (lesson) => {
      const url = `/${metaData.programId}/vocab_tools/user_defined_words/${word.id}.json`;
      ajaxUtils.deleteFromEndpoint(
        url,
        (data) => {
          if (data.status === 200) {
            emit('removeWord', { word: emitData(), unitId: unit.id, lessonId: lesson.id });
            closeConfirmDialog();
          } else {
            console.log(data);
          }
        }
      );
    };

    const closeConfirmDialog = () => {
      confirmDeleteModal.value = false;
      cancelEditMode();
    };

    const toggleEditMode = () => {
      if (word.isEditMode) {
        cancelEditMode();
      } else {
        startEditingWord();
      }
    };

    const startEditingWord = () => {
      if (word.topic === 'My Words') {
        emit('startEditMode', word);
        word.isEditMode = true;
        if (word.accentBarComponent) {
          nextTick(() => {
            registerAccentBar(word.accentBarComponent);
            attachToAccentBarEvents(
              {
                target: `.js-target-word-edit-${word.id}`,
                translation: `.js-translation-word-edit-${word.id}`,
                definition: `.js-definition-word-edit-${word.id}`,
              },
              word
            );
          });
        }
      }
    };

    const emitData = () => {
      return {
        ascii: word.ascii,
        definition: word.definition,
        id: word.id,
        isEditMode: word.isEditMode,
        pinyin: word.pinyin,
        target: word.target,
        topic: word.topic,
        translation: word.translation,
      };
    };

    return {
      closeConfirmDialog, confirmAndRemoveUserWord, isEditedWordValid,
      showDeleteConfirmation, startEditingWord, toggleEditMode, updateUserWord,
    };
  };

  export default {
    name: 'EditWord',
    components: { EditableAttribute, BasicDialog, MusicIcon },
    props: {
      index: { required: true, type: Number },
      isTranslationHidden: { default: false, type: Boolean },
      lesson: { required: true, type: Object },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      targetLanguageCode: { type: String, default: '' },
      unit: { required: true, type: Object },
      vocabHasDefinition: { required: true, type: Boolean },
      word: { required: true, type: Object },
    },
    emits: ['cancelEditMode', 'removeWord', 'startEditMode', 'updateWord'],
    setup(props, { emit }) {
      const userDefinedWord = reactive(props.word);
      userDefinedWord.isEditMode = false;
      if (metaTagContent('VHL.program_accent_bar_enabled') === 'true') {
        userDefinedWord.accentBarComponent = new VHL.AccentBarComponent();
      }
      userDefinedWord.new_target = userDefinedWord.target;
      userDefinedWord.new_pinyin = userDefinedWord.pinyin;
      userDefinedWord.new_translation = userDefinedWord.translation;
      userDefinedWord.new_definition = userDefinedWord.definition;

      const editUserWordId = `
        a11y-edit-user-word-${props.index}-form-${props.unit.id}-${props.lesson.id}
      `;
      const confirmDeleteModal = reactive({ value: false });
      const {
        attachToAccentBarEvents,
        detachFromAccentBarEvents,
        metaData,
        registerAccentBar,
        showPinyin,
      } = useUserDefinedWord();

      const {
        closeConfirmDialog,
        confirmAndRemoveUserWord,
        isEditedWordValid,
        showDeleteConfirmation,
        startEditingWord,
        toggleEditMode,
        updateUserWord,
      } = useInputWord(
        attachToAccentBarEvents,
        confirmDeleteModal,
        detachFromAccentBarEvents,
        emit,
        props.isTranslationHidden,
        props.lesson,
        metaData,
        registerAccentBar,
        props.unit,
        userDefinedWord
      );

      provide('startEditingWord', startEditingWord);

      const columnSpanInfo = computed(() => {
        if (userDefinedWord.isEditMode) {
          return {};
        }

        const { isTranslationHidden, vocabHasDefinition } = props;

        if (isTranslationHidden) {
          return { definitionColumnSpan: 2 };
        }

        return vocabHasDefinition
          ? { definitionColumnSpan: 2, l1ColumnSpan: 1 }
          : { l1ColumnSpan: 2 };
      });

      return {
        closeConfirmDialog,
        columnSpanInfo,
        confirmAndRemoveUserWord,
        confirmDeleteModal,
        editUserWordId,
        isEditedWordValid,
        metaData,
        showDeleteConfirmation,
        showPinyin,
        testClass,
        toggleEditMode,
        updateUserWord,
        userDefinedWord,
      };
    },
  };
</script>
<style lang="scss" scoped>
  .confirmation-delete-modal--no-min-width {
    min-width: 100%;
  }
</style>
