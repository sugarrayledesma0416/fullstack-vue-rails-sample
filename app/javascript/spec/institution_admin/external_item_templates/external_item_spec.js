import ExternalItem from 'institution_admin/external_item_templates/external_item.js';

let updatableFields = [
  'categoryId',
  'dueDate',
  'lessonId',
  'pointsPossible',
  'title'
];

let dataForUpdate = {
  categoryId: '123',
  dueDate: '2020-08-12',
  lessonId: '456',
  pointsPossible: 15,
  title: 'the title'
};

function overrideValues(target, hash) {
  return Object.assign({}, target, hash);
}

describe('ExternalItem', () => {
  let endDate, externalActivityId, extItem, sectionId, startDate;
  let validData;

  beforeEach(() => {
    externalActivityId = 1000;
    sectionId = 2000;
    startDate = '2020-08-06';
    endDate = '2020-12-15';
    extItem = new ExternalItem(
      externalActivityId,
      sectionId,
      startDate,
      endDate
    );

    validData = {
      categoryId: '124',
      dueDate: '2020-08-14',
      lessonId: '457',
      pointsPossible: 16,
      title: 'new title'
    };
  });

  describe('#constructor', () => {
    it('sets expected properties', () => {
      expect(
        ['externalActivityId',
         'sectionId',
         'startDate',
         'endDate'].map(prop => extItem[prop])
      ).toEqual([externalActivityId, sectionId, startDate, endDate]);
    });

    it('does not set updatable values if values are not provided', () => {
      expect(
        updatableFields.map(prop => extItem[prop])
      ).toEqual([undefined, undefined, undefined, undefined, undefined]);

      expect(
        updatableFields.map(prop => extItem.initialData[prop])
      ).toEqual([undefined, undefined, undefined, undefined, undefined]);
    });

    it('sets updatable values if initial form values are provided', () => {
      let otherExtItem = new ExternalItem(
        externalActivityId,
        sectionId,
        startDate,
        endDate,
        validData
      );

      expect(
        updatableFields.map(prop => otherExtItem[prop] === validData[prop])
      ).toEqual([true, true, true, true, true]);

      expect(
        updatableFields.map(
          prop => otherExtItem.initialData[prop] === validData[prop]
        )
      ).toEqual([true, true, true, true, true]);
    });
  });

  describe('#update', () => {
    it('updates expected properties if data are valid', () => {
      extItem.update(dataForUpdate);

      expect(
        updatableFields.map(prop => extItem[prop])
      ).toEqual(Object.values(dataForUpdate));
    });

    it('returns true if data are valid', () => {
      let result = extItem.update(dataForUpdate);

      expect(result).toBe(true);
    });

    it('does not update data if data are invalid', () => {
      // introduce bad data (blank title) to fail validation
      extItem.update(overrideValues(dataForUpdate, { title: '' }));

      expect(
        updatableFields.map(prop => extItem[prop])
      ).toEqual([undefined, undefined, undefined, undefined, undefined]);
    });

    it('returns false if data are invalid', () => {
      // introduce bad data (blank title) to fail validation
      let result = extItem.update(overrideValues(dataForUpdate, { title: '' }));

      expect(result).toBe(false);
    });
  });

  describe('#validate', () => {
    it('returns false if the title has no content', () => {
      let result = extItem.validate(overrideValues(validData, { title: '' }));
      expect(result).toBe(false);
    });

    it('returns false if the points possible are not a number', () => {
      let result = extItem.validate(
        overrideValues(validData, { pointsPossible: 'z' })
      );
      expect(result).toBe(false);
    });

    it('returns false if the lesson ID is blank', () => {
      let result = extItem.validate(
        overrideValues(validData, { lessonId: '' })
      );
      expect(result).toBe(false);
    });

    it('returns false if the category ID is blank', () => {
      let result = extItem.validate(
        overrideValues(validData, { categoryId: '' })
      );
      expect(result).toBe(false);
    });

    it('returns false if the due date is before the start date', () => {
      let result = extItem.validate(
        overrideValues(validData, { dueDate: '2020-08-05' })
      );
      expect(result).toBe(false);
    });

    it('returns false if the due date is after the end date', () => {
      let result = extItem.validate(
        overrideValues(validData, { dueDate: '2020-12-16' })
      );
      expect(result).toBe(false);
    });

    it('returns true if all data are valid', () => {
      let result = extItem.validate(validData);
      expect(result).toBe(true);
    });

    describe('checking if data have changed since initialization', () => {
      let otherExtItem;

      beforeEach(() => {
        otherExtItem = new ExternalItem(
          externalActivityId,
          sectionId,
          startDate,
          endDate,
          validData
        );
      });

      it('returns false if data are same as initial values', () => {
        // change a value...
        otherExtItem.update(
          overrideValues(validData, { title: 'changed title' })
        );
        // ...then change it back to the original
        let result = otherExtItem.validate(validData);

        expect(result).toBe(false);
      });

      it('returns true if data have changed from initial values', () => {
        let result = otherExtItem.validate(
          overrideValues(validData, { title: 'changed title' })
        );
        expect(result).toBe(true);
      });
    });
  });

  describe('#data', () => {
    it('returns expected dataset', ()=> {
      let externalActivityId = 1000;
      let sectionId = 2000;
      let startDate = '2020-08-06';
      let endDate = '2020-12-15';

      let extItem = new ExternalItem(
        externalActivityId,
        sectionId,
        startDate,
        endDate
      );

      extItem.update(dataForUpdate);

      expect(extItem.data()).toEqual({
        category_id: dataForUpdate.categoryId,
        due_date: dataForUpdate.dueDate,
        id: externalActivityId,
        lesson_id: dataForUpdate.lessonId,
        points_possible: dataForUpdate.pointsPossible,
        section_id: sectionId,
        title: dataForUpdate.title
      });
    });
  });
});
