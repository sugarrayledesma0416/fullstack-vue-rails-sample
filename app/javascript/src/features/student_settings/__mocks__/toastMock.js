// Mock document.createElement for Shoelace alerts
const mockToast = vi.fn();
const originalCreateElement = document.createElement;

export const setupToastMock = () => {
  vi.spyOn(document, 'createElement').mockImplementation((tagName) => {
    if (tagName === 'sl-alert') {
      const element = originalCreateElement.call(document, tagName);
      element.toast = mockToast;
      return element;
    }
    return originalCreateElement.call(document, tagName);
  });
};

export const clearToastMock = () => {
  vi.clearAllMocks();
  document.body.innerHTML = '';
};

export const getMockToast = () => mockToast;
