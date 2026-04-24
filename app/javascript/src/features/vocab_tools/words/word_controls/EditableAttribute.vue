<template>
  <div>
    <div
      v-if="!isBeingEdited"
      :class="[
        {'u-pad-lt-8': ssjrStudent},
        testClass(wordType)
      ]"
      :lang="lang"
      @click="startEditingWord()">
      {{ modelValue }}
    </div>
    <div
      v-else
      class="c-form-item"
      :class="testClass('form-item')">
      <input
        :required="!['pinyin-word', 'definition-word'].includes(wordType)"
        type="text"
        :aria-labelledby="ariaLabeledBy"
        :placeholder="placeholder"
        class="c-form-item__input  u-no-min-width  u-width-full  js-word-form-input"
        :class="inputTestClass()"
        :lang="lang"
        :value="modelValue"
        @input="$emit('update:modelValue', $event.target.value)">
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { computed, inject } from 'vue';
  import useUserDefinedWord from './use_user_defined_word';

  export default {
    name: 'EditableAttribute',
    props: {
      ariaLabeledBy: { required: true, type: String },
      inputFieldType: { required: true, type: String },
      lesson: { type: Object, default: null },
      modelValue: { type: String, default: null },
      placeholder: { type: String, default: null },
      ssjrStudent: { type: Boolean, default: false },
      userDefinedWord: { type: Object, default: null },
      viewMode: { required: true, type: String },
      wordType: { required: true, type: String },
    },
    emits: ['update:modelValue'],
    setup(props) {
      let startEditingWord;
      if (props.viewMode === 'edit') {
        startEditingWord = inject('startEditingWord');
      }
      const { metaData } = useUserDefinedWord();

      const inputTestClass = () => {
        const inputClasses = {};
        if (props.viewMode === 'new') {
          inputClasses.test = testClass(`lesson-${props.lesson.id}-new-${props.inputFieldType}`);
          inputClasses.js = `js-${props.wordType}-${props.viewMode}`;
        } else {
          inputClasses.test = testClass(`edit-${props.userDefinedWord.id}-${props.inputFieldType}`);
          inputClasses.js = `js-${props.wordType}-${props.viewMode}-${props.userDefinedWord.id}`;
        }
        return `${inputClasses.test}  ${inputClasses.js}`;
      };

      const isBeingEdited = computed(
        () => {
          if (props.viewMode === 'edit') {
            return props.userDefinedWord.isEditMode;
          } else {
            return true;
          }
        }
      );

      const lang = (props.wordType === 'pinyin-word' ? 'zh-Latn' :
        props.wordType === 'target-word' ? metaData.targetLanguageCode : 'en');

      return {
        inputTestClass,
        isBeingEdited,
        lang,
        metaData,
        startEditingWord,
        testClass,
      };
    },
  };
</script>
