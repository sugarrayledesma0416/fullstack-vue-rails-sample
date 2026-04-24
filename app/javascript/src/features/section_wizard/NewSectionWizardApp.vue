<template>
  <div class="ns-music-v1">
    <form name="section_form">
      <h1 class="c-heading--md">
        Add section
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
   * Composition function for new section.
   * @param {Object} datastore - reactive object which will be available throughout the components.
   * @param {Object} datastore.section - section object.
   * @return {Object}
   */
  function useNewSection(datastore) {
    /**
     * It gets the data from the backend when initial page is load
     * @return {Promise} - promise that gets the section initial data.
     */
    function getSectionData() {
      return new Promise((resolve) => {
        ajaxUtils.getWithAcceptHeaders(
          location.href,
          (response) => {
            datastore.section = new Section();
            datastore.section.init(response);
            datastore.initialData = JSON.stringify(datastore.section);
          }
        );
      });
    }

    return { getSectionData };
  }

  export default {
    name: 'NewSectionWizardApp',
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
        mode: 'new_section',
      };

      const { getSectionData } = useNewSection(datastore);
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
