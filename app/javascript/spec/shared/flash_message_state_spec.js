import FlashMessageState from 'shared/flash_message_state';

let flashMessageState;

describe('FlashMessageState Model', () => {
  describe('constructor', () => {
    beforeEach(() => {
      flashMessageState = new FlashMessageState();
    });

    it('has "showError" value as false.', () => {
      expect(flashMessageState.showError).toBe(false);
    });

    it('has "showNotice" value as false.', () => {
      expect(flashMessageState.showNotice).toBe(false);
    });
  });

  describe('displayError', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      flashMessageState = new FlashMessageState();
      flashMessageState.displayError();
    });

    it('would have "showError" value as true for 10 seconds.', async () => {
      expect(flashMessageState.showError).toBe(true);
      jest.advanceTimersByTime(9999);
      expect(flashMessageState.showError).toBe(true);
    });

    it('would have "showError" value as false after 10 seconds.', async () => {
      jest.advanceTimersByTime(10001);
      expect(flashMessageState.showError).toBe(false);
    });
  });

  describe('displayNotice', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      flashMessageState = new FlashMessageState();
      flashMessageState.displayNotice();
    });

    it('would have "showNotice" value as true for 10 seconds.', async () => {
      expect(flashMessageState.showNotice).toBe(true);
      jest.advanceTimersByTime(9999);
      expect(flashMessageState.showNotice).toBe(true);
    });

    it('would have "showNotice" value as false after 10 seconds.', async () => {
      jest.advanceTimersByTime(10001);
      expect(flashMessageState.showNotice).toBe(false);
    });
  });
});
