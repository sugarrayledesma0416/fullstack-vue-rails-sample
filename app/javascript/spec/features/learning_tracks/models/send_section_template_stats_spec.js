import { sendSectionTemplateStats, sectionTemplateStats } from
  'features/learning_tracks/models/send_section_template_stats';

VHL = { CarlinDispatch: {}};
VHL.CarlinDispatch.Logstash = class {
  constructor(templateType) {
    this.templateType = templateType;
  }

  dispatch(type, statsObj) {}
};

const section = {
  selected_track_name: 'test course, NewProd',
  strands: [{
    color: '#BE0027',
    name: 'Contextos',
    selected: true,
  }],
  calendar: {
    first_unit_id: 303,
    last_unit_id: 303,
  },
  include_microphone_activities: true,
  include_instructor_graded_activities: true,
  include_partner_activities: true,
  name: 'test',
};

describe('UnitRange', () => {
  describe('#sendSectionTemplateStats', () => {
    let spy;
    beforeEach(() => {
      spy = jest.spyOn(VHL.CarlinDispatch.Logstash.prototype, 'dispatch');
      sendSectionTemplateStats({}, 'learning_track_template');
    });

    it('internally calls CarlinDispatcher for logging', () => {
      expect(spy).toHaveBeenCalledTimes(1);
    });
  });

  describe('#sectionTemplateStats', () => {
    let output;
    beforeEach(() => {
      output = sectionTemplateStats(section);
    });

    it('contains dropped strands as empty', () => {
      expect(output.droppedStrands).toStrictEqual([]);
    });

    it('does not contains dropped strands as empty', () => {
      section.strands.push({
        color: '#BE0028',
        name: 'Contextos-1',
        selected: false,
      });
      output = sectionTemplateStats(section);
      expect(output.droppedStrands).toStrictEqual(['Contextos-1']);
    });
  });
});
