<template>
  <tr
    :id="`a11y-add-user-word-form-${unit.id}-${lesson.id}`"
    role="form"
    class="c-row  c-row--vocab-tools  c-table__form-row">
    <td>
      <EditableAttribute
        v-model="userWord.new_target"
        ariaLabeledBy="a11y-foreign-word-label"
        inputFieldType="L2"
        :lesson="lesson"
        :placeholder="targetLanguage"
        viewMode="new"
        wordType="target-word" />
    </td>
    <td v-if="showPinyin">
      <EditableAttribute
        v-model="userWord.new_pinyin"
        ariaLabeledBy="a11y-pinyin-word-label"
        inputFieldType="L2"
        :lesson="lesson"
        placeholder="Pinyin"
        viewMode="new"
        wordType="pinyin-word" />
    </td>
    <td v-if="!isTranslationHidden">
      <EditableAttribute
        v-model="userWord.new_translation"
        ariaLabeledBy="a11y-english-word-label"
        inputFieldType="L1"
        :lesson="lesson"
        placeholder="English"
        viewMode="new"
        wordType="translation-word" />
    </td>
    <td v-if="vocabHasDefinition">
      <EditableAttribute
        v-model="userWord.new_definition"
        ariaLabeledBy="a11y-definition-header"
        inputFieldType="definition"
        :lesson="lesson"
        :placeholder="isTranslationHidden ? 'Notes' : 'Definition'"
        viewMode="new"
        wordType="definition-word" />
    </td>
    <td class="c-table__actions">
      <div class="c-link-group">
        <button
          :disabled="!isUserWordValid(userWord)"
          type="button"
          :aria-controls="`a11y-add-user-word-form-${unit.id}-${lesson.id}`"
          class="c-button  u-pad-8  u-txt-upper"
          :class="[
            ssjrStudent ? 'c-jr-custom-word-button  u-mar-rt-16' : 'u-bord-1  u-bord-gray-d',
            testClass('user-word-add-save'),
            { 'u-bord-0': !(ssjrStudent && isUserWordValid(userWord)) }
          ]"
          @click="onSaveWordClick">
          Save
          <span class="u-screen-reader-only">custom word and close form</span>
        </button>
        <button
          :aria-controls="`a11y-add-user-word-form-${unit.id}-${lesson.id}`"
          type="button"
          class="c-button  u-pad-8  u-txt-upper"
          :class="[
            ssjrStudent ? 'c-jr-custom-word-button  u-mar-rt-16' : 'u-bord-1  u-bord-gray-d',
            testClass('user-word-add-cancel')
          ]"
          @click="cancelAddMode">
          Cancel
          <span class="u-screen-reader-only">adding word and close form</span>
        </button>
      </div>
    </td>
  </tr>
</template>

<script>
  import { metaTagContent, testClass } from 'music';
  import { onMounted, reactive } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import useUserDefinedWord from './use_user_defined_word';
  import EditableAttribute from './EditableAttribute';

  const useNewWord = (
    accentBarComponent,
    detachFromAccentBarEvents,
    emit,
    isTranslationHidden,
    lesson,
    metaData,
    unit,
    userWord
  ) => {
    const url = `/${metaData.programId}/vocab_tools/user_defined_words.json`;

    const cancelAddMode = () => {
      emit('hideAddWord');
      clearUserWordForm();
      if (accentBarComponent) {
        accentBarComponent.deactivateAll();
        detachFromAccentBarEvents({
          target: '.js-target-word-new',
          translation: '.js-translation-word-new',
          definition: '.js-definition-word-new',
        });
      }
    };

    const clearUserWordForm = () => {
      userWord.new_target = null;
      userWord.new_pinyin = null;
      userWord.new_translation = null;
      userWord.new_definition = null;
    };

    const isUserWordValid = () => {
      const shouldEnableSave = isTranslationHidden ? userWord.new_definition : userWord.new_translation;
      return userWord && userWord.new_target && shouldEnableSave;
    };

    const onSaveWordClick = () => {
      createUserWord();
      cancelAddMode();
    };

    const createUserWord = () => {
      if (isTranslationHidden) userWord.new_translation = userWord.new_target;
      const params = {
        lesson_id: lesson.id,
        target: userWord.new_target,
        pinyin: userWord.new_pinyin,
        translation: userWord.new_translation,
        definition: userWord.new_definition,
      };
      ajaxUtils.postToEndpoint(
        url,
        params,
        (data) => {
          data.id ? emit('addWord', { word: data, unitId: unit.id }) : console.log(data);
        }
      );
    };

    return { cancelAddMode, isUserWordValid, onSaveWordClick };
  };

  export default {
    name: 'NewWord',
    components: { EditableAttribute },
    props: {
      isTranslationHidden: { default: false, type: Boolean },
      lesson: { required: true, type: Object },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      unit: { required: true, type: Object },
      vocabHasDefinition: { required: true, type: Boolean },
    },
    emits: ['addWord', 'hideAddWord'],
    setup(props, { emit }) {
      let accentBarComponent;
      const userWord = reactive({
        new_target: null,
        new_pinyin: null,
        new_translation: null,
        new_definition: null,
      });
      if (metaTagContent('VHL.program_accent_bar_enabled') === 'true') {
        accentBarComponent = new VHL.AccentBarComponent();
      }
      const {
        attachToAccentBarEvents,
        detachFromAccentBarEvents,
        metaData,
        registerAccentBar,
        showPinyin,
      } = useUserDefinedWord();
      const {
        cancelAddMode, isUserWordValid, onSaveWordClick,
      } = useNewWord(
        accentBarComponent,
        detachFromAccentBarEvents,
        emit,
        props.isTranslationHidden,
        props.lesson,
        metaData,
        props.unit,
        userWord
      );

      if (accentBarComponent) {
        onMounted(() => {
          registerAccentBar(accentBarComponent);
          attachToAccentBarEvents(
            {
              target: '.js-target-word-new',
              translation: '.js-translation-word-new',
              definition: '.js-definition-word-new',
            },
            userWord
          );
        });
      }

      return {
        cancelAddMode,
        isUserWordValid,
        metaData,
        onSaveWordClick,
        showPinyin,
        testClass,
        userWord,
      };
    },
  };
</script>
