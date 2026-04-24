<template>
  <!--
    WordTable for non-supersite-junior programs has different html structure then WordTableJr.
    Some of the points to differentiate with WordTableJr are following:
    - There is a single <table> element having all the lesson's words.
      Each lessons' words are grouped via some css only.
    - Table has header eg "Spanish"/"Notes" etc via <HeaderRow>
    - Row dividers are displayed via border css in <tr>/<td> etc.
  -->
  <div class="c-word-table-wrapper">
    <CommonHeader
      class="u-mar-bot-0"
      :isTranslationHidden="isTranslationHidden"
      :targetLanguage="targetLanguage"
      :totalColumns="totalColumns"
      :vocabHasDefinition="vocabHasDefinition" />

    <template
      v-for="({ lesson, unit }, lessonIndex) in lessonsWithUnitInfo"
      :key="`${unit.id}-${lesson.id}`">
      <div class="c-lesson-meta">
        <LessonHeaderRow
          :lesson="lesson"
          :targetLanguageCode="targetLanguageCode" />
        <AddWordIcon
          v-if="lessonIdForAddWord !== lesson.id"
          :lesson="lesson"
          :unit="unit"
          @showAddWord="updateLessonIdForAddWord($event)" />
      </div>

      <table 
        class="c-table  c-table--vocab-tools  u-bord-top-0"
        :class="testClass('table-vocab-tools-words')">
        <WordTableCaption
          :isTranslationHidden="isTranslationHidden"
          :lessonName="lesson.name"
          :tableNumber="lessonIndex + 1"
          :tableCount="lessonsWithUnitInfo.length"
          :targetLanguage="targetLanguage"
          :vocabHasDefinition="vocabHasDefinition" />

        <tbody>
          <NewWord
            v-if="lessonIdForAddWord === lesson.id"
            :ssjrStudent="ssjrStudent"
            :isTranslationHidden="isTranslationHidden"
            :lesson="lesson"
            :targetLanguage="targetLanguage"
            :unit="unit"
            :vocabHasDefinition="vocabHasDefinition"
            @addWord="$emit('addWord', $event)"
            @hideAddWord="resetLessonIdForAddWord()" />

          <EditWord
            v-for="(word, wordIndex) in orderByHeadword(lesson.selectedWords)"
            :key="word.id"
            :index="wordIndex"
            :isTranslationHidden="isTranslationHidden"
            :lesson="lesson"
            :targetLanguage="targetLanguage"
            :targetLanguageCode="targetLanguageCode"
            :unit="unit"
            :vocabHasDefinition="vocabHasDefinition"
            :word="word"
            @cancelEditMode="resetWordInEdit($event)"
            @removeWord="$emit('removeWord', $event)"
            @startEditMode="setWordInEdit($event)"
            @updateWord="$emit('updateWord', $event)" />
        </tbody>
      </table>
    </template>
  </div>
</template>

<script>
  import { reactive, ref } from 'vue';
  import { testClass } from 'music';
  import AddWordIcon from 'features/vocab_tools/words/word_controls/AddWordIcon';
  import NewWord from 'features/vocab_tools/words/word_controls/NewWord';
  import EditWord from 'features/vocab_tools/words/word_controls/EditWord';
  import HeaderRow from 'features/vocab_tools/words/table/HeaderRow';
  import WordTableCaption from 'features/vocab_tools/words/table/WordTableCaption';
  import LessonHeaderRow from 'features/vocab_tools/words/table/LessonHeaderRow';
  import useWordList from './use_word_list';
  import useWordTable from './use_word_table';
  import CommonHeader from 'features/vocab_tools/words/table/CommonHeader';

  export default {
    name: 'WordTableSr',
    components: { AddWordIcon, EditWord, HeaderRow, LessonHeaderRow, NewWord, WordTableCaption, CommonHeader },
    props: {
      isTranslationHidden: { default: false, type: Boolean },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      targetLanguageCode: { required: true, type: String },
      units: { required: true, type: Array },
      viewAllLessons: { default: false, type: Boolean },
      vocabHasDefinition: { required: true, type: Boolean },
    },
    emits: ['addWord', 'removeWord', 'updateWord'],
    setup(props) {
      const lessonIdForAddWord = ref(null);
      const wordInEdit = reactive({ word: null });

      const { hasSelectedWords, orderByHeadword } = useWordList();
      const {
        lessonsWithUnitInfo,
        resetLessonIdForAddWord,
        resetWordInEdit,
        setWordInEdit,
        totalColumns,
        updateLessonIdForAddWord,
      } = useWordTable(lessonIdForAddWord, props, wordInEdit);

      return {
        lessonIdForAddWord,
        lessonsWithUnitInfo,
        orderByHeadword,
        resetLessonIdForAddWord,
        resetWordInEdit,
        setWordInEdit,
        testClass,
        totalColumns,
        updateLessonIdForAddWord,
        wordInEdit,
      };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .list_lesson {
    border-right: rpx(1) solid $gray-d;
  }
</style>
