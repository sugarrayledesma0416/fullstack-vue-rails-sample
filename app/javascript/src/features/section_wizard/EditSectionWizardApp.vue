<template>
  <div class="ns-music-v1">
    <a
      v-if="datastore.section && datastore.section.course"
      class="return-to-dashboard"
      :href="`/instructor/dashboard/${datastore.section.course.programId}`">
      Return to Dashboard
    </a>
    <form name="section_form" class="main" :class="testClass('edit-section-form')">
      <h1 class="c-heading--md">
        Edit section
      </h1>
      <div class="wizard_content  ui-helper-clearfix">
        <SectionInformationStep
          v-if="datastore.section.course"
          :loadingImg="loadingImg"
          :remainingTimeZones="remainingTimeZones"
          :timeZones="timeZones" />
      </div>
    </form>
  </div>
</template>

<script>
  import { provide, reactive } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import { testClass } from 'music';
  import * as ajaxUtils from 'shared/ajax_utils';
  import SectionInformationStep from './components/SectionInformationStep';
  import { Section } from './models/section';
  import FlashMessageState from 'shared/flash_message_state';
  import useSectionWizard from './components/useSectionWizard';

  /**
   * This composable has methods for fetching section data for edit section wizard.
   * @param {Object} datastore - Vue js reactive object to store app state
   * @return {Object} - An object wrapping following methods
   * getSectionData,
   */
  const useEditSection = (datastore) => {
    /**
     * Fetch section data and initialize section in datastore
     * @return {Promise} - promise that gets the section initial data.
     */
    function getSectionData() {
      const url = location.href.replace(/#.*/, '') + '.json';
      return new Promise((resolve) => {
        ajaxUtils.getFromEndpoint(
          url,
          (response) => {
            datastore.section = new Section();
            datastore.section.init(response);
            datastore.initialData = JSON.stringify(datastore.section);
          }
        );
      });
    }
    return { getSectionData };
  };

  export default {
    name: 'EditSectionWizardApp',
    components: { SectionInformationStep },
    props: {
      currentUserRostering: { default: false, type: Boolean },
      loadingImg: { required: true, type: String },
      remainingTimeZones: { required: true, type: Array },
      timeZones: { required: true, type: Object },
    },
    setup(props) {
      const datastore = reactive({
        section: {},
        initialData: null,
      });
      const flashMessageState = new FlashMessageState();
      const config = {
        currentUserRostering: props.currentUserRostering,
        instAdmin: metaTagContent('VHL.in_institution_admin') === 'true',
        schoolId: metaTagContent('VHL.course_school_id'),
        mode: 'edit_section',
      };
      const { getSectionData } = useEditSection(datastore);
      const { addConfirmEventListenerOnPageLeave } = useSectionWizard(datastore);

      getSectionData();
      addConfirmEventListenerOnPageLeave();

      provide('datastore', datastore);
      provide('config', config);
      provide('flashMessageState', flashMessageState);
      return { datastore, testClass };
    },
  };
</script>
