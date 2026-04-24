<template>
  <div>
    <div class="u-mar-bot-16  u-mar-top-12">
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlCheckbox
        :id="`component_${component.name}`"
        v-model:checked="courseDataStore.store.course.shareToPortfolio"
        :class="testClass('allow-share-portfolio')"
        name="component"
        testSelectorInput="component-checkbox"
        @update:checked="toggleComponent(component);">
        <span :class="is_enterprise ? 'u-txt-16  u-txt-gray-3' : 'u-txt-bold'">{{ component.name }}</span>
        <p :class="is_enterprise ? 'u-txt-16  u-txt-gray-3' : ''">
          Create a Portfolio account for each student enrolled in this course.
          Students will be able to send <br> submitted Composition, Solo Video Record,
          and Video Virtual Chat activities to their Portfolio.
        </p>
        <ContentSetting 
          v-if="courseDataStore.store.course.shareToPortfolio" 
          class="u-pad-lt-14" 
          title="Include Partner and Group Chat">
          <!-- eslint-disable vue/no-v-model-argument -->
          <VhlRadioButton
            v-for="option in includeChatOptions"
            id="include_chat_activity"
            :key="option.value"
            v-model:modelValue="isChatActivityIncluded"
            name="include_chat_activity"
            :text="option.text"
            :value="option.value"
            class="test-include_chat_activity  u-dis-block"
            :class="is_enterprise ? 'u-txt-16  u-txt-gray-3' : ''"
            @change="toggleConfirmDialog"/>
            <!-- eslint-enable vue/no-v-model-argument -->
        </ContentSetting>
      </VhlCheckbox>
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
    <PortfolioConfirmDialog
      v-if="showConfirmDialog"
      @close="updatePortfolioActivityTypes(false)"
      @confirm="updatePortfolioActivityTypes(true)"/>
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { inject, ref } from 'vue';
  import ContentSetting from '../ContentSetting';
  import PortfolioConfirmDialog from './PortfolioConfirmDialog';
  import VhlCheckbox from '../../VhlCheckbox';
  import VhlRadioButton from '../../VhlRadioButton';

  const courseDataStore = inject('courseDataStore');
  const props = defineProps({
    component: { default: null, type: Object },
    is_enterprise: { default: false, type: Boolean }
  });

  const setDefaultPortfolioActivityTypes = () => {
    if (courseDataStore.store.course.portfolioActivityTypes === null ||
      courseDataStore.store.course.portfolioActivityTypes === undefined ) {
      courseDataStore.store.course.portfolioActivityTypes = {
        'composition': false,
        'group_chat': false,
        'info_gap_partner_chat': false,
        'partner_chat': false,
        'solo_video_recording': false,
        'video_virtual_chat': false,
      };
    }
  };
  setDefaultPortfolioActivityTypes();

  const isChatActivityIncluded = ref(
    !!courseDataStore.store.course.portfolioActivityTypes['partner_chat']
  );

  const showConfirmDialog = ref(false);

  const includeChatOptions = [
    { text: 'Do not include', value: false },
    { text: 'Include', value: true },
  ];

  const onshareToPortfolioUpdate = () => {
    setDefaultPortfolioActivityTypes();

    if (courseDataStore.store.course.shareToPortfolio) {
      courseDataStore.store.course.portfolioActivityTypes['solo_video_recording'] = true;
      courseDataStore.store.course.portfolioActivityTypes['composition'] = true;
      courseDataStore.store.course.portfolioActivityTypes['video_virtual_chat'] = true;
    } else {
      courseDataStore.store.course.portfolioActivityTypes = {};
    }
  };

  const toggleConfirmDialog = (evt) => {
    if (evt.target.value === 'true') {
      showConfirmDialog.value = true;
    } else {
      setDefaultPortfolioActivityTypes();

      showConfirmDialog.value = false;
      courseDataStore.store.course.portfolioActivityTypes['info_gap_partner_chat'] = false;
      courseDataStore.store.course.portfolioActivityTypes['partner_chat'] = false;
      courseDataStore.store.course.portfolioActivityTypes['group_chat'] = false;
      isChatActivityIncluded.value = false;
    }
  };

  const updatePortfolioActivityTypes = (value) => {
    setDefaultPortfolioActivityTypes();

    courseDataStore.store.course.portfolioActivityTypes['info_gap_partner_chat'] = value;
    courseDataStore.store.course.portfolioActivityTypes['partner_chat'] = value;
    courseDataStore.store.course.portfolioActivityTypes['group_chat'] = value;
    isChatActivityIncluded.value = value;
    showConfirmDialog.value = false;
  };

  function toggleComponent(component) {
    const index = courseDataStore.store.course.components.indexOf(component.id);
    if (index > -1) {
      courseDataStore.store.course.components.splice(index, 1);
    } else {
      courseDataStore.store.course.components.push(component.id);
    }
    onshareToPortfolioUpdate();
  }
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .portfolio-activity-types {
    margin-left: rpx(20);
  }
</style>
