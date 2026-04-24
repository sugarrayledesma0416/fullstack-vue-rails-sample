<template>
  <ModalComponent
    :class="testClass('src-change-modal')"
    :title="title"
    @close="onCloseClick($event)">
    <template #body>
      <div v-if="type === 'mapping-change-src'" class="c-panel__body modal-body-text">
        <p>
          <span class="u-txt-bold  new-src-program"> {{ title }}</span>
          will be set as the new source.
        </p>
        <p>
          Doing so will delete the previously mapped source since only one source
          can be mapped per destination.
        </p>
      </div>

      <div v-else-if="type === 'mapping-already-in-use'" class="c-panel__body  modal-body-text">
        <p>
          <span class="new-src-program">{{ newSrcProg }}</span> is already used as a source for
          <span class="u-txt-bold  current-dest-program">{{ currentDestForSrcName }}</span>,
          each source can only be used once.
        </p>
        <p>
          Would you like to delete the existing mapping between
          <span class="u-txt-bold  new-src-program">{{ newSrcProg }}</span> and
          <span class="u-txt-bold  current-dest-program">{{ currentDestForSrcName }}</span>?
        </p>
      </div>

      <div
        v-else-if="type === 'mapping-change-and-in-use'"
        class="c-panel__body  modal-body-text">
        <p>
          <span class="new-src-program">{{ newSrcProg }}</span> is already used as a source for
          <span class="u-txt-bold  current-dest-program">{{ currentDestForSrcName }}</span>,
          each source can only be used once.
        </p>
        <p>
          Would you like to delete the existing mapping between
          <span class="u-txt-bold  new-src-program">{{ newSrcProg }}</span> and
          <span class="u-txt-bold  current-dest-program">{{ currentDestForSrcName }}</span>, and
          <span class="u-txt-bold">set it as a new source</span>?
        </p>
      </div>
    </template>
    <template #footer>
      <div class="c-button-group  u-mar-0  u-txt-rt">
        <button
          type="button"
          class="c-button"
          :class="testClass('modal-cancel')"
          @click.stop="onCloseClick($event)">
          Cancel
        </button>
        <button
          type="button"
          class="c-button  c-button--primary"
          :class="testClass('modal-confirm')"
          @click.stop="onConfirmClick($event)">
          <span class="confirm-button">{{ confirmButtonText }}</span>
        </button>
      </div>
    </template>
  </ModalComponent>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';

  const useMappingSrcChangeModal = (emit, localstore, props) => {
    /**
     * Handler for modal close.
     * @param {Event} event - click event on close modal button
     */
    const onCloseClick = async (event) => {
      await localstore.programToProgramMapping.declineSourceProgramChange();
      emit('close', event);
    };

    /**
     * Handler for confirm button click.
     * @param {Event} event - click event on confirm button
     */
    const onConfirmClick = async (event) => {
      await localstore.programToProgramMapping.confirmSourceProgramChange(
        props.srcProgId, props.currentDestForSrcId
      );
      emit('close', event);
    };

    return { onCloseClick, onConfirmClick };
  };

  export default {
    name: 'MappingSrcChangeModal',
    components: { ModalComponent },
    props: {
      confirmButtonText: { required: true, type: String },
      currentDestForSrcId: { default: 0, type: Number },
      currentDestForSrcName: { default: '', type: String },
      newSrcProg: { default: '', type: String },
      srcProgId: { default: 0, type: Number },
      title: { required: true, type: String },
      type: { required: true, type: String },
    },
    setup(props, { emit }) {
      const localstore = {
        programToProgramMapping: inject('programToProgramMapping'),
        programTitle: inject('programTitle'),
      };
      const { onCloseClick, onConfirmClick } = useMappingSrcChangeModal(emit, localstore, props);

      return { onCloseClick, onConfirmClick, localstore, testClass };
    },
  };
</script>
