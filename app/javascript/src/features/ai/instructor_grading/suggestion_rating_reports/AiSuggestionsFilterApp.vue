<template>
  <div class="c-filter-container  c-form-item  u-pad-16  u-dis-flex  u-bord-bot-1  u-bord-gray-d">
    <!-- Lesson Selector -->
    <li class="c-menu__item  js-nav-system__item  u-txt-bold  u-bord-radius-16  c-filter-bg-white  u-mar-rt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      <a 
        href="#" 
        aria-haspopup="true" 
        aria-expanded="false" 
        class="c-menu__title  js-nav-system__link  m4-button-secondary  u-pad-top-2">
        <span>
          {{ twoTier ? 'Unit' : 'Lesson' }}
          <music-icon-down-arrow class="m4-fill--primary  u-mar-bot-2"></music-icon-down-arrow>
        </span>
      </a>
      <ul class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" role="menu">
        <div v-if="twoTier" class="c-menu__inner-scroll">
          <ul v-for="unit in units" :key="unit.id">
            <li>{{ unit.label }}</li>
            <li v-for="lesson in unitLessons(unit.lesson_ids)" :key="lesson.id" class="u-mar-lt-8" >
              <input type="checkbox" :value="lesson.id" v-model="selectedLessons">
              <label :for="'checkbox-lesson-id' + lesson.id" class="u-txt-bold  u-pad-lt-6">
                {{ lesson.label }}
              </label>
            </li>
          </ul>
        </div>
        <div v-else  class="c-menu__inner-scroll">
          <li v-for="lesson in lessons" :key="lesson.id">
            <input type="checkbox" :value="lesson.id" v-model="selectedLessons">
            <label :for="'checkbox-lesson-id' + lesson.id" class="u-txt-bold  u-pad-lt-6">
              {{ lesson.label }}
            </label>
          </li>
        </div>
      </ul>
    </li>

    <!-- Strand Selector -->
    <li class="c-menu__item  js-nav-system__item  u-txt-bold  u-bord-radius-16  c-filter-bg-white  u-mar-rt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      <a
        href="#" 
        aria-haspopup="true" 
        aria-expanded="false" 
        :class="[selectedLessons.length == 0 ? 'm4-txt--primary-disabled' : 'm4-button-secondary']"
        class="c-menu__title  js-nav-system__link  u-pad-top-2">
        <span v-if="selectedLessons.length == 0">
          Strand <music-icon-down-arrow class="m4-fill--primary-disabled  u-mar-bot-2"></music-icon-down-arrow>
        </span>
        <span v-else>
          Strand <music-icon-down-arrow class="m4-fill--primary  u-mar-bot-2"></music-icon-down-arrow>
        </span>
      </a>
      <ul
        v-if="selectedLessons.length > 0"
        class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" 
        role="menu"
        :style="calculateMaxWidthForUl(filteredStrands)">
        <div class="c-menu__inner-scroll">
          <li v-for="strand in filteredStrands" :key="strand.strand_id">
            <input type="checkbox" :value="strand" v-model="selectedStrands">
            <label :for="'checkbox-strand-id' + strand.strand_id" class="u-txt-bold  u-pad-lt-6">
              {{ strand.title }}
            </label>
          </li>
        </div>
      </ul>
    </li>

    <!-- Type Selector -->
    <li class="c-menu__item  js-nav-system__item  u-txt-bold  u-bord-radius-16  c-filter-bg-white  u-mar-rt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      <a 
        href="#" 
        aria-haspopup="true" 
        aria-expanded="false" 
        class="c-menu__title  js-nav-system__link  m4-button-secondary  u-pad-top-2">
        <span>
          Type <music-icon-down-arrow class="m4-fill--primary  u-mar-bot-2"></music-icon-down-arrow>
        </span>
      </a>
      <ul class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" role="menu" style="max-height: 5em;" >
        <div class="c-menu__inner-scroll">
          <li v-for="(typeValue, typeKey) in types" :key="typeKey">
            <input type="checkbox" :value="typeKey" v-model="selectedTypes">
            <label :for="'checkbox-type-id' + typeKey" class="u-txt-bold  u-pad-lt-6">
              {{ typeValue }}
            </label>
          </li>
        </div>
      </ul>
    </li>

    <!-- Instructors Selector -->
    <li class="c-menu__item  js-nav-system__item  u-txt-bold  u-bord-radius-16  c-filter-bg-white  u-mar-rt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      <a
        href="#"
        aria-haspopup="true"
        aria-expanded="false"
        class="c-menu__title  js-nav-system__link  m4-button-secondary  u-pad-top-2">
        <span>
          Instructor <music-icon-down-arrow class="m4-fill--primary  u-mar-bot-2"></music-icon-down-arrow>
        </span>
      </a>
      <ul class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" role="menu" style="max-height: 5em;" >
        <div class="c-menu__inner-scroll">
          <li v-for="instructorValue in instructors" :key="instructorValue.id">
            <input type="checkbox" :value="instructorValue.id" v-model="selectedInstructors">
            <label :for="'checkbox-instructor-id' + instructorValue.id" class="u-txt-bold  u-pad-lt-6">
              {{ instructorValue.full_name }}
            </label>
          </li>
        </div>
      </ul>
    </li>

    <StandardButton 
      type="submit" 
      @click="applyFilters" 
      class="m4-button--primary  u-txt-bold  u-mar-lt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      Apply
    </StandardButton>
  </div>

    <!-- Selected filters -->
    <div style="gap: 8px;" class="u-dis-flex  flex-wrap  u-pad-16  u-mar-tp-16">
    <span
      v-for="(lesson, index) in selectedLessons"
      :key="'lesson-' + lesson"
      class="c-lesson-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ findLessonLabel(lesson) }}
      <a class="u-txt-nodec  u-pad-lt-8  u-txt-black" @click="removeLesson(lesson)">
        <music-icon-close style="padding-bottom: 1.25rem;" size="sm"></music-icon-close>
      </a>
    </span>
    <span 
      v-for="(strand, index) in selectedStrands"
      :key="'strand-' + strand.strand_id"
      class="c-strand-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ strand.title }}
      <a class="u-txt-nodec  u-pad-lt-8  u-txt-black" @click="removeStrand(strand)">
        <music-icon-close style="padding-bottom: 1.25rem;" size="sm"></music-icon-close>
      </a>
    </span>
    <span 
      v-for="(type, index) in selectedTypes" 
      :key="'type-' + type" 
      class="c-type-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ findTypeLabel(type) }}
      <a class="u-txt-nodec  u-pad-lt-8  u-txt-black" @click="removeType(type)">
        <music-icon-close style="padding-bottom: 1.25rem;" size="sm"></music-icon-close>
      </a>
    </span>
    <span
      v-for="(instructor, index) in selectedInstructors"
      :key="'instructor-' + instructor"
      class="c-instructor-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ findInstructorLabel(instructor) }}
      <a class="u-txt-nodec  u-pad-lt-8  u-txt-black" @click="removeInstructor(instructor)">
        <music-icon-close style="padding-bottom: 1.25rem;" size="sm"></music-icon-close>
      </a>
    </span>
    <StandardButton 
      v-if="hasFilters" 
      @click="clearAllFilters" 
      class="m4-button--primary  u-txt-bold  u-pad-6  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      Clear All
    </StandardButton>
  </div>
