<template>
  <ModalComponent
    :hideHeader="true"
    :class="testClass('section-modal')"
    :isConfirmationDialog="true">
    <template #body>
      <div class="section-modal-body" :class="testClass('section-modal-body')">
        {{ newSectionMsg }}
      </div>
    </template>
    <template #footer>
      <div class="section-modal-controls">
        <VhlButton
          variant="primary"
          class="mar-rt-8  js-modal-a11y__last-focus-element"
          :class="testClass('section-modal-yes')"
          @click="courseDataStore.courseHttp.gotoSectionWizard(
            courseDataStore.store.saveCourseResponse
          )">
          Yes
        </VhlButton>
        <VhlButton
          class="js-modal-a11y__last-focus-element"
          :class="testClass('section-modal-no')"
          @click="courseDataStore.courseHttp.returnToDashboard(
            courseDataStore.store.saveCourseResponse
          )">
          No
        </VhlButton>
      </div>
    </template>
  </ModalComponent>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import VhlButton from 'features/learning_tracks/components/VhlButton';
  import ModalComponent from 'features/modal/ModalComponent';

  export default {
    name: 'CreateSectionModal',
    components: { ModalComponent, VhlButton },
    props: {
      loadingIconPath: { default: '', type: String },
    },
    setup() {
      const courseDataStore = inject('courseDataStore');
      const newSectionMsg = 'Do you want to create a section for this course?';

      return {
        courseDataStore,
        newSectionMsg,
        testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .section-modal-body {
    color: $gray-3;
  }

  .section-modal-controls {
    display: flex;
    justify-content: center;
  }

  .mar-rt-8 {
    margin-right: 0.5rem;
  }
</style>
