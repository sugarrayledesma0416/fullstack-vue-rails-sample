/**
 * Handles section change by redirecting to the selected URL.
 * @param {Event} event - The event triggered by the section change.
 */
export function handleSectionChange(event) {
  const selectedValue = event.target.value.trim();

  if (selectedValue) {
    try {
      const url = new URL(selectedValue, window.location.origin);
      window.location.href = url.href;
    } catch (e) {
      console.error('Invalid URL:', selectedValue);
    }
  }
}
