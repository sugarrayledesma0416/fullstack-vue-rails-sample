<template>
  <div>
    <div class="u-mar-bot-16">
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlCheckbox
        id="course_share_to_portfolio"
        v-model:checked="courseDataStore.store.course.shareToPortfolio"
        :class="testClass('allow-share-portfolio')"
        @change="onshareToPortfolioUpdate">
        Create a Portfolio account for each student enrolled in this course.
        Students can add Composition, Solo Video Recording,
        and Video Virtual Chat activities to their Portfolio.
      </VhlCheckbox>
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>

    <ContentSetting
      v-if="courseDataStore.store.course.shareToPortfolio"
      title="Include Partner and Group chat">
      <div class="portfolio-activity-types">
        <!-- eslint-disable vue/no-v-model-argument -->
        <VhlRadioButton
          v-for="option in includeChatOptions"
          id="include_chat_activity"
          :key="option.value"
          v-model:modelValue="isChatActivityIncluded"
          name="include_chat_activity"
          :text="option.text"
          :value="option.value"
          :class="testClass('include_chat_activity')"
          @change="toggleConfirmDialog" />
          <!-- eslint-enable vue/no-v-model-argument -->
      </div>
    </ContentSetting>

    <PortfolioConfirmDialog
      v-if="showConfirmDialog"
      @close="updatePortfolioActivityTypes(false)"
      @confirm="updatePortfolioActivityTypes(true)" />
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
  const isChatActivityIncluded = ref(
    !!courseDataStore.store.course.portfolioActivityTypes['partner_chat']
  );

  const showConfirmDialog = ref(false);

  const includeChatOptions = [
    { text: 'Do not include', value: false },
    { text: 'Include', value: true },
  ];

  const onshareToPortfolioUpdate = () => {
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
      showConfirmDialog.value = false;
      courseDataStore.store.course.portfolioActivityTypes['info_gap_partner_chat'] = false;
      courseDataStore.store.course.portfolioActivityTypes['partner_chat'] = false;
      courseDataStore.store.course.portfolioActivityTypes['group_chat'] = false;
      isChatActivityIncluded.value = false;
    }
  };

  const updatePortfolioActivityTypes = (value) => {
    courseDataStore.store.course.portfolioActivityTypes['info_gap_partner_chat'] = value;
    courseDataStore.store.course.portfolioActivityTypes['partner_chat'] = value;
    courseDataStore.store.course.portfolioActivityTypes['group_chat'] = value;
    isChatActivityIncluded.value = value;
    showConfirmDialog.value = false;
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .portfolio-activity-types {
    display: flex;
    flex-direction: column;
  }
</style>
