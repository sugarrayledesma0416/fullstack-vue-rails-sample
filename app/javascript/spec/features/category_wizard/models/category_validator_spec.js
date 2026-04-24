import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryValidator from 'features/category_wizard/models/category_validator';

let categoryValidator;
let category;
const courseCategories = [{ name: 'homework' }];
describe('CategoryValidator', () => {
  beforeEach(async () => {
    category = reactive(new Category());
    categoryValidator = new CategoryValidator(category);
  });

  describe('#isStepInValid', () => {
    describe('when step is 0', () => {
      describe('when category name is blank', () => {
        beforeEach(() => {
          category.name = '';
        });

        it('returns that current step is invalid', () => {
          expect(categoryValidator.isStepInValid(0, [])).toBe(true);
        });
      });

      describe('when category name is already used', () => {
        beforeEach(() => {
          category.name = 'homework';
        });

        it('returns that current step is invalid', () => {
          expect(categoryValidator.isStepInValid(0, courseCategories)).toBe(true);
        });
      });

      describe('when category name is present and not used', () => {
        beforeEach(() => {
          category.name = 'credit';
        });

        it('returns that current step is not invalid', () => {
          expect(categoryValidator.isStepInValid(0, courseCategories)).toBe(false);
        });
      });
    });
  });

  describe('#hasErrorInCategoryName', () => {
    describe('when category name is blank', () => {
      beforeEach(() => {
        category.name = '';
      });

      it('returns hasErrorInCategoryName value as true', () => {
        expect(categoryValidator.hasErrorInCategoryName([])).toEqual({
          msg: 'This is a required field',
          value: true,
        });
      });
    });

    describe('when category name is already used', () => {
      beforeEach(() => {
        category.name = 'homework';
      });

      it('returns hasErrorInCategoryName value as true', () => {
        expect(categoryValidator.hasErrorInCategoryName(courseCategories)).toEqual({
          msg: 'This category name is already in use',
          value: true,
        });
      });
    });

    describe('when category name is present and not used', () => {
      beforeEach(() => {
        category.name = 'credit';
      });

      it('returns hasErrorInCategoryName value as false', () => {
        expect(categoryValidator.hasErrorInCategoryName(courseCategories)).toEqual({
          msg: '',
          value: false,
        });
      });
    });
  });
});
