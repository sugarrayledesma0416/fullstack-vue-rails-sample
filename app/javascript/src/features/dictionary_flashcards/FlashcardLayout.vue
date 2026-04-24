<template>
  <div>
    <h2 class="u-screen-reader-only">
      Vocabulary Flashcards
    </h2>
    <FlashcardStart
      v-if="!activityStarted"
      :ssjrStudent="ssjrStudent"
      :studyOptions="studyOptions"
      @startActivity="startActivity" />
    <div
      v-else-if="deck.flashcards.length === 0"
      :class="testClass('no-flashcard')">
      <div v-if="ssjrStudent">
        <NoWordSelected :class="testClass('no-word-selected')" />
      </div>
      <div v-else>
        Select a lesson or topic to see flashcards.
      </div>
    </div>
    <div v-else>
      <FlashcardComponent
        :class="testClass('flashcard-component')"
        :modes="modes"
        :mode="studyOptions.mode"
        :ssjrStudent="ssjrStudent" />
    </div>
  </div>
</template>

<script>
  import { inject, reactive, ref, watch } from 'vue';
  import { testClass } from 'music';
  import FlashcardComponent from './FlashcardComponent';
  import FlashcardStart from './FlashcardStart';
  import NoWordSelected from 'features/vocab_tools/words/NoWordSelected.vue';

  const useFlashcardLayout = (activityStarted, modes, props, translationLanguage) => {
    /**
     * @private
     * Creates and returns array of options for study-mode dropdown.
     * @return {Array.<{label: string, value: number}>} array of option objects
     */
    const getModeOptions = () => {
      /** Create and return option for study-mode dropdown
       * @param {String} frontName
       * @param {String} backName
       * @param {String} modeName
       * @return {Object}
       */
      const createModeOption = (frontName, backName, modeName) => {
        return {
          label: `${frontName} to ${backName}`,
          value: modes[modeName],
        };
      };

      // if no definition is available, use only the first two options;
      // otherwise use all three
      if (props.isTranslationHidden) {
        return [
          createModeOption(props.targetLanguage, 'Notes', 'TARGET_TO_DEFINITION'),
          createModeOption('Notes', props.targetLanguage, 'DEFINITION_TO_TARGET'),
        ];
      } else {
        return [
          createModeOption(props.targetLanguage, translationLanguage, 'TARGET_TO_TRANSLATION'),
          createModeOption(translationLanguage, props.targetLanguage, 'TRANSLATION_TO_TARGET'),
          createModeOption('Definition', props.targetLanguage, 'DEFINITION_TO_TARGET'),
        ].slice(0, props.vocabHasDefinition ? 3 : 2);
      }
    };

    const startActivity = () => {
      activityStarted.value = true;
    };

    return { getModeOptions, startActivity };
  };

  export default {
    name: 'FlashcardLayout',
    components: { FlashcardComponent, FlashcardStart, NoWordSelected },
    props: {
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      vocabHasDefinition: { default: false, type: Boolean },
      isTranslationHidden: { default: false, type: Boolean },
    },
    emits: [],
    setup(props) {
      const activityStarted = ref(false);
      const deck = inject('deck');
      let modes;
      let defaultMode;
      let translationLanguage;

      if (props.isTranslationHidden) {
        modes = {
          TARGET_TO_DEFINITION: 0,
          DEFINITION_TO_TARGET: 1,
        };
        defaultMode = 'TARGET_TO_DEFINITION';
      } else {
        modes = {
          TARGET_TO_TRANSLATION: 0,
          TRANSLATION_TO_TARGET: 1,
          DEFINITION_TO_TARGET: 2,
        };
        translationLanguage = 'English';
        defaultMode = 'TARGET_TO_TRANSLATION';
      }

      const { getModeOptions, startActivity } = useFlashcardLayout(activityStarted, modes, props, translationLanguage);

      const studyOptions = reactive({
        mode: modes[defaultMode],
        modeOptions: getModeOptions(),
      });

      if (deck.value) {
        watch(deck, (newValue, oldValue) => {
          const newWords = JSON.stringify(newValue.allWords);
          const oldWords = JSON.stringify(oldValue.allWords);
          if (newWords !== oldWords) {
            activityStarted.value = false;
            oldValue.stopAllAudio();
          }
        });
      }

      return {
        activityStarted, deck, modes, startActivity, studyOptions, testClass,
      };
    },
  };
</script>
