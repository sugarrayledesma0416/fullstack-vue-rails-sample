<template>
  <div ref="disclosureContainer" class="u-mar-bot-20" :class="testClass('skills-container')">
    <h3 class="content-filter" :class="testClass('skills-header')">
      Skills
    </h3>
    <BasicDisclosure
      variant="end"
      class="skills-dropdown"
      :expanded="isExpanded"
      :float="true"
      :headerTextClosed="dropdownText"
      :headerTextOpen="dropdownText"
      :class="testClass('skills-dropdown')"
      @disclosureClick="toggleExpanded">
      <template #caret>
        <span class="triangle-icon" :class="testClass('skills-caret')">
          <TriangleIcon />
        </span>
      </template>
      <template #default>
        <div class="deselect-all-container">
          <button
            :disabled="!isAnySkillSelected"
            class="deselect-all"
            :class="testClass('deselect-all-button')"
            @click.prevent="deselectAll">
            Deselect All
          </button>
        </div>
        <div class="skills-options" :class="testClass('skills-options-container')">
          <div
            v-for="(skill, index) in skills"
            :key="skill.name"
            class="skill-option"
            :class="testClass('skill-option')">
            <div
              class="skill-label"
              :class="testClass('skill-label')">
              <BasicCheckbox
                :id="`skill-${index}`"
                :class="testClass('skill-checkbox')"
                :modelValue="selectedSkills.includes(skill.name)"
                @click.stop="handleSkillToggle(skill)">
                {{ skill.name }}
              </BasicCheckbox>
            </div>
            <div
              v-if="isRefinementVisible(skill)"
              class="refinements-container"
              :class="testClass('refinements-container')">
              <div
                v-for="(refinement, subIndex) in skill.refinements"
                :key="refinement"
                class="refinement"
                :class="testClass('refinement')">
                <BasicCheckbox
                  :id="`refinement-${index}-${subIndex}`"
                  :class="testClass('refinement-checkbox')"
                  :checked="selectedRefinements.includes(refinement)"
                  @click.stop="handleRefinementToggle(skill, refinement)">
                  {{ refinement }}
                </BasicCheckbox>
              </div>
            </div>
          </div>
        </div>
      </template>
    </BasicDisclosure>
  </div>
</template>

