<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">
        Program Editions set
      </h3>
    </div>
    <div class="c-panel__body">
      <fieldset class="u-mar-top-16">
        <div class="c-form-item  l-line">
          <div>
            <label for="previous_edition_program_id" class="c-form-item__label">
              Previous Edition Program
            </label>
            <select
              id="previous_edition_program_id"
              v-model="programEditionData.previousEditionProgramId"
              class="c-dropdown--button  c-select  u-width-full"
              name="previous_edition_program_id">
              <option />
              <option
                v-for="(program, programIdIndex) in programsByTitle"
                :key="programIdIndex"
                :value="program.id">
                {{ program.title }}
              </option>
            </select>
          </div>
          <div>
            <label for="next_edition_program_id" class="c-form-item__label">
              Next Edition Program
            </label>
            <select
              id="next_edition_program_id"
              v-model="programEditionData.nextEditionProgramId"
              class="c-dropdown--button  c-select  u-width-full"
              name="next_edition_program_id">
              <option />
              <option
                v-for="(program, programIdIndex) in programsByTitle"
                :key="programIdIndex"
                :value="program.id">
                {{ program.title }}
              </option>
            </select>
          </div>
        </div>
      </fieldset>
    </div>
  </div>
</template>

<script setup>
  import { reactive } from 'vue';

  /**
    * @typedef Program
    * @property {Array} programsByTitle - array program by title
    * @property {string} previousEditionProgramId - previous edition id to current program
    * @property {string} nextEditionProgramId - next edition id to current program
  */
  const props = defineProps({
    /** @type {Program[]} programsByTitle */
    programsByTitle: { required: true, type: Array },
    previousEditionProgramId: { type: String, default: '' },
    nextEditionProgramId: { type: String, default: '' },
  });

  const programEditionData = reactive({
    previousEditionProgramId: props.previousEditionProgramId,
    nextEditionProgramId: props.nextEditionProgramId,
  });
  const programsByTitle = props.programsByTitle;
</script>
