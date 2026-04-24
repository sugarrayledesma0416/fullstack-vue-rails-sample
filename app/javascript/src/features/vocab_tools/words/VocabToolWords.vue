<template>
  <div class="l-grid">
    <aside class="l-col-md-4  c-word-filter-wrapper  c-word-filter-wrapper--full-below-md  u-mar-bot-32">
      <h2 class="u-screen-reader-only">
        Word Filter
      </h2>
      <WordFilter
        v-bind="getWordFilterProps()"
        @retrieveLesson="retrieveLesson"
        @toggleLessonSelection="toggleLessonSelection"
        @toggleTopicSelection="toggleTopicSelection" />
      <div class="u-txt-ctr" v-if="vocabToolsDataStore.enrolled && !vocabToolsDataStore.ssjrStudent">
        <button
          v-if="vocabToolsDataStore.viewAllLessons"
          class="c-button  u-bord-1  u-bord-gray-d  u-pad-lt-16  u-pad-rt-16  u-mar-bot-4"
          @click="viewOnlyLessonsInCourse">
          View only lessons for this course
        </button>
        <button
          v-else
          class="c-button  u-bord-1  u-bord-gray-d  u-pad-lt-16  u-pad-rt-16  u-mar-bot-4"
          @click="viewAllLessonsInProgram">
          View all lessons in this program
        </button>
      </div>
    </aside>
    <div class="l-col-md-8  c-main-content  c-main-content--full-below-md">
      <div>
        <h2 class="u-screen-reader-only">
          Customizable Vocabulary List
        </h2>
        <VocabTabs :ssjrStudent="vocabToolsDataStore.ssjrStudent">
          <template #flashcards>
            <FlashcardLayout
              v-if="vocabToolsDataStore.targetLanguage"
              :isTranslationHidden="vocabToolsDataStore.isTranslationHidden"
              :ssjrStudent="vocabToolsDataStore.ssjrStudent"
              :targetLanguage="vocabToolsDataStore.targetLanguage"
              :vocabHasDefinition="vocabToolsDataStore.vocabHasDefinition" />
          </template>
          <template #vocabulary>
            <span id="a11y-foreign-word-label" class="u-screen-reader-only">
              {{ vocabToolsDataStore.targetLanguage }} word
            </span>
            <span id="a11y-english-word-label" class="u-screen-reader-only">
              English word
            </span>
            <div class="c-form  c-form--vocab  js-vocab-tools-word-table">
              <WordTable
                v-bind="getWordTableProps()"
                @addWord="addUserWord"
                @removeWord="removeUserWord"
                @updateWord="updateUserWord" />
            </div>
          </template>
        </VocabTabs>
      </div>
    </div>
  </div>
</template>

<script>
  import { computed, onMounted, provide } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import Deck from 'models/vocab_tools/deck';
  import FlashcardLayout from 'features/dictionary_flashcards/FlashcardLayout';
  import VocabTabs from './VocabTabs';
  import WordFilter from 'features/vocab_tools/words/toc/WordFilter';
  import WordTable from 'features/vocab_tools/words/table/WordTable';
  import useWordFilterModelAdaptor from './toc/use_word_filter_model_adaptor';
  import useWordTableModelAdaptor from './table/use_word_table_model_adaptor';
  import VocabToolsDataStore from './models/vocab_tools_data_store';

  export default {
    name: 'VocabToolWords',
    components: {
      FlashcardLayout, VocabTabs, WordFilter, WordTable,
    },
    setup() {
      const setTargetLanguage = (targetLanguage) => {
        VHL.VocabTools.currentTargetLanguage = targetLanguage;
      };

      // This has reactive properties and stores vocab tools app state
      const vocabToolsDataStore = new VocabToolsDataStore(setTargetLanguage);

      // Deck needs to be recalculated whenever 'vocabToolsDataStore.units' changes
      const deck = computed(() => {
        const viewAllLessons = vocabToolsDataStore.viewAllLessons;
        const filteredUnits = vocabToolsDataStore.units.filter((unit) => {
          return viewAllLessons || unit.inCourse;
        });
        return new Deck(filteredUnits, 'units');
      });
      provide('deck', deck);

      const {
        getWordFilterProps,
        retrieveLesson,
        toggleLessonSelection,
        toggleTopicSelection,
        viewAllLessonsInProgram,
        viewOnlyLessonsInCourse,
      } = useWordFilterModelAdaptor(vocabToolsDataStore);

      const {
        addUserWord,
        getWordTableProps,
        removeUserWord,
        updateUserWord,
      } = useWordTableModelAdaptor(vocabToolsDataStore);

      onMounted(() => {
        vocabToolsDataStore.targetLanguageCode = metaTagContent('VHL.program_language');
      });

      return {
        addUserWord,
        getWordFilterProps,
        getWordTableProps,
        vocabToolsDataStore,
        removeUserWord,
        retrieveLesson,
        toggleLessonSelection,
        toggleTopicSelection,
        updateUserWord,
        viewAllLessonsInProgram,
        viewOnlyLessonsInCourse,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-word-filter-wrapper {
    margin-top: rpx(48);
  }

  @include viewport-max(md) {
    .c-word-filter-wrapper--full-below-md {
      width: 100%;
    }

    .c-main-content--full-below-md {
      width: 100%;
    }
  }
</style>
