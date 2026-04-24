import UnitRange from 'features/learning_tracks/models/unit_range';

const units = [
  { id: 3 },
  { id: 5 },
  { id: 7 },
  { id: 9 },
  { id: 11 },
  { id: 13 },
  { id: 15 },
  { id: 17 },
  { id: 19 },
  { id: 21 },
  { id: 23 },
  { id: 25 },
];

let unitRange;

describe('UnitRange', () => {
  beforeEach(() => {
    unitRange = new UnitRange('0', '2', units);
  });

  describe('#initialize', () => {
    it('sets the first unit index', () => {
      expect(unitRange.firstUnitIndex).toEqual('0');
    });

    it('sets the last unit index', () => {
      expect(unitRange.lastUnitIndex).toEqual('2');
    });

    it('sets the units', () => {
      expect(unitRange.units).toEqual(units);
    });

    it('sets a unit id to index map', () => {
      expect(unitRange.unitIdToIndexMap).toEqual({
        3: '0',
        5: '1',
        7: '2',
        9: '3',
        11: '4',
        13: '5',
        15: '6',
        17: '7',
        19: '8',
        21: '9',
        23: '10',
        25: '11',
      });
    });
  });

  describe('#valid', () => {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('returns true when first and last unit indexes are numbers', () => {
      expect(unitRange.isValid).toBeTruthy();
    });

    it('returns false when either is not a number', () => {
      unitRange = new UnitRange(undefined, '2', units);
      expect(unitRange.isValid).toBeFalsy();
    });

    it('returns false if the last unit index is less than the first unit index', () => {
      unitRange = new UnitRange('0', '-1', units);
      expect(unitRange.isValid).toBeFalsy();
    });
  });

  describe('#firstUnitId', () => {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('returns the unit id at the first unit index', () => {
      expect(unitRange.firstUnitId).toEqual(3);
    });

    it('returns false when there are no units', () => {
      expect(new UnitRange(null, null, []).firstUnitId).toBeUndefined();
    });
  });

  describe('#lastUnitId', () => {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('returns the unit id at the last unit index', () => {
      expect(unitRange.lastUnitId).toEqual(7);
    });

    it('returns false when there are no units', () => {
      expect(new UnitRange(null, null, []).lastUnitId).toBeUndefined();
    });
  });

  describe('#count', () => {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('returns the number of units', () => {
      expect(unitRange.count).toEqual(3);
    });
  });

  describe('#includes', () => {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('returns true when an activity is included in the unit range', () => {
      expect(unitRange.includes(3)).toBe(true);
      expect(unitRange.includes(5)).toBe(true);
      expect(unitRange.includes(7)).toBe(true);
    });

    it('returns false when an activity is not included in the unit range', () => {
      expect(unitRange.includes(2)).toBe(false);
      expect(unitRange.includes(4)).toBe(false);
      expect(unitRange.includes(6)).toBe(false);
      expect(unitRange.includes(8)).toBe(false);
    });

    it(
      'returns false when the activity index is lexically less but numerically' +
      ' greater than the last unit index',
      () => {
        expect(unitRange.includes(25)).toBe(false);
      });
  });

  describe('#each', function() {
    beforeEach(() => {
      unitRange = new UnitRange('0', '2', units);
    });

    it('iterates starting at the first unit index and ending with the last unit index', () => {
      const actual = [];
      unitRange.each((index) => {
        actual.push(index);
      });
      expect(actual).toEqual([0, 1, 2]);
    });
  });
});
