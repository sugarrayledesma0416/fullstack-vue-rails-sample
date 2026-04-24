<template>
  <fieldset class="u-mar-top-16">
    <div class="c-form-item">
      <label class="c-form-item__label">Page Number Prefix</label>
      <input
        type="text"
        class="c-form-item__input  u-width-full"
        :value="`v${index + 3}`"
        disabled
        readonly>
    </div>

    <div class="c-form-item">
      <label
        :for="`${elementPrefix}_url`"
        class="c-form-item__label">
        Additional entry {{ index + 1 }} url
      </label>

      <input
        :id="`${elementPrefix}_url`"
        name="datastore[content_menu_additional_entries][][url]"
        type="text"
        class="c-form-item__input  u-width-full"
        :class="testClass('additional-entry-url')"
        :value="modelValue.url"
        @input="additionalEntry.url = $event.target.value">
    </div>

    <div class="c-form-item">
      <label
        :for="`${elementPrefix}_label`"
        class="c-form-item__label">
        Additional entry {{ index + 1 }} label
      </label>

      <input
        :id="`${elementPrefix}_label`"
        name="datastore[content_menu_additional_entries][][label]"
        type="text"
        class="c-form-item__input  u-width-full"
        :class="testClass('additional-entry-label')"
        :value="modelValue.label"
        @input="additionalEntry.label = $event.target.value">
    </div>

    <div class="c-form-item">
      <label
        :for="`${elementPrefix}_description`"
        class="c-form-item__label">
        Additional entry {{ index + 1 }} description
      </label>

      <select
        :id="`${elementPrefix}_description`"
        name="datastore[content_menu_additional_entries][][description]"
        class="c-select"
        :class="testClass('additional-entry-description')"
        :value="modelValue.description"
        @input="additionalEntry.description = $event.target.value">
        <option v-for="option in studentVtextOptions">
          {{ option }}
        </option>
        <option v-for="option in teacherVtextOptions">
          {{ option }}
        </option>
      </select>
    </div>

    <div class="c-form-item">
      <label
        :for="`${elementPrefix}_target_user`"
        class="c-form-item__label">
        Additional entry {{ index + 1 }} will be for
      </label>

      <select
        :id="`${elementPrefix}_target_user`"
        name="datastore[content_menu_additional_entries][][target_user]"
        :value="modelValue.targetUser"
        class="c-select"
        :class="testClass('additional-entry-target-user')"
        @change="additionalEntry.targetUser = $event.target.value">
        <option
          v-for="(option, optionIndex) in optionsData"
          :key="optionIndex"
          :value="option">
          {{ option }}
        </option>
      </select>
    </div>

    <div class="c-form-item">
      <label
        :for="`${elementPrefix}_program_id`"
        class="c-form-item__label">
        Additional entry {{ index + 1 }} program id
      </label>
      <div class="c-form-item__hint  u-mar-4  u-txt-ital">
        (optional, only needed if different from main program id)
      </div>

      <input
        :id="`${elementPrefix}_program_id`"
        name="datastore[content_menu_additional_entries][][program_id]"
        type="number"
        class="c-form-item__input  u-width-full"
        :class="testClass('additional-entry-program-id')"
        :value="modelValue.programId"
        @input="additionalEntry.programId = $event.target.value">
    </div>

    <div class="c-form-item  u-mar-top-16">
      <button
        type="button"
        class="c-button  c-button--primary c-button--border  is-navigable"
        :class="testClass('remove-additional-entry')"
        @click="$emit('removeAdditionalEntry', { event: $event, entryIndex: index })">
        Remove entry
      </button>
    </div>
  </fieldset>
</template>

<script setup>
  import { watch, reactive, toRefs } from 'vue';
  import { testClass } from 'music';
  import { studentVtextOptions, teacherVtextOptions } from './vtext_options';
  const props = defineProps(
    {
      modelValue: { default: () => {}, type: Object },
      index: { default: 0, type: Number },
    }
  );
  const emit = defineEmits(
    ['removeAdditionalEntry', 'update:modelValue']
  );

  const additionalEntry = reactive(props.modelValue);
  additionalEntry.targetUser = additionalEntry.targetUser || 'Instructor';
  const { label, targetUser, url, programId, description } = toRefs(additionalEntry);

  const elementPrefix = `content_menu_additional_entry_${props.index + 1}`;
  const optionsData = ['Instructor', 'Student'];

  /**
   * Watch change in additionalEntry local state and trigger 'update:modelValue'
   * so parent component can sync additionalEntry list data.
   */
  watch(
    [label, targetUser, url, programId, description],
    (newValue) => {
      const entry = {
        label: newValue[0],
        targetUser: newValue[1],
        url: newValue[2],
        programId: newValue[3],
        description: newValue[4],
      };
      const payload = { entry, index: props.index };
      emit('update:modelValue', payload);
    }
  );
</script>

<style scoped>
  input[type="text"].number-input {
    width: 120px;
  }
</style>
