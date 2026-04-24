<template>
  <div class="setup-footer">
    <div class="setup-controls">
      <template v-if="courseDataStore.newCourseMode === true">
        <ArrowButton
          v-if="previousStep !== ''"
          arrowDirection="left"
          theme="supersites-secondary"
          renderAs="link"
          href="javascript://"
          class="u-mar-right-8"
          :class="testClass('back-btn')"
          @click="$router.push({ name: previousStep })">
          Previous
        </ArrowButton>
        <ArrowButton
          v-if="nextStep !== ''"
          type="button"
          class="u-mar-right-8"
          :class="testClass('next-btn')"
          :disabled="isNextDisabled"
          @click="$router.push({ name: nextStep })">
          Next
        </ArrowButton>
        <StandardButton
          v-if="showSaveBtn"
          :class="testClass('save-course')"
          variant="primary"
          type="button"
          :disabled="isSaveDisabled"
          @click="$emit('save')">
          Save
        </StandardButton>
        <span class="flex-spacer" />
        <VhlLink
          :href="getCancelPath()"
          class="cancel-setup"
          :class="testClass('cancel-btn')">
          cancel
        </VhlLink>
      </template>
      <template v-else>
        <StandardButton
          class="save-btn"
          :class="testClass('save-changes')"
          variant="primary"
          type="button"
          :disabled="isUpdateDisabled"
          @click="courseDataStore.postCourseUpdate()">
          Save changes
        </StandardButton>
        <VhlLink
          :href="getCancelPath()"
          class="cancel-edit"
          :class="testClass('cancel-btn')">
          EXIT
        </VhlLink>
      </template>
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import StandardButton from 'music/app/javascript/src/vue/StandardButton';
  import VhlLink from './VhlLink';
  import ArrowButton from 'music/app/javascript/src/components/arrow_button/v2.0/ArrowButton';

  export default {
    name: 'SetupControls',
    components: { StandardButton, VhlLink, ArrowButton },
    props: {
      isNextDisabled: { default: false, type: Boolean },
      isSaveDisabled: { default: false, type: Boolean },
      isUpdateDisabled: { default: false, type: Boolean },
      nextStep: { default: '', type: String },
      previousStep: { default: '', type: String },
      showSaveBtn: { default: false, type: Boolean },
    },
    emits: ['save'],
    setup() {
      const courseDataStore = inject('courseDataStore');
      const config = inject('config');

      /**
       * This href path for cancel link
       * @return {string}
       */
      function getCancelPath() {
        return config.instAdmin ?
          `/institution_admin/templates/${config.programId}?school_id=${config.schoolId}` :
          `/instructor/dashboard/${config.programId}`;
      }

      return { courseDataStore, getCancelPath, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .setup-footer {
    background-attachment: scroll;
    background-color: white;
    background-image: none;
    background-position: 0% 0%;
    background-repeat: repeat;
    border-top: $border-width-1 solid $gray-d;
    bottom: 0pt;
    height: rpx(68);
    left: 0pt;
    position: fixed;
    width: 100%;
    /*
     * Set to this value to prevent a bug with tippy tooltips that have
     * a z-index of 9999
     */
    z-index: 10000;
  }
  .setup-controls {
    height: rpx(68);
    margin: auto;
    max-width: 1200px;
    padding: 1rem;
    width: 100%;
  }
  .next-btn,
  .save-btn {
    line-height: 1.2rem;
    min-width: 7rem;
  }
  .cancel-setup {
    display: inline-block;
    float: right;
    text-transform: uppercase;
  }
  .cancel-edit {
    margin: 0 rpx(42);
  }
  .flex-spacer {
    flex-grow: 100;
  }
  .mar-right-4 {
    margin-right: rpx(4);
  }

  .u-mar-right-8 {
    margin-right: rpx(8);
  }
</style>
