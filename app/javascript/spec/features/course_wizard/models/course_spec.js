import Course from 'features/course_wizard/models/course';
let course;
const categoryA = { name: 'a', rank: 1, id: 11 };
const categoryB = { name: 'b', rank: 2, id: 131 };
const categoryC = { name: 'c', rank: 3, id: 241 };

describe('Coure Model', () => {
  describe('init course model', () => {
    beforeEach(() => {
      course = new Course();
    });

    it('initializes the pathType to null', () => {
      expect(course.pathType).toBeNull();
    });

    it('initializes the chat level to partner_chat', () => {
      expect(course.chatLevel).toEqual('partner_chat');
    });

    it('does not copy intructor created activities from previous course by default', () => {
      expect(course.copyCreatedActivitiesFromPreviousCourse).toBeFalsy();
    });

    it('allows help requests by default', () => {
      expect(course.allowsHelpRequests).toBeTruthy();
    });

    it('allows review requests by default', () => {
      expect(course.allowsReviewRequests).toBeTruthy();
    });

    it('initializes sections to be a list with a single object', () => {
      expect(course.sections).toEqual([{}]);
    });

    it('initializes categories to be an empty array', () => {
      expect(course.categories).toEqual([]);
    });

    it('initializes course library from course as null', () => {
      expect(course.courseLibraryFrom).toBeNull();
    });

    it('initializes aiVirtualChatLevel as false', () => {
      expect(course.aiVirtualChatLevel).toBe(false);
    });
  });

  describe('#removeCategory', () => {
    beforeEach(() => {
      course = new Course();
    });

    it('stores only removed categories with id', () => {
      const categoryD = { name: 'c', rank: 3, id: null };
      course.categories = [categoryA, categoryB, categoryC, categoryD];
      course.removeCategory(categoryD);
      expect(course.removedCategories).toEqual([]);
    });

    it('updates removed category with destoryed flag', () => {
      course.categories = [categoryA, categoryB, categoryC];
      course.removeCategory(categoryC);
      expect(course.removedCategories[0]._destroy).toBeTruthy();
    });

    it('adds removed category to removed categories list', () => {
      course.categories = [categoryA, categoryB, categoryC];
      course.removeCategory(categoryC);
      expect(course.removedCategories).toEqual([categoryC]);
    });

    it('removes the category from categoreis list', () => {
      course.categories = [categoryA, categoryB, categoryC];
      course.removeCategory(categoryC);
      expect(course.categories).toEqual([categoryA, categoryB]);
    });
  });

  describe('#displayName', () => {
    beforeEach(() => {
      course = new Course();
    });

    it('returns the placeholder name when course.name is undefined', () => {
      course.namePlaceholder = 'foo';
      course.name = undefined;
      expect(course.displayName).toEqual('foo');
    });

    it('returns the placeholder name when course.name is an empty string', () => {
      course.namePlaceholder = 'baz';
      course.name = '';
      expect(course.displayName).toEqual('baz');
    });

    it('returns the course name when course.name is not empty', () => {
      course.name = 'New Course';
      expect(course.displayName).toEqual('New Course');
    });
  });

  describe('#isStandardSetGroupSelected', () => {
    beforeEach(() => {
      course = new Course();
      course.standardSetIds = [1, 3, 5];
    });

    it('returns false when one of the standard set in the group is present in the course', () => {
      const group = { name: 'blah', ids: [2, 4, 6] };
      expect(course.isStandardSetGroupSelected(group)).toBeFalsy();
    });

    it('returns true when no standard set in the group is present in the course', () => {
      const group = { name: 'blah', ids: [2, 5, 6] };
      expect(course.isStandardSetGroupSelected(group)).toBeTruthy();
    });
  });

  describe('aiVirtualChatLevel', () => {
    it('can be set to true', () => {
      course.aiVirtualChatLevel = true;
      expect(course.aiVirtualChatLevel).toBe(true);
    });

    it('can be set to false', () => {
      course.aiVirtualChatLevel = false;
      expect(course.aiVirtualChatLevel).toBe(false);
    });
  });
});