</template>

<script setup>
  import { ref, computed, watch, onMounted } from 'vue';
  const props = defineProps({
    programId: {
      type: Number,
      required: true
    },
    lessons: {
      type: Array,
      required: true
    },
    strandsByLesson: {
      type: Array,
      required: true
    },
    types: {
      type: Object,
      required: true
    },
    instructors: {
      type: Array,
      required: true
    },
  });

  const selectedLessons = ref([]);
  const selectedStrands = ref([]);
  const selectedTypes = ref([]);
  const selectedInstructors = ref([]);

  onMounted(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const params = [
      'selected_lesson_ids',
      'selected_strands',
      'selected_types',
      'selected_instructor_ids',
    ];

    params.forEach(param => {
      const urlParam = urlParams.get(param);
      if (urlParam) {
        setSelectedValues(param, urlParam.split(','));
      }
    })
  });

  watch(selectedLessons, (newLessons) => {
    if (newLessons.length === 0) {
      selectedStrands.value = [];
    }
  });

  /**
   * Sets selected filter values based on the URL parameters.
   * @param {string} param - The name of the URL parameter.
   * @param {Array} values - The values retrieved from the URL.
   */
  const setSelectedValues = (param, values) => {
    switch (param) {
      case 'selected_lesson_ids':
        selectedLessons.value = values;
        break;
      case 'selected_strands':
        selectedStrands.value = values.map(strand => {
          return {
            strand_id: strand,
            title: props.strandsByLesson.find(s => s.strand_id === strand).title
          }
        });
        break;
      case 'selected_types':
        selectedTypes.value = values;
        break;
      case 'selected_instructor_ids':
        selectedInstructors.value = values;
        break;
    }
  }

  /**
   * Computes the available strands based on the selected lessons.
   * It ensures that only strands related to selected lessons are displayed.
   */
  const filteredStrands = computed(() => {
    const selectedLessonIds = selectedLessons.value.map(id => parseInt(id));

    const filtered = props.strandsByLesson.filter(strand =>
      selectedLessonIds.includes(strand.lesson_id)
    );

    const uniqueStrands = new Set();
    return filtered.filter(strand => {
      const isDuplicate = uniqueStrands.has(strand.title);
      uniqueStrands.add(strand.title);
      return !isDuplicate;
    });
  });

  /**
   * Finds lessons that belong to a specific unit.
   * @param {Array} lessonIds - An array of lesson IDs.
   * @returns {Array} The lessons that match the given IDs.
   */
  const unitLessons = (lessonIds) => {
    return props.lessons.filter( (lesson) => lessonIds.includes(lesson.id) );
  };

  /**
   * Finds the label for a given type key.
   * @param {string} typeKey - The key of the type.
   * @returns {string} The corresponding label.
   */
  const findTypeLabel = (typeKey) => {
    return props.types[typeKey] || '';
  }

  /**
   * Finds the full name of an instructor based on their ID.
   * @param {number} instructorId - The ID of the instructor.
   * @returns {string} The full name of the instructor.
   */
  const findInstructorLabel = (instructorId) => {
    const instructor = props.instructors.find(instructor => instructor.id === parseInt(instructorId));
    return instructor ? instructor.full_name : '';
  }

  /**
   * Finds the label for a given lesson ID.
   * @param {number} lessonId - The ID of the lesson.
   * @returns {string} The label of the lesson.
   */
  const findLessonLabel = (lessonId) => {
    const lesson = props.lessons.find(lesson => lesson.id === parseInt(lessonId));
    return lesson ? lesson.label : '';
  }

  /**
   * Removes a lesson from the selected lessons list.
   * @param {number} lessonId - The ID of the lesson to be removed.
   */
  const removeLesson = (lessonId) => {
    selectedLessons.value = removeFilter(selectedLessons.value, lessonId);
  };

  /**
   * Removes a strand from the selected strands list.
   * @param {string} strand - The strand to be removed.
   */
  const removeStrand = (strand) => {
    selectedStrands.value = removeFilter(selectedStrands.value, strand);
  };

  /**
   * Removes a type from the selected types list.
   * @param {string} typeKey - The key of the type to be removed.
   */
  const removeType = (typeKey) => {
    selectedTypes.value = removeFilter(selectedTypes.value, typeKey);
  };

  /**
   * Removes an instructor from the selected instructors list.
   * @param {number} instructor - The ID of the instructor to be removed.
   */
  const removeInstructor = (instructor) => {
    selectedInstructors.value = removeFilter(selectedInstructors.value, instructor)
  }

  /**
   * Generic method to remove an item from a given array.
   * @param {Array} array - The array to modify.
   * @param {any} value - The value to remove.
   * @returns {Array} A new array without the specified value.
   */
  const removeFilter = (array, value) => {
    return array.filter(item => item !== value);
  }

  /**
   * Determines if any filters have been applied.
   * @returns {boolean} True if at least one filter is applied.
   */
  const hasFilters = computed(() => {
    return [
      selectedLessons.value,
      selectedStrands.value,
      selectedTypes.value,
      selectedInstructors.value,
    ].some(filters => filters.length > 0);
  })

  /**
   * Clears all selected filters.
   */
  const clearAllFilters = () => {
    selectedLessons.value = [];
    selectedStrands.value = [];
    selectedTypes.value = [];
    selectedInstructors.value = [];
  };

  /**
   * Dynamically calculates the maximum width of the dropdown menu for strands.
   * @param {Array} strands - The list of available strands.
   * @returns {Object} A style object containing the maxWidth value.
   */
  const calculateMaxWidthForUl = (strands) => {
    const longestString = 
      strands.reduce((a, b) => a.title.length > b.title.length ? a : b, { title: '' });
    const maxWidth = longestString.title.length * 10;

    return {
      maxWidth: `${maxWidth}px`,
    };
  };

  /**
   * Applies the selected filters and redirects the user to the filtered results.
   */
  const applyFilters = () => {
    let url = `${window.location.origin}/ai/programs/${props.programId}/instructor_grading/suggestion_rating_reports`;
    const params = new URLSearchParams({
      selected_lesson_ids: selectedLessons.value,
      selected_strands: selectedStrands.value.map(strand => strand.strand_id),
      selected_types: selectedTypes.value,
      selected_instructor_ids: selectedInstructors.value,
      filtered: true
    });
    window.location.href = `${url}?${params.toString()}`;
  };
</script>
