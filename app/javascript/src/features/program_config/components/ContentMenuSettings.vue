<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">Enable/Disable content menu features</h3>
    </div>
    <div class="c-panel__body">
      <fieldset>
        <div class="c-form-item">
          <input
            id="vocab_tools_enabled"
            type="checkbox"
            name="vocab_tools_enabled"
            value=""
            class="c-form-item__checkbox"
            :checked="vocabToolsEnabled"
            :class="testClass('vocab-tools')"
            @change="$emit('updateHideTranslation', { event: $event });">
          <label
            for="vocab_tools_enabled"
            class="c-form-item__label">
            Vocabulary Tools
          </label>
        </div>
        <div class="c-form-item">
          <button
            id="update_vocab_tools"
            type="button"
            class="c-button  c-button--primary"
            @click="updateVocabTools($event, programId )">
            Activate/Update Vocab Tools
          </button>
          <span
            class="u-mar-lt-8"
            :class="testClass('vocab_tools_status')">
            {{ dataStore.vocabToolsStatus }}
          </span>
        </div>
        <div class="c-form-item">
          <label
            for="datastore_vocab_tools"
            class="c-form-item__label">
            Override Vocab tools title for Content Menu
          </label>
          <input
            id="datastore_vocab_tools"
            v-model="dataStore.vocabTools"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[vocab_tools]"
            :class="testClass('input-vocab-tools')">
        </div>
        <div class="c-form-item">
          <label
            for="datastore_ebook"
            class="c-form-item__label">
            Override eBook title for Content Menu
          </label>
          <input
            id="datastore_ebook"
            v-model="dataStore.ebook"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[ebook]"
            :class="testClass('input-ebook')">
        </div>
      </fieldset>
      <fieldset class="u-mar-top-16">
        <div class="c-form-item">
          <label
            for="datastore_vtext_type"
            class="c-form-item__label">
            Virtual textbook type
          </label>
          <select
            id="datastore_vtext_type"
            v-model="dataStore.vtextType"
            name="datastore[vtext][type]"
            class="c-select"
            :class="testClass('input-vtext-type')">
            <option value="vText">
              vText
            </option>
            <option value="eCompanion">
              eCompanion
            </option>
          </select>
        </div>
        <div class="c-form-item">
          <label
            for="datastore_vtext_url"
            class="c-form-item__label">
            {{dataStore.vtextType}} url
          </label>
          <input
            id="datastore_vtext_url"
            v-model="dataStore.vtextUrl"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[vtext][url]"
            :class="testClass('input-vtext-url')">
        </div>
        <div class="c-form-item">
          <label class="c-form-item__label">Page Number Prefix</label>
          <input
            type="text"
            class="c-form-item__input  u-width-full"
            value="v1"
            disabled
            readonly>
        </div>
        <div class="c-form-item">
          <label
            for="datastore_vtext_label"
            class="c-form-item__label">
            Override {{dataStore.vtextType}} label for Content Menu
          </label>
          <input
            id="datastore_vtext_label"
            v-model="dataStore.vtextLabel"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[vtext_label]"
            :class="testClass('input-vtext-label')">
        </div>
      </fieldset>
      <fieldset class="u-mar-top-16">
        <div class="c-form-item">
          <label
            for="datastore_teacher_vtext_url"
            class="c-form-item__label">
            Teacher edition vText url
          </label>
          <input
            id="datastore_teacher_vtext_url"
            v-model="dataStore.teacherVtextUrl"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[teacher_vtext][url]"
            :class="testClass('input-teacher-vtext-url')">
        </div>
        <div class="c-form-item">
          <label class="c-form-item__label">Page Number Prefix</label>
          <input
            type="text"
            class="c-form-item__input  u-width-full"
            value="v2"
            disabled
            readonly>
        </div>
        <div class="c-form-item">
          <label
            for="datastore_teacher_vtext_label"
            class="c-form-item__label">
            Override Instructor's Manual label for Content Menu
          </label>
          <input
            id="datastore_teacher_vtext_label"
            v-model="dataStore.teacherVtextLabel"
            type="text"
            class="c-form-item__input  u-width-full"
            name="datastore[teacher_vtext_label]"
            :class="testClass('input-teacher-vtext-label')">
        </div>
      </fieldset>
      <div :class="testClass('entry-container')">
        <button
          type="button"
          class="c-button  c-button--primary  is-navigable  u-mar-top-20"
          :class="testClass('add-additional-entry')"
          @click="addAdditionalEntry">
          Add additional entry
        </button>
        <AdditionalEntry
          v-for="(additionalEntry, index) in dataStore.additionalEntries"
          :key="index"
          :modelValue="additionalEntry"
          :index="index"
          @update:modelValue="updateAdditionalEntry"
          @removeAdditionalEntry="removeAdditionalEntry" />
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { testClass } from 'music';
  import AdditionalEntry from './AdditionalEntry';
  import useContentMenuSettings from './use_content_menu_settings';

  export default {
    name: 'ContentMenuSettings',
    components: { AdditionalEntry },
    props: {
      additionalEntries: { default: () => [], type: Array },
      ebook: { default: '', type: String },
      teacherVtextLabel: { default: '', type: String },
      teacherVtextUrl: { default: '', type: String },
      vocabTools: { default: '', type: String },
      vocabToolsEnabled: { default: false, type: Boolean },
      vtextLabel: { default: '', type: String },
      vtextType: { default: 'vText', type: String },
      vtextUrl: { default: '', type: String },
    },
    emits: ['updateHideTranslation'],
    setup(props) {
      const dataStore = reactive({
        additionalEntries: [],
        ebook: props.ebook,
        teacherVtextLabel: props.teacherVtextLabel,
        teacherVtextUrl: props.teacherVtextUrl,
        vocabTools: props.vocabTools,
        vocabToolsStatus: '',
        vtextLabel: props.vtextLabel,
        vtextType: props.vtextType,
        vtextUrl: props.vtextUrl,
      });

      const programId = inject('programId');
      const data = { ...props, ...{ programId }};

      const {
        addAdditionalEntry,
        initialAdditionalEntries,
        removeAdditionalEntry,
        updateVocabTools,
      } = useContentMenuSettings(data, dataStore);

      dataStore.additionalEntries = initialAdditionalEntries();

      /**
       * Update additionalEntry in datastore at the given index
       * @param {Object} payload - Event payload
       * @param {Object} payload.entry - AdditionalEntry object
       * @param {number} payload.index - Index of given AdditionalEntry in the list in datastore
       */
      const updateAdditionalEntry = (payload) => {
        const { entry, index } = payload;
        dataStore.additionalEntries[index] = entry;
      };

      return {
        addAdditionalEntry,
        dataStore,
        programId,
        removeAdditionalEntry,
        testClass,
        updateAdditionalEntry,
        updateVocabTools,
      };
    },
  };
</script>