<script setup>
  import { computed, ref, watch } from 'vue';
  import { testClass } from 'music';
  import BasicCheckbox from 'music/app/javascript/src/components/basic_checkbox/v2.0/BasicCheckbox';
  import BasicDisclosure from
  'music/app/javascript/src/components/basic_disclosure/v1.1/BasicDisclosure';
  import skillsData from './skills.json';
  import TriangleIcon from
  '../../gradebook/standards/section_report_filters/components/TriangleIcon.vue';
  import useStandardsAssigningStore from '../models/use_standards_assigning_store.js';

  const disclosureContainer = ref(null);
  const isExpanded = ref(false);
  const store = useStandardsAssigningStore();

  const emit = defineEmits(['applyFilter']);

  const selectedSkills = computed(() => store.getSelectedSkills);
  const selectedRefinements = computed(() => store.getSelectedRefinements);
  const visibleRefinements = computed(() => store.getVisibleRefinements);
  const skills = skillsData;

  const isAnySkillSelected = computed(() => selectedSkills.value.length > 0);

  const dropdownText = computed(() => {
    const selectedTopLevelSkills = selectedSkills.value.filter((skill) =>
      skills.some((topSkill) => topSkill.name === skill)
    );

    if (selectedTopLevelSkills.length === 0) return 'Select Skill';
    const text = selectedTopLevelSkills.join(', ');

    const maxLength = 35;
    return text.length > maxLength ? `${text.slice(0, maxLength)}...` : text;
  });

  /**
   * Checks if the refinements for a given skill should be visible.
   *
   * @param {Object} skill - The skill object containing the refinements.
   * @return {boolean} - True if the refinements should be visible, false otherwise.
   */
  function isRefinementVisible(skill) {
    return skill.refinements?.length && visibleRefinements.value[skill.name];
  }

  /**
   * Toggles the expanded state of the dropdown.
   */
  function toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  /**
   * Toggles the selection of a refinement within a skill.
   *
   * @param {Object} skill - The skill object containing the refinement.
   * @param {string} refinement - The refinement to be toggled.
   */
  function handleRefinementToggle(skill, refinement) {
    const updatedRefinements = new Set(store.selectedRefinements);
    const updatedSkills = new Set(store.selectedSkills);

    if (refinement && updatedRefinements.has(refinement)) {
      updatedRefinements.delete(refinement);
    } else if (refinement) {
      updatedRefinements.add(refinement);
      if (skill.name) {
        updatedSkills.add(skill.name);
      }
    }

    if (skill.refinements && skill.refinements.length > 0) {
      const anyRefinementsSelected = skill.refinements.some((sub) => updatedRefinements.has(sub));
      if (!anyRefinementsSelected && skill.name) {
        updatedSkills.delete(skill.name);
      }
    }

    const filteredRefinements = [...updatedRefinements].filter(
      (refinement) => refinement !== undefined
    );
    const filteredSkills = [...updatedSkills].filter((skill) => skill !== undefined);

    store.setSelectedRefinements(filteredRefinements);
    store.setSelectedSkills(filteredSkills);

    if (skill.refinements && skill.refinements.length > 0) {
      const anyRefinementsSelected = skill.refinements.some(
        (sub) => filteredRefinements.includes(sub)
      );
      if (!anyRefinementsSelected) {
        store.setVisibleRefinements({
          ...visibleRefinements.value,
          [skill.name]: false,
        });
      }
    }

    emit(
      'applyFilter',
      store.selectedTocItems,
      selectedSkills.value,
      selectedRefinements.value
    );
  }

  /**
   * Toggles the selection of a skill and its refinements.
   *
   * @param {Object} skill - The skill object containing the refinements.
   */
  function handleSkillToggle(skill) {
    const skillIndex = selectedSkills.value.indexOf(skill.name);

    if (skillIndex === -1) {
      store.setVisibleRefinements({
        ...visibleRefinements.value,
        [skill.name]: true,
      });

      store.setSelectedSkills([...store.selectedSkills, skill.name]);

      if (skill.refinements?.length) {
        const updatedRefinements = [
          ...store.selectedRefinements,
          ...skill.refinements.filter(
            (refinement) => !store.selectedRefinements.includes(refinement)
          ),
        ];
        store.setSelectedRefinements(updatedRefinements);
      }
    } else {
      const updatedSkills = store.selectedSkills.filter((s) => s !== skill.name);
      store.setSelectedSkills(updatedSkills);

      if (skill.refinements?.length) {
        const updatedRefinements = store.selectedRefinements.filter(
          (s) => !skill.refinements.includes(s)
        );
        store.setSelectedRefinements(updatedRefinements);
      }
      const anyRefinementsSelected = skill.refinements.some(
        (sub) => store.selectedRefinements.includes(sub)
      );
      store.setVisibleRefinements({
        ...visibleRefinements.value,
        [skill.name]: anyRefinementsSelected,
      });
    }
    emit(
      'applyFilter',
      store.selectedTocItems,
      selectedSkills.value,
      selectedRefinements.value
    );
  }

  /**
   * Deselects all skills and refinements.
   */
  function deselectAll() {
    store.setSelectedSkills([]);
    store.setSelectedRefinements([]);
    store.setVisibleRefinements({});

    emit(
      'applyFilter',
      store.selectedTocItems,
      selectedSkills.value,
      selectedRefinements.value
    );
  }

  /**
   * Handles clicks outside the disclosure container to close the dropdown.
   *
   * @param {Event} event - The click event.
   */
  function handleClickOutside(event) {
    if (disclosureContainer.value && !disclosureContainer.value.contains(event.target)) {
      isExpanded.value = false;
    }
  }

  watch(isExpanded, (newVal) => {
    if (newVal) {
      document.addEventListener('click', handleClickOutside);
    } else {
      document.removeEventListener('click', handleClickOutside);
    }
  });
</script>

