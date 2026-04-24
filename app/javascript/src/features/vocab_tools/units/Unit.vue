<template>
  <div>
    <figure>
      <a class="u-dis-block  u-txt-under" :href="vocabToolsWordPath">
        <img
          class="js-unit-image"
          :class="testClass('unit-image')"
          alt=""
          role="presentation"
          :src="unit.media_item_filename">
        <figcaption
          class="c-gallery__link"
          :class="testClass('gallery-link')"
          :lang="unitLanguageCode"
          :innerHTML="unit.name" />
      </a>
    </figure>
  </div>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'Unit',
    props: {
      unit: { required: true, type: Object },
    },
    setup(props) {
      const currentProgram = inject('currentProgram');
      const vocabToolsWordPath = document.querySelector(`.js-unit-${props.unit.id}`)
        .getAttribute('data-vocab-tools-word-path');

      const unitLanguageCode = computed(() => {
        return props.unit.name?.toLowerCase().includes('news and cultural updates')
          ? 'en'
          : currentProgram.language_code;
      });

      return {
        currentProgram,
        testClass,
        unitLanguageCode,
        vocabToolsWordPath,
      };
    },
  };
</script>
