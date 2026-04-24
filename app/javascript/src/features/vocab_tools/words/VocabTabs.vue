<template>
  <div :class="{ 'c-jr-vocab-tabs': ssjrStudent }">
    <TabSet label="vocabulary tools tabs">
      <TabSetTab label="Vocabulary">
        <slot name="vocabulary" />
      </TabSetTab>
      <TabSetTab label="Flashcards">
        <slot name="flashcards" />
      </TabSetTab>
      <template v-if="tabs[0].selected" #print>
        <div class="c-print-tab  u-mar-auto  u-mar-rt-0">
          <button
            class="c-no-button  c-print-button"
            :class="{ 'u-txt-16': !ssjrStudent }"
            type="button"
            role="tab"
            @click="print">
            <MusicIcon variant="print" size="md" aria-hidden="true" />
            PRINT
            <span class="u-screen-reader-only">Word List</span>
          </button>
        </div>
      </template>
    </TabSet>
  </div>
</template>

<script>
  import { provide, reactive } from 'vue';
  import { testClass } from 'music';
  import MusicIcon from 'shared/vue/MusicIcon';
  import TabSet from 'shared/vue/TabSet';
  import TabSetTab from 'shared/vue/TabSetTab';

  export default {
    name: 'VocabTabs',
    components: {
      MusicIcon, TabSet, TabSetTab,
    },
    props: {
      ssjrStudent: { default: false, type: Boolean },
    },
    setup() {
      const tabs = reactive(
        [
          { label: 'Vocabulary', selected: true, linkClasses: [testClass('vocabulary-link')] },
          { label: 'Flashcards', selected: false, linkClasses: [testClass('flashcards-link')] },
        ]
      );

      const print = () => {
        const printWindow = window.open('', 'Vocabulary List');
        const printHtml = `<html>
          <head>${document.head.innerHTML}</head>
          <body class="ns-music-v1 ns-responsive ns-full-width ns-flashcards vol t-vol">
          ${document.querySelector('.js-vocab-tools-word-table')?.innerHTML}
            <script>
              window.print();
              window.onfocus = () => {
                window.close();
              }
            <\/script>
          </body>
        </html>`;
        printWindow.document.write(printHtml);
        printWindow.document.close();
        printWindow.focus();
        return false;
      };

      provide('tabs', tabs);

      return { print, tabs };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

   // Using ::v-deep(<inner-selector>) as ::v-deep usage as a combinator has been deprecated.

  .c-jr-vocab-tabs {
    ::v-deep(.tabs) {
      position: relative;
      justify-content: space-around;

      @include viewport-min(sm) {
        justify-content: flex-start;
      }
    }

    ::v-deep(.tab) {
      font-size: var(--font-1);
      padding-left: 0.72rem;
      padding-right: 0.72rem;

      @include viewport-min(sm) {
        font-size: 1rem;
        letter-spacing: 1px;
        padding-left: 1rem;
        padding-right: 1rem;
      }
    }

    ::v-deep(.tab.is-selected) {
      background-color: var(--ui-accent-highlight-color);
      border-bottom: 0.35rem solid var(--ui-accent-color);
      color: var(--ui-link-color);
    }

    .c-print-tab {
      position: absolute;
      right: 0rem;
      top: 2.63rem;

      @include viewport-min(sm) {
        position: relative;
        top: 1rem;
        right: 2rem;
      }
    }

    .c-print-tab .c-print-button {
      color: var(--ui-link-color);
      font-size: var(--font-1);
      letter-spacing: 1px;
      @include viewport-min(sm) {
        font-size: 1rem;
      }
    }
  }

</style>