<style lang="scss" scoped>
  @use 'music/app/styles/library/base';
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .skills-dropdown {
    font-size: rpx(16);
    width: 100%;
    z-index: 2;
  }

  .content-filter {
    color: $lightest-text;
    font-size: rpx(16);
    font-weight: normal;
    letter-spacing: rpx(1);
    margin-bottom: rpx(5);
    text-transform: uppercase;
  }

  .deselect-all-container {
    display: flex;
    justify-content: flex-end;
  }

  .deselect-all {
    background: none;
    border: none;
    color: #006bae;
    cursor: pointer;
    display: inline-block;
    letter-spacing: rpx(1);
    margin-top: rpx(10);
    padding-right: rpx(8);
    text-align: right;
    text-underline-offset: 0.5em;

    &:focus,
    &:active {
      border: none;
      outline: none;
    }

    &:hover {
      text-decoration: underline;
    }
    &:disabled {
      color: #ccc;
      cursor: not-allowed;
      text-decoration: none;
    }
  }

  .skills-options {
    color: #333;
    background: white;
    padding: rpx(10);
  }

  .skill-label {
    padding-bottom: rpx(10);
    padding-top: rpx(10)
  }

  .skill-set {
    color: #333;
    font-size: rpx(16);
    font-weight: normal;
    margin-left: rpx(10);
  }

  .skill-option {
    border-bottom: rpx(1) solid #ddd;
    margin-bottom: rpx(5);

    &:last-child {
      border-bottom: none;
    }
  }

  .refinements-container {
    margin-left: rpx(20);
  }

  .refinement {
    border-bottom: rpx(1) solid #ddd;
    margin-left: rpx(12);
    padding: rpx(10) 0;

    &:last-child {
      border-bottom: none;
    }
  }

  [class] :deep(.basic-checkbox__input) {
    @include base.appearance-none();

    background-color: base.$white;
    background-size: 100% 100%;
    border: base.rpx(1) solid #8e8e8e;
    border-radius: 0;
    height: rpx(20);
    transition: opacity 0.2s;
    width: rpx(20);

    &:hover {
      border-color: base.$gray-3;
    }

    &:checked {
      background-image: url('~MusicAssets/images/music/icons/check.svg');
      border-color: base.$gray-3;
    }
  }

  [class] :deep(.basic-checkbox__label) {
    font-weight: normal;
    pointer-events: none;
  }

  [class] :deep(.expandable-body) {
    width: 100%;
  }

  [class] :deep(.disclosure__button) {
    border: #{base.rpx(1)} solid #{base.$gray-d};
    border-radius: #{base.rpx(3)};
    font-family: inherit;
    font-size: #{base.$font-size-16};
    font-style: italic;
    height: rpx(42);
    line-height: #{base.rpx(36)};
    padding: #{base.rpx(4)};

    &:not([disabled]) {
      &:hover {
        background-color: #{base.$gray-f8};
      }
    }

    & .embedded-icon .triangle-icon svg {
      --fill: #{base.$gray-6};
    }

    &[disabled] .embedded-icon .triangle-icon svg {
      --fill: var(--embedded-icon-disabled-color);
    }
  }

  [class] :deep(.disclosure__button .disclosure-header-text) {
    --disclosure-header-text-color: #{base.$black};
    --disclosure-header-text-style: none;
    --disclosure-header-text-case: capitalize;
    padding-left: rpx(8);
  }

  [class] :deep(.disclosure__button[disabled]) {
    cursor: not-allowed;
  }

  [class] :deep(.disclosure__button[disabled] .disclosure-header-text) {
    color: #{base.$link-disabled-color};
  }

  [class] :deep(.embedded-icon .triangle-icon svg) {
    bottom: rpx(2.24);
    display: block;
    left: rpx(16);
    position: relative;
    width: rpx(10);
  }

  [class] :deep(.disclosure__image) {
    margin-right: #{base.rpx(15)};
    rotate: 0deg;
  }

  [class] :deep(.is-expanded .disclosure__image) {
    rotate: 0deg !important;
  }

  [class] :deep(.disclosure__button-content) {
    justify-content: space-between;
  }

  [class] :deep(.is-floater) {
    left: 0;
    position: relative;
    top: 0;
    width: 100%;
    z-index: 2;
  }
</style>
