<template>
  <ModalComponent
    :class="testClass('auto-map-modal')"
    title="Map Automatically"
    @close="onCloseClick($event)">
    <template #body>
      <div class="c-panel__body  modal-body-text">
        <p>
          Map automatically will override the current strand mappings.
          The replaced mappings will not save until you click “submit” at
          the bottom of the page.
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
          :class="testClass('map-automatically')"
          @click="mapToDestination($event)">
          Map Automatically
        </button>
      </div>
    </template>
  </ModalComponent>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';

  const useMappingSrcChangeModal = (emit, programToProgramMapping, props) => {
    /**
     * Handler for modal close.
     * @param {Event} event - click event on close modal button
     */
    const onCloseClick = async (event) => {
      emit('close', event);
    };

    /**
     * Map source program to destination.
     * @param {Event} event - document click event
     */
    const mapToDestination = (event) => {
      programToProgramMapping.mapAutomatically(props.srcProgId);
      emit('close', event);
    };

    return { mapToDestination, onCloseClick };
  };

  export default {
    name: 'MapAutomatically',
    components: { ModalComponent },
    props: {
      srcProgId: { default: 0, type: Number },
    },
    setup(props, { emit }) {
      const programToProgramMapping = inject('programToProgramMapping');
      const { onCloseClick, mapToDestination } = useMappingSrcChangeModal(
        emit, programToProgramMapping, props
      );

      return { mapToDestination, onCloseClick, testClass };
    },
  };
</script>
