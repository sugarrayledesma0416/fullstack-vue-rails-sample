import SectionSerializer from 'features/section_wizard/services/section_serializer';

const section = {
  name: 'TestSection',
  additionalInfo: 'sdsdsd',
  assignmentCopySectionId: null,
  classDays: {
    1: true,
    2: true,
    3: true,
  },
  sectionInstructors: [
    {
      first_name: 'Lolita',
      full_name: 'Lolita Stracke',
      last_name: 'Stracke',
      role: 'Instructor',
      user_id: 23,
    },
    {
      first_name: 'Elise',
      full_name: 'Elise Herzog',
      last_name: 'Herzog',
      role: '',
      user_id: 724,
    },
  ],
  dueTimeAmpm: 'PM',
  dueTimeHour: '11',
  dueTimeMin: '59',
  timeZone: 'Eastern Time (US & Canada)',
  hideOwnerName: false,
  instructor: { id: 23 },
  openToStudents: true,
  daysToShowAssignmentDueDate: null,
};

let sectionSerializer;
let serializeObj;

describe('Section Serializer', () => {
  describe('serialize', () => {
    beforeEach(() => {
      sectionSerializer = new SectionSerializer();
      serializeObj = sectionSerializer.serialize(section);
    });

    it('returns the list of section instructors with attrs', () => {
      expect(
        serializeObj.section.section_instructors_attributes
      ).toEqual([{ role: 'Instructor', user_id: 23 }]);
    });

    it('returns the appropriate format of the class days', () => {
      expect(
        serializeObj.section.class_days
      ).toBe('1,2,3');
    });

    it('returns the serialize object with keys count of 12', () => {
      expect(Object.keys(serializeObj.section).length).toEqual(12);
    });
  });
});
