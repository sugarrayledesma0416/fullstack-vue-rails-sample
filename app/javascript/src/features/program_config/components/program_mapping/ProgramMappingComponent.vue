<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">My Content</h3>
    </div>
    <div class="c-panel__body">
      <MapSourceProgram
        :canMap="localstore.lessons.length > 0"
        :mappingSrcPrograms="localstore.mappingSrcPrograms"
        :mappingSrcProgramId="localstore.mappingSrcProgramId"
        :srcProgId="localstore.srcProgId"
        :sourceChanged="localstore.sourceChanged" />

      <MappingSrcChangeModal
        v-if="modalParams.type"
        :confirmButtonText="modalParams.confirmButtonText"
        :currentDestForSrcId="modalParams.currentDestForSrcId"
        :currentDestForSrcName="modalParams.currentDestForSrcName"
        :newSrcProg="modalParams.newSrcProg"
        :srcProgId="localstore.srcProgId"
        :title="modalParams.header"
        :type="modalParams.type"
        @close="onModalClose()" />

      <div class="u-bord-top-2  u-pad-top-12  mapping-content">
        <div
          v-for="(lesson, index) in localstore.lessons"
          :key="`${index}-${localstore.tableKey}`">
          <MappingTable
            :lesson="lesson"
            :lessonsForDestPrograms="localstore.lessonsForDestPrograms" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, provide, reactive } from 'vue';
  import { testClass } from 'music';
  import MapSourceProgram from './MapSourceProgram';
  import MappingSrcChangeModal from './MappingSrcChangeModal';
  import MappingTable from './MappingTable';
  import ProgramToProgramMapping from '../../models/program_to_program_mapping';

  const useProgramMappingComponent = ( modalParams, localstore) => {
    /**
     * Handler for modal close event.
     */
    const onModalClose = () => {
      modalParams.type = null;
    };

    return { onModalClose };
  };

  export default {
    name: 'ProgramMappingComponent',
    components: { MapSourceProgram, MappingSrcChangeModal, MappingTable },
    props: {
      programMappingData: { required: true, type: Object },
    },
    setup(props) {
      const modalParams = reactive({
        type: '',
        header: '',
        confirmButtonText: '',
        currentDestForSrcId: '',
        currentDestForSrcName: '',
      });

      const programMappingData = props.programMappingData;
      let srcProgId;
      if (programMappingData.mapping_src_prog_id === '') {
        srcProgId = 0;
      } else {
        srcProgId = parseInt(programMappingData.mapping_src_prog_id);
      }

      const localstore = reactive({
        destProgId: inject('programId'),
        lessons: programMappingData.mapping_src_lessons_strands,
        lessonsForDestPrograms: programMappingData.lessons_for_dest_program_array,
        mappingSrcProgramId: programMappingData.mapping_src_prog_id.toString(),
        mappingSrcPrograms: programMappingData.mapping_src_programs_array,
        newSrcProg: '',
        srcProgId,
        tableKey: 0,
        sourceChanged: false,
      });
      const programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);

      provide('programToProgramMapping', programToProgramMapping);

      const { onModalClose } = useProgramMappingComponent(modalParams, localstore);

      return { localstore, onModalClose, modalParams, testClass };
    },
  };
</script>
