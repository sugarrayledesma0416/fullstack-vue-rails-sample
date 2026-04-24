<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">Reference tools</h3>
    </div>
    <div class=c-panel__body>
      <div class="c-form-item">
        <button
          class="js-add-ref-setting  c-button  c-button--primary"
          :class="testClass('add-ref-setting')"
          type="button"
          @click="addRefSetting">
          Add setting
        </button>
      </div>
      <div v-for="(setting, settingIndex) in currentSettingsStore" :key="settingIndex">
        <fieldset class="u-mar-top-16">
          <div class="c-form-item">
            <label :for="`setting_label_${settingIndex}`" class="c-form-item__label">Tool label</label>
            <input
              v-model="setting.label"
              class="c-form-item__input  u-width-full"
              :class="testClass(`setting-label-${settingIndex}`)"
              name="datastore[settings][][label]"
              type="text">
          </div>
          <div class="c-form-item">
            <label :for="`setting_link_${settingIndex}`" class="c-form-item__label">Tool url</label>
            <input
              v-model="setting.link"
              class="c-form-item__input  u-width-full"
              :class="testClass(`setting-link-${settingIndex}`)"
              name="datastore[settings][][link]"
              type="text">
          </div>
          <div class="c-form-item  u-mar-top-16">
            <button
              class="remove_setting  c-button  c-button--primary"
              :class="[
                testClass(`remove-ref-setting-${settingIndex}`),
                testClass('remove-setting-btn')
              ]"
              type="button"
              @click="removeRefSetting(settingIndex)">
              Remove setting
            </button>
          </div>
          <!-- Only setting type for now is: link -->
          <input
            v-model="setting.type"
            name="datastore[settings][][type]"
            type="hidden">
        </fieldset>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { reactive } from 'vue';

  export default {
    name: 'ReferenceToolSettings',
    props: {
      currentSettings: { required: true, type: Array },
    },
    setup(props) {
      const currentSettingsStore = reactive(props.currentSettings);
      const addRefSetting = () => {
        currentSettingsStore.push({ label: '', link: '', type: 'link' });
      };

      const removeRefSetting = (index) => {
        if (index > -1) currentSettingsStore.splice(index, 1);
      };

      return { addRefSetting, currentSettingsStore, removeRefSetting, testClass };
    },
  };
</script>
