import useSectionReportFilterStore
  from 'features/gradebook/standards/section_report_filters/stores/use_section_report_filter_store';
import { createPinia, setActivePinia } from 'pinia';

describe('useSectionReportFilterStore', () => {
  const pinia = createPinia();
  setActivePinia(pinia);

  let store;
  const assessmentId1 = 123456;
  const assessmentId2 = 567890;

  beforeEach(() => {
    store = useSectionReportFilterStore();
  });

  describe('when the store is first created', () => {
    it('has an empty selectedAssessmentIds', () => {
      expect(store.selectedAssessmentIds.size).toBe(0);
    });

    it('has userHasChangedAssessmentSelection set to false', () => {
      expect(store.userHasChangedAssessmentSelection).toBeFalsy();
    });

    it('has selectedAssessmentOption set to "proficiency"', () => {
      expect(store.selectedAssessmentOption).toBe('proficiency');
    });

    it('has an empty selectedStandardSetRef', () => {
      expect(store.selectedStandardSetRef).toBe('');
    });

    it('has an empty selectedLessonId', () => {
      expect(store.selectedLessonId).toBe('');
    });

    it('has an empty selectedCategories array', () => {
      expect(store.selectedCategories).toEqual([]);
    });

    it('has an empty isCategoryChecked object', () => {
      expect(store.isCategoryChecked).toEqual({});
    });
  });

  describe('#clearSelectedAssessmentIds', () => {
    beforeEach(() => {
      store.toggleSelectAssessmentId({ assessmentId: assessmentId1, checked: true });
      store.toggleSelectAssessmentId({ assessmentId: assessmentId2, checked: true });
      store.clearSelectedAssessmentIds();
    });

    it('empties selectedAssessmentIds', () => {
      expect(store.selectedAssessmentIds.size).toBe(0);
    });

    it('resets userHasChangedAssessmentSelection to false', () => {
      expect(store.userHasChangedAssessmentSelection).toBeTruthy();
    });
  });

  describe('#isSelected', () => {
    beforeEach(() => {
      store.toggleSelectAssessmentId({ assessmentId: assessmentId1, checked: true });
    });

    describe('when the assessmentId is in selectedAssessmentIds', () => {
      it('returns true', () => {
        expect(store.isSelected(assessmentId1)).toBeTruthy();
      });
    });

    describe('when the assessmentId is not in selectedAssessmentIds', () => {
      it('returns false', () => {
        expect(store.isSelected(assessmentId2)).toBe(false);
      });
    });
  });

  describe('#selectedAssessmentIdsString', () => {
    beforeEach(() => {
      store.toggleSelectAssessmentId({ assessmentId: assessmentId1, checked: true });
      store.toggleSelectAssessmentId({ assessmentId: assessmentId2, checked: true });
    });

    it('returns a comma-separated string of the selected assessmentIds', () => {
      expect(store.selectedAssessmentIdsString).toBe(`${assessmentId1},${assessmentId2}`);
    });

    describe('when there are no selected assessmentIds', () => {
      it('returns an empty string', () => {
        store.clearSelectedAssessmentIds();
        expect(store.selectedAssessmentIdsString).toBe('');
      });
    });
  });

  describe('#toggleSelectAssessmentId', () => {
    beforeEach(() => {
      store.toggleSelectAssessmentId({ assessmentId: assessmentId1, checked: true });
    });

    describe('when the argument object includes { checked: true }', () => {
      it('adds the assessmentId to selectedAssessmentIds', () => {
        expect(store.selectedAssessmentIds.has(assessmentId1)).toBe(true);
      });

      it('sets userHasChangedAssessmentSelection to true', () => {
        expect(store.userHasChangedAssessmentSelection).toBeTruthy();
      });
    });

    describe('when the argument object includes { checked: false }', () => {
      it('removes the assessmentId from selectedAssessmentIds', () => {
        store.toggleSelectAssessmentId({ assessmentId: assessmentId1, checked: false });
        expect(store.selectedAssessmentIds.has(assessmentId1)).toBe(false);
      });
    });
  });

  describe('#setSelectedAssessmentOption', () => {
    it('updates selectedAssessmentOption to the specified option', () => {
      store.setSelectedAssessmentOption('New Option');
      expect(store.selectedAssessmentOption).toBe('New Option');
    });
  });

  describe('#setSelectedStandardSetRef', () => {
    it('updates selectedStandardSetRef to the specified value', () => {
      store.setSelectedStandardSetRef('Ref1');
      expect(store.selectedStandardSetRef).toBe('Ref1');
    });
  });

  describe('#setSelectedLessonId', () => {
    it('updates selectedLessonId to the specified value', () => {
      store.setSelectedLessonId('Lesson1');
      expect(store.selectedLessonId).toBe('Lesson1');
    });
  });

  describe('#resetCategoryCheck', () => {
    beforeEach(() => {
      store.isCategoryChecked = { 1: true, 2: false };
      store.resetCategoryCheck();
    });

    it('resets isCategoryChecked to an empty object', () => {
      expect(store.isCategoryChecked).toEqual({});
    });
  });
});
