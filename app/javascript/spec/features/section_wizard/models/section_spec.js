import { Section } from 'features/section_wizard/models/section';

const sectionParams = {
  additional_info: '',
  class_days: {},
  course: {
    id: 39,
    name: 'sddf',
    owner_id: 23,
    program_id: 79,
  },
  due_time_ampm: 'PM',
  due_time_hour: '11',
  due_time_min: '59',
  id: null,
  instructor: { id: 23 },
  latest_section_id: 54,
  name: null,
  previous_sections: [],
  section_instructors: [
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
};

let section;

describe('Section Model', () => {
  describe('assignmentAvailabilityMessage', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it(
      'returns the availability message as "All upcoming assignments available to students."',
      () => {
        expect(
          section.assignmentAvailabilityMessage
        ).toBe('All upcoming assignments available to students.');
      }
    );
  });

  describe('availableOptions', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns the list of available options with keys as "Frequently Used" and "Other', () => {
      expect(Object.keys(section.availableOptions)).toStrictEqual(['Frequently Used', 'Other']);
    });
  });

  describe('courseId', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns the course id', () => {
      expect(section.courseId).toBe(39);
    });
  });

  describe('courseSectionsPresent', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns if course sections are presents or not', () => {
      expect(section.courseSectionsPresent).toBeFalsy();
    });
  });

  describe('instructorLastNames', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns the list of last names of the instructor', () => {
      expect(section.instructorLastNames).toEqual(['Stracke, Lolita']);
    });
  });

  describe('descendingByRole', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns the instructors list descending by role', () => {
      expect(
        section.descendingByRole(sectionParams.section_instructors)
      ).toEqual(sectionParams.section_instructors);
    });
  });

  describe('formattedFullNames', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns the full names with formatting', () => {
      expect(
        section.formattedFullNames(sectionParams.section_instructors)
      ).toEqual(['Stracke, Lolita', 'Herzog, Elise']);
    });
  });

  describe('nonOwners', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns non owners section instructors', () => {
      expect(
        section.nonOwners(sectionParams.section_instructors)
      ).toEqual([sectionParams.section_instructors[1]]);
    });
  });

  describe('sectionInstructorsWithRoles', () => {
    beforeEach(() => {
      section = new Section();
      section.init(sectionParams);
    });

    it('returns instructors with some role', () => {
      expect(
        section.sectionInstructorsWithRoles(sectionParams.section_instructors)
      ).toEqual([sectionParams.section_instructors[0]]);
    });
  });
});
