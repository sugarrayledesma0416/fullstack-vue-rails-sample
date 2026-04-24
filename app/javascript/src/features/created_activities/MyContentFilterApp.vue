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
          <li v-for="strand in filteredStrands" :key="strand.title">
            <input type="checkbox" :value="strand.title" v-model="selectedStrands">
            <label :for="'checkbox-strand-' + strand.title" class="u-txt-bold  u-pad-lt-6">
              <span v-html="strand.title"></span>
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
      <ul class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" role="menu">
        <div class="c-menu__inner-scroll">
          <li v-for="(typeValue, typeKey) in types" :key="typeKey">
            <input type="checkbox" :value="typeKey" v-model="selectedTypes">
            <label :for="'checkbox-type-' + typeKey" class="u-txt-bold  u-pad-lt-6">
              {{ typeValue }}
            </label>
          </li>
        </div>
      </ul>
    </li>

    <!-- Created by Selector -->
    <li 
      v-if="sharedActivityCreators"
      class="c-menu__item  js-nav-system__item  u-txt-bold  u-bord-radius-16  c-filter-bg-white  u-mar-rt-16  u-pad-8  u-pad-lt-16  u-pad-rt-16">
      <a href="#" aria-haspopup="true" aria-expanded="false" class="c-menu__title  js-nav-system__link  m4-button-secondary  u-pad-top-2">
        <span>Created by <music-icon-down-arrow class="m4-fill--primary  u-mar-bot-2"></music-icon-down-arrow></span>
      </a>
      <ul 
        class="c-menu__inner  js-nav-system__subnav  u-bord-radius-16" 
        role="menu"
        >
        <div class="c-menu__inner-scroll">
          <li 
            v-for="sharedActivityCreator in sharedActivityCreators" 
            :key="sharedActivityCreator.id">
            <input 
              type="checkbox" 
              :value="sharedActivityCreator.id"
              v-model="selectedSharedActivityCreators">
            <label 
              :for="'checkbox-shared-activity-creators-' + sharedActivityCreator.id" 
              class="u-txt-bold  u-pad-lt-6">
              {{ sharedActivityCreator.full_name }}
            </label>
          </li>
        </div>
      </ul>
    </li>
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
      :key="'strand-' + strand" 
      class="c-strand-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ strand }}
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
      v-for="(sharedActivityCreator, index) in selectedSharedActivityCreators" 
      :key="'type-' + sharedActivityCreator.id" 
      class="c-type-chip  m4-button-tertiary  u-pad-4  u-pad-lt-12  u-pad-rt-12  u-mar-top-12">
      {{ findSharedActivityCreatorFullName(sharedActivityCreator) }}
      <a 
        class="u-txt-nodec  u-pad-lt-8  u-txt-black" 
        @click="removeSharedActivityCreators(sharedActivityCreator)">
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
  import { ref, onMounted, onUpdated, computed, nextTick, watch } from 'vue';

  const props = defineProps({
    programId: { type: Number, required: true },
    twoTier: { type: Boolean, default: false },
    lessons: { type: Array, required: true },
    units: { type: Array, required: true },
    strandsByLesson: { type: Array, required: true },
    types: { type: Object, required: true },
    sharedActivityCreators: { type: Object, required: true }
  });

  const selectedLessons = ref([]);
  const selectedStrands = ref([]);
  const selectedTypes = ref([]);
  const selectedSharedActivityCreators = ref([]);
  const shouldUpdate = ref(false);

  // Get selected filters if the component is reloaded
  onMounted(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const params = [
      'selected_lesson_ids',
      'selected_strands',
      'selected_types',
      'selected_shared_activity_creator_ids'
    ];

    params.forEach(param => {
      const urlParam = urlParams.get(param);
      if (urlParam) {
        setSelectedValues(param, urlParam.split(','));
      }
    });

    nextTick(() => {
      shouldUpdate.value = true;
    });
  });

  const setSelectedValues = (param, values) => {
    switch (param) {
      case 'selected_lesson_ids':
        selectedLessons.value = values;
        break;
      case 'selected_strands':
        selectedStrands.value = values;
        break;
      case 'selected_types':
        selectedTypes.value = values;
        break;
      case 'selected_shared_activity_creator_ids':
        selectedSharedActivityCreators.value = values;
        break;
    }
  }

  onUpdated(() => {
    if(shouldUpdate.value) {
      applyFilters();
    }
  });

  const hasFilters = computed(() => {
    return [
      selectedLessons.value,
      selectedStrands.value,
      selectedTypes.value,
      selectedSharedActivityCreators.value,
    ].some(filters => filters.length > 0);
  })

  const findLessonLabel = (lessonId) => {
    const lesson = props.lessons.find(lesson => lesson.id === parseInt(lessonId));
    return lesson ? lesson.label : '';
  }

  const findTypeLabel = (typeKey) => {
    return props.types[typeKey] || '';
  }

  const findSharedActivityCreatorFullName = (sharedActivityCreatorId) => {
    const sharedActivityCreator =
      props.sharedActivityCreators.find(
        sharedActivityCreator =>
        sharedActivityCreator.id === parseInt(sharedActivityCreatorId)
      );
    return sharedActivityCreator.full_name
  }

  const removeFilter = (array, value) => {
    applyFilters();
    return array.filter(item => item !== value);
  }

  const removeLesson = (lessonId) => {
    selectedLessons.value = removeFilter(selectedLessons.value, lessonId);
  };

  const removeStrand = (strand) => {
    selectedStrands.value = removeFilter(selectedStrands.value, strand);
  };

  const removeType = (typeKey) => {
    selectedTypes.value = removeFilter(selectedTypes.value, typeKey);
  };

  const removeSharedActivityCreators = (sharedActivityCreatorsKey) => {
    selectedSharedActivityCreators.value = 
      removeFilter(selectedSharedActivityCreators.value, sharedActivityCreatorsKey);
  };

  const clearAllFilters = () => {
    selectedLessons.value = [];
    selectedStrands.value = [];
    selectedTypes.value = [];
    selectedSharedActivityCreators.value = [];
  };

  // Computed to filter strands based on selected lessons
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

  const calculateMaxWidthForUl = (strands) => {
    const longestString = 
      strands.reduce((a, b) => a.title.length > b.title.length ? a : b, { title: '' });
    const maxWidth = longestString.title.length * 10;

    return {
      maxWidth: `${maxWidth}px`,
    };
  };

  watch(selectedLessons, (newLessons) => {
    if (newLessons.length === 0) {
      selectedStrands.value = [];
    }
  });

  const unitLessons = (lessonIds) => {
    return props.lessons.filter( (lesson) => lessonIds.includes(lesson.id) );
  };

  const applyFilters = () => {
    let contentEndPoint = props.sharedActivityCreators ? 'shared_content' : 'mycontent';
    let url = `${window.location.origin}/instructor/${contentEndPoint}/${props.programId}`;

    const params = new URLSearchParams({
      selected_lesson_ids: selectedLessons.value.join(','),
      selected_strands: selectedStrands.value.join(','),
      selected_types: selectedTypes.value.join(','),
      selected_shared_activity_creator_ids: selectedSharedActivityCreators.value.join(','),
      filtered: true
    });

    window.location.href = `${url}?${params.toString()}`;
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  :deep(.c-filter-bg-white) {
    background-color: #FFFFFF; 
  }

  :deep(.c-filter-bg-white:hover) {
    background-color: #F8EFEE !important;
  }

  :deep(.c-menu__inner) {
    height: auto;
    max-height: rpx(300);
    overflow: hidden;
    width: 100%;
    word-wrap: break-word;
  }

  :deep(.c-menu__inner-scroll) {
    height: 100%;
    overflow-y: auto;
    padding-right: 10px;
    padding-left: 5px;
  }

  :deep(.c-menu__inner-scroll::-webkit-scrollbar) {
    width: .25rem;
  }

  :deep(.c-menu__inner-scroll::-webkit-scrollbar-thumb) {
    background-color: #AA3127;
    border-radius: .125rem;
  }

  :deep(.c-menu__inner-scroll::-webkit-scrollbar-track) {
    background-color: #BFBFBF;
    border-radius: .125rem;
  }
</style>
