<template>
  <div class="l-grid  u-mar-bot-12">
    <div>
      <label class="c-heading--caps" for="mapping_src_program">Source</label>
      <select
        id="mapping_src_program"
        ref="mappingSrcProgramElm"
        name="mapping_src_program"
        class="c-dropdown--button  c-select  l-span-3"
        :class="testClass('mapping-src-program')"
        @change="onSrcProgramChange($event)">
        <option value="">
          Please select
        </option>
        <option
          v-for="option in mappingSrcPrograms"
          :key="option[1]"
          :value="option[1]"
          :selected="mappingSrcProgramId === option[1].toString()">
          {{ option[0] }}
        </option>
      </select>
    </div>
    <div class="u-mar-top-20">
      <button
        type="button"
        class="c-button c-button--border"
        :class="testClass('map-to-destination')"
        :disabled="!canMap"
        @click="mapToDestination()">
        Map to Destination
      </button>
    </div>
    <div class="u-mar-lt-48">
      <label class="c-heading--caps" for="mapping_dest_program">Destination</label>
      <p class="u-txt-bold  u-pad-top-8" :class="testClass('program-title')">
        {{ localstore.programTitle }}
      </p>
    </div>

    <MapAutomatically
      v-if="localstore.showMapAutomaticallyModal"
      :srcProgId="srcProgId"
      @close="onModalClose('map-automatically')" />
  </div>
</template>

<script>
  import { inject, onMounted, reactive, ref } from 'vue';
  import { testClass } from 'music';
  import MapAutomatically from './MapAutomatically';

  const useMapSourceProgram = (localstore, props) => {
    /**
     * Handler for modal close event.
     */
    const onModalClose = () => {
      localstore.showMapAutomaticallyModal = false;
    };

    /**
     * Reset the lessons and strands on change of source program.
     * @param {Event} event - onchange event for source program
     */
    const onSrcProgramChange = (event) => {
      const value = event.target.value;

      if (value) {
        const id = parseInt(event.target.value);
        const text = props.mappingSrcPrograms.find((program) => program[1] === id)[0];
        localstore.programToProgramMapping.onSrcProgramChange({
          srcProgId: id,
          srcProgName: text,
          noCurrentSrc: noCurrentSrc(),
        });
      }
    };

    /**
     * Map source to the destination.
     */
    const mapToDestination = () => {
      if (noCurrentSrc() || props.sourceChanged) {
        localstore.programToProgramMapping.mapAutomatically(props.srcProgId);
      } else {
        localstore.showMapAutomaticallyModal = true;
      }
    };

    /**
     * @private
     * @return {boolean} Whether mapping exists for the current destination
     */
    const noCurrentSrc = () => {
      return props.mappingSrcProgramId === '';
    };

    return { mapToDestination, onModalClose, onSrcProgramChange };
  };

  export default {
    name: 'MapSourceProgram',
    components: { MapAutomatically },
    props: {
      canMap: { required: true, type: Boolean },
      mappingSrcProgramId: { default: '', type: String },
      mappingSrcPrograms: { required: true, type: Array },
      sourceChanged: { required: true, type: Boolean },
      srcProgId: { default: 0, type: Number },
    },
    setup(props) {
      const mappingSrcProgramElm = ref(null);

      const localstore = reactive({
        programToProgramMapping: inject('programToProgramMapping'),
        programTitle: inject('programTitle'),
      });

      const {
        onModalClose, onSrcProgramChange, mapToDestination,
      } = useMapSourceProgram(localstore, props);

      onMounted(() => {
        // For use in preserving last selected item in the source dropdown.
        sessionStorage.setItem('lastSelSrcProg', mappingSrcProgramElm.value.value);
      });

      return {
        localstore,
        mappingSrcProgramElm,
        mapToDestination,
        onModalClose,
        onSrcProgramChange,
        props,
        testClass,
      };
    },
  };
</script>
