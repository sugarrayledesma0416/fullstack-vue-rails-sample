import { shallowMount } from '@vue/test-utils';
import VolConfigs from 'features/program_config/components/VolConfigs';
import DescriptionField from 'features/program_config/components/DescriptionField';

const volConfigs = {
  is_vista_online_learning: true,
  learning_tracks_options: [
    {
      explanation: '<p>enhance core instruction with cultural readings.</p>',
      label: 'Complete',
    },
    {
      explanation: '<p>focus on vocabulary and grammar.</p>',
      label: 'Essentials',
    },
  ],
  descriptions: {
    advanced_course: `
      <ul>
        <li>
          <p>
            Configure individual course settings and gradebook categories
            to fit your specific needs.
          </p>
        </li>
        <li>
          <p>Once completed, create individual assignments from the course content.</p>
        </li>
      </ul>
    `,
    express_course: `
      <ul>
        <li>
          <p>
            Copy, course settings, and gradebook categories from a course
            you previously created.
          </p>
        </li>
        <li>
          <p>
            <strong>Save time</strong> by selecting a Learning Track.
            Learning Tracks contain expertly-curated assignments, course settings,
            and gradebook categories to fit your style of course.
          </p>
        </li>
        <li>
          <p>All default selections may be modified as needed.</p>
        </li>
      </ul>
    `,
    general: '<p>Learning Tracks are pre-built courses created by curricular experts.</p>',
    header: '<p>Learning Track</p>',
    options_overall: '',
  },
};

const getWrapper = () => {
  return shallowMount(VolConfigs, {
    props: { volConfigs },
  });
};

const expectDescriptionFieldComponent = (index, props) => {
  expect(
    wrapper.findAllComponents(DescriptionField)[index].props().type
  ).toEqual(props.type);

  expect(
    wrapper.findAllComponents(DescriptionField)[index].props().value
  ).toEqual(props.value);
};

let wrapper;

describe('Settings for Vista Online Learning Program', () => {
  describe('I can see course setup description', () => {
    beforeEach(() => wrapper = getWrapper());

    it('contains a label of "Express Course"', () => {
      expect(wrapper.get('.test-express-course').text()).toEqual('Express Course');
    });

    it('contains Description Field child Component for "Express Course"', () => {
      expectDescriptionFieldComponent(0, {
        type: 'express_course',
        value: volConfigs.descriptions.express_course,
      });
    });

    it('contains a label of "Advanced Course"', () => {
      expect(wrapper.get('.test-advanced-course').text()).toEqual('Advanced Course');
    });

    it('contains Description Field child Component for "Advanced Course"', () => {
      expectDescriptionFieldComponent(1, {
        type: 'advanced_course',
        value: volConfigs.descriptions.advanced_course,
      });
    });
  });

  describe('I can see Learning tracks descriptions', () => {
    beforeEach(() => wrapper = getWrapper());

    it('contains a label of "Learning Tracks Header:"', () => {
      expect(wrapper.get('.test-learning-tracks-header').text()).toEqual('Header');
    });

    it('contains Description Field child Component for "Learning Tracks Header"', () => {
      expectDescriptionFieldComponent(2, {
        type: 'learning_tracks.header',
        value: volConfigs.descriptions.header,
      });
    });

    it('contains a label of "Learning Tracks Overview"', () => {
      expect(wrapper.get('.test-learning-tracks-general').text()).toEqual('Overview');
    });

    it('contains Description Field child Component for "Learning Tracks Overview"', () => {
      expectDescriptionFieldComponent(3, {
        type: 'learning_tracks.general',
        value: volConfigs.descriptions.general,
      });
    });
  });

  describe('I can see Learning Track options', () => {
    beforeEach(() => wrapper = getWrapper());

    it('contains a label of "Overview"', () => {
      expect(wrapper.get('.test-learning-tracks-options-overview').text()).toEqual('Overview');
    });

    it('contains Description Field child Component for "Overview: Learning Track Options"', () => {
      expectDescriptionFieldComponent(4, {
        type: 'learning_tracks.options_overall',
        value: volConfigs.descriptions.options_overall,
      });
    });

    it('contains two Description Fields as specified in "Learning Tracks Options"', () => {
      volConfigs.learning_tracks_options.forEach((option, index) => {
        const currentIndex = index + 1;
        expectDescriptionFieldComponent(4 + currentIndex, {
          type: `explanation_${currentIndex}`,
          value: option.explanation,
        });
      });
    });
  });
});
