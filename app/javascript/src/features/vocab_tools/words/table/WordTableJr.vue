<template>
  <!--
    WordTable for Supersite Junior programs has different html structure based on ssjrStudent prop.
    Some of the differences from existing html ie. WordTableSr are as follows:
    - It has a separate <table> for each lesson's words. (For rounded tables)
    - New row divider element is added via <RowDivider>. (For row divider width
      should be less than table width)
    - Column header eg "Spanish"/"Notes" etc are moved out of tables and into <CommonHeader>
    - Each table's columns width is independent across table so use fixed % width
      for all tables via <ColumnsLayout>
    - Everything is wrapped in a rounded container.

    NOTE:
      This table component can potentially support the ui for non-supersite-junior programs as well
      via css, except some regressions. (eg fixed % width columns now vs self-adjusting width)
  -->
  <div
    class="c-word-table-wrapper"
    :class="{
      'c-box' : ssjrStudent,
      'c-box--bubble-wrap' : ssjrStudent
    }">
    <CommonHeader
      :isTranslationHidden="isTranslationHidden"
      :ssjrStudent="ssjrStudent"
      :targetLanguage="targetLanguage"
      :totalColumns="totalColumns"
      :vocabHasDefinition="vocabHasDefinition" />

    <div
      v-for="({ lesson, unit }, lessonIndex) in lessonsWithUnitInfo"
      :key="`${unit.id}-${lesson.id}`"
      class="c-lesson-wrapper">

      <ColumnsLayout :totalColumns="totalColumns" />
      <div class="c-lesson-meta">
        <LessonHeaderRow
          :lesson="lesson"
          :targetLanguageCode="targetLanguageCode" />
        <AddWordIcon
          v-if="lessonIdForAddWord !== lesson.id"
          :lesson="lesson"
          :ssjrStudent="ssjrStudent"
          :unit="unit"
          @showAddWord="updateLessonIdForAddWord($event)" />
      </div>

      <table
        class="c-table  c-table--vocab-tools  u-bord-top-0  u-mar-bot-0"
        :class="testClass('table-vocab-tools-lesson-words')">
        <WordTableCaption
          :isTranslationHidden="isTranslationHidden"
          :lessonName="lesson.name"
          :tableNumber="lessonIndex + 1"
          :tableCount="lessonsWithUnitInfo.length"
          :targetLanguage="targetLanguage"
          :vocabHasDefinition="vocabHasDefinition" />
        <tbody class="list_lesson">
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

          <RowDivider
            v-if="ssjrStudent"
            :colspan="totalColumns" />

          <template
            v-for="(word, wordIndex) in orderByHeadword(lesson.selectedWords)"
            :key="word.id">
            <EditWord
              :index="wordIndex"
              :isTranslationHidden="isTranslationHidden"
              :lesson="lesson"
              :ssjrStudent="ssjrStudent"
              :targetLanguage="targetLanguage"
              :unit="unit"
              :vocabHasDefinition="vocabHasDefinition"
              :word="word"
              @cancelEditMode="resetWordInEdit($event)"
              @removeWord="$emit('removeWord', $event)"
              @startEditMode="setWordInEdit($event)"
              @updateWord="$emit('updateWord', $event)" />

            <RowDivider v-if="ssjrStudent" :colspan="totalColumns" />
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
  import { reactive, ref } from 'vue';
  import { testClass } from 'music';
  import AddWordIcon from 'features/vocab_tools/words/word_controls/AddWordIcon';
  import NewWord from 'features/vocab_tools/words/word_controls/NewWord';
  import EditWord from 'features/vocab_tools/words/word_controls/EditWord';
  import LessonHeaderRow from 'features/vocab_tools/words/table/LessonHeaderRow';
  import CommonHeader from 'features/vocab_tools/words/table/CommonHeader';
  import RowDivider from 'features/vocab_tools/words/table/RowDivider';
  import ColumnsLayout from 'features/vocab_tools/words/table/ColumnsLayout';
  import WordTableCaption from 'features/vocab_tools/words/table/WordTableCaption';
  import useWordList from './use_word_list';
  import useWordTable from './use_word_table';

  export default {
    name: 'WordTableJr',
    components: {
      AddWordIcon,
      ColumnsLayout,
      CommonHeader,
      EditWord,
      LessonHeaderRow,
      NewWord,
      RowDivider,
      WordTableCaption,
    },
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

<style scoped lang="scss">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $table-border-radius: rpx(8);

  .c-lesson-wrapper {
    border: rpx(1) solid $gray-d;
    border-radius: $table-border-radius;
    margin-bottom: rpx(12);
  }

  .c-lesson-meta {
    border-top-left-radius: $table-border-radius;
    border-top-right-radius: $table-border-radius;
  }
</style>
