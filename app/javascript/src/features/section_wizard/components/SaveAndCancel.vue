<template>
  <div>
    <img
      v-show="datastore.section.saving"
      class="save-spinner"
      :src="loadingImg">
    <div class="u-pad-top-24">
      <div class="l-inline-group">
        <div v-if="config.mode === 'edit_section'" class="update">
          <button
            type="submit"
            class="c-button  c-button--primary  is-navigable"
            :disabled="!datastore.section.isValid || !hasChanges"
            @click.prevent="datastore.section.update(flashMessageState)">
            Update
          </button>
        </div>

        <div
          v-if="config.mode === 'new_section'"
          class="save">
          <button
            type="submit"
            class="c-button  c-button--primary"
            :class="[
              {'is-navigable': !datastore.section.hasError.value},
              testClass('submit-btn')
            ]"
            :disabled="datastore.section.hasError.value || !datastore.section.name"
            @click.prevent="!datastore.section.hasError.value && datastore.section.save()">
            Submit
          </button>
        </div>
        <div>
          <a
            :class="testClass('cancel-button')"
            :href="cancelBtnUrl">
            <button type="button" class="c-button  is-navigable">
              cancel
            </button>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'SaveAndCancel',
    props: {
      loadingImg: { required: true, type: String },
    },
    setup(props) {
      const datastore = inject('datastore');
      const config = inject('config');
      const flashMessageState = inject('flashMessageState');
      const isSubmitEnabled = computed(() => {
        return datastore.section.name && datastore.section.name.length <= 75;
      });

      const hasChanges = computed(() => {
        return datastore.initialData !== JSON.stringify(datastore.section);
      });

      const cancelBtnUrl = computed(() => {
        if (config.instAdmin) {
          return `/institution_admin/templates/${datastore.section.course.program_id}` +
            `?school_id=${config.schoolId}`;
        } else {
          return `/instructor/dashboard/${datastore.section.course.program_id}`;
        }
      });

      return {
        cancelBtnUrl,
        config,
        datastore,
        flashMessageState,
        hasChanges,
        isSubmitEnabled,
        testClass,
      };
    },
  };
</script>
