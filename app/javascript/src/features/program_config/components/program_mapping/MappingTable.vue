<template>
  <div
    ref="disclosureElm"
    class="c-disclosure  c-disclosure--start"
    :class="testClass('lesson-title')">
    <div
      class="c-disclosure__header"
      role="button"
      aria-expanded="false"
      aria-controls="disclosure-body">
      <div class="c-disclosure__marker" />
      <h3 class="u-dis-inline">
        {{ lesson.name }}
      </h3>
    </div>
    <div id="disclosure-body" class="c-disclosure__body  u-pad-0  u-mar-0">
      <div class="u-pad-top-12  u-mar-lt-24  mapping-table">
        <table class="c-table">
          <tr
            v-for="concept in lesson.concepts"
            :key="concept.id"
            class="c-row"
            :class="testClass(`concept-${concept.id}`)">
            <td
              class="l-span-3"
              :class="testClass('concept_name')"
              scope="row">
              <p v-html="concept.name" />
            </td>
            <td scope="row">
              <input
                :id="`src_strand_id_${concept.id}`"
                type="hidden"
                name="ptp_mapping[][src_strand_id]"
                :value="concept.id">
              <select
                :id="`ptp_mapping_dest_lesson_id_${concept.id}`"
                name="ptp_mapping[][dest_lesson_id]"
                class="c-dropdown--button  c-select  l-span-3  u-mar-rt-4"
                :class="testClass('concept-lessons')"
                @change="onLessonChange($event, concept)">
                <option value="">
                  Please select
                </option>
                <option
                  v-for="option in lessonsForDestPrograms"
                  :key="option[1]"
                  :value="option[1]"
                  :selected="concept.selected_lesson === option[1]">
                  {{ option[0] }}
                </option>
              </select>

              <select
                :id="`ptp_mapping_dest_strand_id_${concept.id}`"
                name="ptp_mapping[][dest_strand_id]"
                class="c-dropdown--button  c-select  l-span-3"
                :class="testClass('concept-strands')">
                <option
                  v-for="option in getStrandsForLesson(concept)"
                  :key="option[1]"
                  :value="option[1]"
                  :selected="concept.selected_strand === option[1]"
                  v-html="option[0]" />
              </select>
            </td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, onMounted, ref } from 'vue';
  import { testClass } from 'music';

  const useMappingTable = (disclosureElm, disclosure, programToProgramMapping) => {
    /**
     * Initialise disclosures for the lessons.
     */
    const initializeDisclosure = () => {
      disclosure.value = new VHL.Music.V1.Disclosure(disclosureElm.value);
    };

    /**
     * Get all strands selectbox values.
     * @param {Object} concept - lesson`s concept
     * @return {Array} - strands array.
     */
    const getStrandsForLesson = (concept) => {
      if (concept.strands_for_dest_lesson_array) {
        return [['Please Select', '']].concat(concept.strands_for_dest_lesson_array);
      } else {
        return [['Please Select a lesson', '']];
      }
    };

    /**
     * Handler for lesson change.
     * @param {Event} event - onchange event for lesson.
     * @param {Object} concept - lesson`s concept
     */
    const onLessonChange = async (event, concept) => {
      const lessonId = parseInt(event.target.value);
      const strands = await programToProgramMapping.getDestLessonStrands(lessonId);
      if (strands) {
        concept.strands_for_dest_lesson_array = strands.map((strand) => [strand.name, strand.id]);
      } else {
        concept.strands_for_dest_lesson_array = [];
      }

      concept.selected_lesson = '';
      concept.selected_strand = '';
    };

    return { initializeDisclosure, getStrandsForLesson, onLessonChange };
  };

  export default {
    name: 'MappingTable',
    components: { },
    props: {
      lesson: { default: () => {}, type: Object },
      lessonsForDestPrograms: { default: () => [], type: Array },
      strandsForDestLessons: { default: () => [], type: Array },
    },
    setup() {
      const disclosureElm = ref(null);
      const disclosure = ref(null);
      const programToProgramMapping = inject('programToProgramMapping');

      const { initializeDisclosure, getStrandsForLesson, onLessonChange } =
        useMappingTable(disclosureElm, disclosure, programToProgramMapping);

      onMounted(() => {
        initializeDisclosure();
      });
      return { disclosureElm, getStrandsForLesson, onLessonChange, testClass };
    },
  };
</script>
