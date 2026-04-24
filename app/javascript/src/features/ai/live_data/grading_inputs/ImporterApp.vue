<template>
  <div>
    <div class="grading-entries-wrapper">
      <div
        v-if="state.entries.length">
        <div
          v-for="(entry, index) in state.entries"
          :key="index"
          class="c-box  c-box--bubble-wrap">
          <Entry
          :entry="entry"
          :saveEntry="() => saveEntry(entry)" />
        </div>
      </div>
      <ButtonSecondary
        theme="vol"
        :disabled="!state.loadMoreUrl || state.isLoadingMoreResults"
        @click="loadMoreResults">
        {{ loadMoreResultsButtonLabel() }}
        <span class="c-embedded-icon">
          <MusicLoadingIndicator v-show="state.isLoadingMoreResults" />
        </span>
      </ButtonSecondary>
    </div>
  </div>
</template>

<script setup>
  import { provide, reactive } from 'vue';
  import { computed } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import ButtonSecondary from
  'music/app/javascript/src/components/button_secondary/v1.2/ButtonSecondary';
  import Entry from './Entry'
  import MusicLoadingIndicator from 'shared/vue/MusicLoadingIndicator'

  const props = defineProps(
    {
      loadMoreUrl: { required: true, type: String },
      saveEntryUrl: { required: true, type: String },
      entries: { required: true, type: String },
    }
  );

  const state = reactive(
    {
      entries: JSON.parse(props.entries),
      isLoadingMoreResults: false,
      loadMoreUrl: props.loadMoreUrl,
    }
  );

  loadMoreResults();

  /**
   * Return the label of the button used to load more results.
   */
  function loadMoreResultsButtonLabel() {
    if (state.isLoadingMoreResults) {
      return 'Loading results';
    } else if (state.loadMoreUrl) {
      return 'Load more results';
    } else {
      return 'No more results';
    }
  }

  /**
   * Makes an AJAX request to load more entries.
   */
  function loadMoreResults() {
    state.isLoadingMoreResults = true;
    ajaxUtils.getFromEndpoint(
      state.loadMoreUrl,
      (data) => {
        state.isLoadingMoreResults = false;
        if (data.errors) {
          data.errors.forEach((error) => console.log(error));
        } else {
          data.entries.forEach((entry) => state.entries.push(entry));
          state.loadMoreUrl = data.nextUrl;
        }
      }
    );
  }

  /**
   * @param {Entry} entry
   * Makes an AJAX request to save the entry.
   */
  function saveEntry(entry) {
    entry.isSaved = true;

    const url = `${props.saveEntryUrl}`;
    ajaxUtils.postToEndpoint(
      url,
      {
        attempt_id: entry.attemptId,
        question_label: entry.questionLabel
      },
      (data) => {
        if (data.errors) {
          data.errors.forEach((error) => console.log(error));
        }
      }
    );
  }
</script>
