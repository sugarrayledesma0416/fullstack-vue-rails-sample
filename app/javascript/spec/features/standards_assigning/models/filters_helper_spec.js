import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Filters from 'features/standards_assigning/components/Filters';
import {
  updateMatchingContentCount,
  handleFilterChange,
} from 'features/standards_assigning/models/filters_helper';
import {
  appliedFilters,
  tocJson,
} from '../standards_assigning_fixture.js';

const store = createTestingPinia(
  {
    stubActions: false,
    initialState: {
      store: {
        appliedFilters: appliedFilters,
        isStandardsModalOpen: false,
      },
    },
  }
);

function getWrapper() {
  return shallowMount(
    Filters,
    {
      global: {
        plugins: [store],
      },
      props: {
        programTocType: 'Unit',
        tocJson: tocJson,
        preloadStandardsFilter: '{}',
      },
    }
  );
}

let wrapper;

describe('Filters', () => {
  beforeEach(()=> {
    wrapper = getWrapper();
  });

  describe('updateMatchingContentCount', () => {
    it('updates matchingContentCount correctly', () => {
      document.body.innerHTML = `
        <div class="aligned-items"></div>
        <div class="aligned-items"></div>
        <div class="aligned-items u-hidden"></div>
      `;

      const matchingContentCountRef = { value: null };
      updateMatchingContentCount(matchingContentCountRef);

      expect(matchingContentCountRef.value).toBe(2);
    });
  });

  describe('handleFilterChange', () => {
    it('handles status change to Assigned', () => {
      document.body.innerHTML = `
        <div class="c-assigned-item"></div>
        <div class="c-assigned-item"></div>
        <div class="c-unassigned-item"></div>
      `;

      handleFilterChange('Assigned', 'All');

      const assignedItems = wrapper.findAll('.c-assigned-item');
      const unassignedItems = wrapper.findAll('.c-unassigned-item');

      assignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      unassignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
    });

    it('handles status change to Unassigned', () => {
      document.body.innerHTML = `
        <div class="c-assigned-item"></div>
        <div class="c-assigned-item"></div>
        <div class="c-unassigned-item"></div>
      `;

      handleFilterChange('Unassigned', 'All');

      const assignedItems = wrapper.findAll('.c-assigned-item');
      const unassignedItems = wrapper.findAll('.c-unassigned-item');

      assignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
      unassignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
    });

    it('handles status change to All', () => {
      document.body.innerHTML = `
        <div class="c-assigned-item"></div>
        <div class="c-assigned-item"></div>
        <div class="c-unassigned-item"></div>
      `;

      handleFilterChange('All', 'All');

      const assignedItems = wrapper.findAll('.c-assigned-item');
      const unassignedItems = wrapper.findAll('.c-unassigned-item');

      assignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      unassignedItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
    });

    it('handles content type change to Activity', () => {
      document.body.innerHTML = `
        <div class="c-activity-item"></div>
        <div class="c-assessment-item"></div>
        <div class="c-ereader-item"></div>
      `;

      handleFilterChange('All', 'Activity');

      const activityItems = wrapper.findAll('.c-activity-item');
      const assessmentItems = wrapper.findAll('.c-assessment-item');
      const ereaderItems = wrapper.findAll('.c-ereader-item');

      activityItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      assessmentItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
      ereaderItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
    });

    it('handles content type change to Assessment', () => {
      document.body.innerHTML = `
        <div class="c-activity-item"></div>
        <div class="c-assessment-item"></div>
        <div class="c-ereader-item"></div>
      `;

      handleFilterChange('All', 'Assessment');

      const activityItems = wrapper.findAll('.c-activity-item');
      const assessmentItems = wrapper.findAll('.c-assessment-item');
      const ereaderItems = wrapper.findAll('.c-ereader-item');

      activityItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
      assessmentItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      ereaderItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
    });

    it('handles content type change to Teacher Edition', () => {
      document.body.innerHTML = `
        <div class="c-activity-item"></div>
        <div class="c-assessment-item"></div>
        <div class="c-ereader-item"></div>
      `;

      handleFilterChange('All', 'Teacher Edition');

      const activityItems = wrapper.findAll('.c-activity-item');
      const assessmentItems = wrapper.findAll('.c-assessment-item');
      const ereaderItems = wrapper.findAll('.c-ereader-item');

      activityItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
      assessmentItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(true);
      });
      ereaderItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
    });

    it('handles content type change to All', () => {
      document.body.innerHTML = `
        <div class="c-activity-item"></div>
        <div class="c-assessment-item"></div>
        <div class="c-ereader-item"></div>
      `;

      handleFilterChange('All', 'All');

      const activityItems = wrapper.findAll('.c-activity-item');
      const assessmentItems = wrapper.findAll('.c-assessment-item');
      const ereaderItems = wrapper.findAll('.c-ereader-item');

      activityItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      assessmentItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
      ereaderItems.forEach((item) => {
        expect(item.classList.contains('u-hidden')).toBe(false);
      });
    });
  });
});
