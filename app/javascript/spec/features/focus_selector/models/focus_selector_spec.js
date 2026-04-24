import FocusSelector from 'features/focus_selector/models/focus_selector';

describe('FocusSelector', () => {
  describe('constructor', () => {
    describe('when given sections JSON that is not an array', () => {
      it('throws an error', () => {
        expect(() => {
          new FocusSelector('{}');
        }).toThrowError();
      });
    });

    describe('when given sections JSON that is an array', () => {
      it('sets the parsed JSON to sections', () => {
        expect(new FocusSelector('[{},{}]').sections).toEqual([{}, {}]);
      });
    });
  });
});
