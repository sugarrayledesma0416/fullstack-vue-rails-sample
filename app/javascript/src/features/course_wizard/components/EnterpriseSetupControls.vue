<template>
  <div class="setup-footer">
    <div class="u-max-width-1200 u-pad-24 u-width-full u-mar-auto">
      <div class="u-dis-flex flex-justify-between flex-align-ctr">
        <div class="u-dis-flex" style="gap: 25px;">
          <button
            v-if="previousStep !== ''"
            arrowDirection="left"
            theme="supersites-secondary"
            renderAs="link"
            href="javascript://"
            class="c-button-v3 c-button-v3--lg c-button-v3--tertiary"
            @click="$router.push({ name: previousStep })">
            <music-icon-chevron-right rotate="180" size="4" />
            <span>Previous</span>
          </button>
          <button
            v-if="nextStep !== ''"
            type="button"
            class="c-button-v3 c-button-v3--lg"
            :class="getNextButtonClass()"
            :disabled="isNextDisabled"
            @click="$router.push({ name: nextStep })">
            <span>Next</span>
            <music-icon-chevron-right size="4" />
          </button>
          <button
            v-if="!courseDataStore.newCourseMode"
            class="c-button-v3 c-button-v3--lg c-button-v3--primary"
            :class="testClass('save-changes')"
            variant="primary"
            type="button"
            @click="courseDataStore.postCourseUpdate()">
            <span>Save changes</span>
          </button>
          <button
            v-if="courseDataStore.newCourseMode && showSaveBtn"
            class="c-button-v3 c-button-v3--lg c-button-v3--primary"
            variant="primary"
            type="button"
            :disabled="isSaveDisabled"
            @click="$emit('save')">
            <span>Save</span>
          </button>
        </div>
        <div class="flex-spacer"></div>
        <!-- TODO: Remove u-txt-true-gray-900 u-txt-nodec once we no longer have ns-music-v1 on
        the page -->
        <a
          :href="getCancelPath()"
          class="
            c-button-v3
            c-button-v3--lg
            c-button-v3--quaternary
            u-txt-true-gray-900
            u-txt-nodec
          "
          :class="testClass('cancel-btn')">
          <span>Cancel</span>
        </a>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import StandardButton from 'music/app/javascript/src/vue/StandardButton';
  import ArrowButton from 'music/app/javascript/src/components/arrow_button/v2.0/ArrowButton';

  export default {
    name: 'EnterpriseSetupControls',
    components: { StandardButton, ArrowButton },
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
       * Get next button style class.
       * @return {string}
       */
      function getNextButtonClass() {
        return courseDataStore.newCourseMode
          ? 'c-button-v3--primary'
          : 'c-button-v3--tertiary';
      }

      /**
       * This href path for cancel link
       * @return {string}
       */
      function getCancelPath() {
        return config.instAdmin ?
          `/institution_admin/courses/${config.programId}?school_id=${config.schoolId}` :
          `/instructor/dashboard/${config.programId}`;
      }

      return {
        courseDataStore,
        getNextButtonClass,
        getCancelPath,
        testClass
      };
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
    left: 0pt;
    position: fixed;
    width: 100%;
    /*
     * Set to this value to prevent a bug with tippy tooltips that have
     * a z-index of 9999
     */
    z-index: 10000;

    // TODO: Remove this utility class when music v3 adds it.
    .u-max-width-1200 {
      max-width: rpx(1200);
    }

    // TODO: Remove these "a" and "button" overrides once we remove ns-music-v1 from the page.
    a:hover {
      text-decoration: none;
    }

    button, [type="button"] {
      font-size: var(--button-font-size)
    }
  }

  .flex-spacer {
    flex-grow: 1;
  }
</style>
