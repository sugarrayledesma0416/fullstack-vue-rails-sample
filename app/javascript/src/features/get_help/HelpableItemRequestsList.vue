<template>
  <div
    v-if="requests.length > 0"
    :ref="el => { helpDisclosures[`${metaData.userType}-${helpableItemId}`] = el }"
    :class="`js-help-disclosure-${metaData.userType}-${helpableItemId}`"
    class="js-accent_bar_container">
    <div
      class="ns-music-v1  c-help-request  c-disclosure  js-help-request"
      :class="testClass('help-request-disclosure')">
      <button
        type="button"
        class="c-help-request-header  c-disclosure__header  c-no-button  js-help-request-header"
        :class="testClass('help-request-header')"
        aria-expanded="true"
        @click="toggleIcon()">
        <Icon class="c-embedded-icon--md-lg" :svg="fileSvgRequestDisclosureIcon" />
        View Student Request(s)
      </button>
      <div
        v-if="metaData.userType === 'Student'"
        class="c-disclosure__body  js-help-requests-container">
        <StudentRequestForHelp
          :helpableItemId="helpableItemId"
          @deleted="deleteRequests"
          @firstReqAdded="initRequests" />
      </div>
      <div v-else class="c-disclosure__body  js-help-requests-container">
        <InstructorHelpResponse :helpableItemId="helpableItemId" />
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, onMounted, ref } from 'vue';
  import { testClass } from 'music';
  import StudentRequestForHelp from './StudentRequestForHelp';
  import InstructorHelpResponse from './InstructorHelpResponse';
  import Icon from 'features/shared/Icon';
  import fileSvgRequestDisclosureIcon from '!!raw-loader!MusicAssets/images/music/v1/forms/caret.svg';

  const requestsDisclosure = (helpableItemId, metaData, requests, helpDisclosures) => {
    const deleteRequests = (emittedReqs) => {
      if (!emittedReqs.length) {
        requests.splice(0, requests.length);
      }
    };

    const initRequests = (emittedReq) => {
      if (emittedReq) {
        requests.push(emittedReq);
      }
    };

    const toggleIcon = () => {
      const toggleElement = getToggleElement();
      toggleElement.classList.toggle('is-collapsed');
    };

    const initializeRequests = () => {
      const toggleElement = getToggleElement();
      if (metaData.userType == 'Student') {
        toggleElement.classList.add('is-collapsed');
      }
    };

    const getToggleElement = () => {
      return helpDisclosures.value[`${metaData.userType}-${helpableItemId}`]
        .querySelector('.js-help-request-header');
    };

    return {
      initializeRequests, toggleIcon, deleteRequests, initRequests,
    };
  };

  export default {
    name: 'HelpableItemRequestsList',
    components: { StudentRequestForHelp, InstructorHelpResponse, Icon },
    props: {
      helpableItemId: {
        type: String,
        default: '',
      },
    },
    setup(props) {
      const { helpableItemId } = props;
      const metaData = inject('metaData');
      let requests = inject('requests');
      const helpDisclosures = ref([]);

      onMounted(() => {
        initializeRequests();
        if (VHL?.AccentBarComponentWrapper) new VHL.AccentBarComponentWrapper();
      });
      const { initializeRequests, toggleIcon, deleteRequests, initRequests } = requestsDisclosure(
        helpableItemId, metaData, requests, helpDisclosures
      );
      return {
        requests, metaData, testClass, fileSvgRequestDisclosureIcon,
        toggleIcon, helpDisclosures, deleteRequests, initRequests,
      };
    },
  };
</script>
