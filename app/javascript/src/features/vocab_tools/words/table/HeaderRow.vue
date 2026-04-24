<template>
  <tr class="c-header-row  c-header-row--vocab-tools  c-header-row--first">
    <th id="a11y-L2-header" class="c-vocab-th-target" scope="col">
      <div class="c-underbar" :class="testClass('vocab-target-language')">
        {{ targetLanguage }}
      </div>
    </th>
    <th
      v-if="targetLanguage === 'Chinese'"
      id="a11y-pinyin-header"
      class="c-vocab-th-target"
      scope="col">
      <div class="c-underbar">
        Pinyin
      </div>
    </th>
    <th
      v-if="!isTranslationHidden"
      id="a11y-L1-header"
      class="c-vocab-th-source"
      :class="testClass('vocab-translation-language')"
      scope="col"
      :colspan="columnSpanInfo.l1ColumnSpan">
      <div class="c-underbar">
        {{ englishHeaderText }}
      </div>
    </th>
    <th
      v-if="vocabHasDefinition"
      id="a11y-definition-header"
      class="c-vocab-th-definition"
      :class="testClass('vocab-th-definition')"
      scope="col"
      :colspan="columnSpanInfo.definitionColumnSpan">
      <div class="c-underbar">
        {{ isTranslationHidden ? 'Notes' : 'Definition' }}
      </div>
    </th>
  </tr>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'HeaderRow',
    props: {
      isTranslationHidden: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      vocabHasDefinition: { required: true, type: Boolean },
    },
    setup(props) {
      /* In add/edit mode, the column on the right contains save/delete controls.
       * Whichever th (header) element is rightmost must be assigned a colspan
       * of 2 so that it can span both its own column and the column with
       * controls. If there are definitions, the definition header is rightmost.
       * Otherwise, the l1 (i.e., translation) header is rightmost.
       *
       * Also, a program with definitions has 4 columns:
       * target, translation, definition, controls.
       * Otherwise, the total column count is 3.
       *
       * In TranslationHidden mode there are 3 columns
       * target, definition, controls.
       */
      const columnSpanInfo = computed(() => {
        if (props.isTranslationHidden) {
          // Here totalColumns is 3
          return { definitionColumnSpan: 2 };
        }
        if (props.vocabHasDefinition) {
          // Here totalColumns is 4
          return { definitionColumnSpan: 2, l1ColumnSpan: 1 };
        } else {
          // Here totalColumns is 3
          return { l1ColumnSpan: 2 };
        }
      });

      /*
       * This property is just to fix flicker. Earlier the inline text element 'English'
       * was appearing before targetLanguage text element.
       */
      const englishHeaderText = computed(() => props.targetLanguage ? 'English' : '' );
      return { columnSpanInfo, englishHeaderText, testClass };
    },
  };
</script>
