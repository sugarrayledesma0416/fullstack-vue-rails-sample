import { defineStore } from 'pinia';
import UnitItem from 'features/standards_assigning/models/unit_item';

/**
 * @typedef import { TocItem } from './jsdoc/standards.js'
 */


/**
 * @typedef StandardsAssigningState
 * @property {Array.<Filter>} appliedFilters
 * @property {Array.<TocItem>} tocItems
 * @property {Array.<Standard>} matchedStandards - list of standards matching the search terms.
 */

/**
 * returns the state object for standards assigning.
 * @return {StandardsAssigningState}
 */
function state() {
  return {
    tocItems: [],
    tocUnitNames: {},
    tocConceptNames: {},
    selectedStandards: [],
    matchedStandards: null,
    standardsInfo: {},
    alignedItems: {},
    selectedTocItems: [],
    isStandardsModalOpen: true,
    isFirstSearch: true,
    selectedStatus: null,
    selectedContentType: null,
    visibleRefinements: {},
    selectedSkills: [],
    selectedRefinements: [],
    selectedStandardSet: null,
    showBrowseTree: false,
    resetAllFilters: false,
  };
}

const useStandardsAssigningStore = defineStore(
  'store',
  {
    state: state,
    getters: {
      getSelectedSkills(state) {
        return state.selectedSkills;
      },

      getSelectedRefinements(state) {
        return state.selectedRefinements;
      },

      getVisibleRefinements(state) {
        return state.visibleRefinements;
      },

      anyRequiredFiltersSelected(state) {
        return (
          state.selectedStandards.length ||
          state.selectedSkills.length ||
          state.selectedRefinements.length
        );
      },
    },
    actions: {
      /**
       * @param {String} tocJson - includes unit/lesson id, name
       */
      initToc(tocJson) {
        const parsedToc = JSON.parse(tocJson);
        this.tocItems = parsedToc.units.map((item) => {
          return { ...item, ...{ selected: true }};
        });
        parsedToc.units.forEach((item) => {
          this.tocUnitNames[item.id] = item.name;
        });
        this.tocConceptNames = parsedToc.concepts;
      },

      /**
       * @param {String} standardGuid
       * @return {Boolean} - true if standard is selected, false otherwise.
       *
       */
      isStandardSelected(standardGuid) {
        return this.selectedStandards.includes(standardGuid);
      },
      /**
       * Sets all Units/Lessons selected by default.
       */
      setDefaultSelectedTocItems() {
        this.selectedTocItems = this.tocItems.map((item) => item.id);
      },

      /**
       * @param {String} alignedItemsJson - json payload returned upon search from
       * instructor_search_standards_path. Includes aligned item data grouped
       * by unit, lesson, concept.
       * @param {boolean|null} [paginatedRequest=null] - Indicates if the request is paginated.
       */
      updateAlignedItems(alignedItemsJson, paginatedRequest = null) {
        const parsedItems = JSON.parse(alignedItemsJson);
        const unitIds = Object.keys(parsedItems);
        const items = unitIds.map((id) => {
          return new UnitItem(id, parsedItems[id]);
        });

        if (paginatedRequest) {
          this.previousAlignedItems.push(...items);
          this.alignedItems = this.previousAlignedItems;
        } else {
          this.previousAlignedItems = [];
          this.alignedItems = items;
          this.previousAlignedItems = items;
        }
      },

      /**
       * Stores and appends the standards info json data
       * @param {String} standardsInfoJson - json payload returned from
       * instructor_search_standards_path. Includes standards and standard_sets info.
       */
      updateStandardsInfo(standardsInfoJson) {
        const standardsInfo = JSON.parse(standardsInfoJson);
        this.standardsInfo = {
          standards: {
            ...(this.standardsInfo?.standards || {}),
            ...(standardsInfo.standards || {}),
          },
          standard_sets: {
            ...(this.standardsInfo?.standard_sets || {}),
            ...(standardsInfo.standard_sets || {}),
          },
        };
      },

      /**
       * Parse and process the standards json data fetched via keyword search
       * and set it to store's matchedStandards var.
       * @param {String} matchedStandardsJson 
       */
      updateMatchedKeywordStandards(matchedStandardsJson) {
        const parsedStandards = JSON.parse(matchedStandardsJson);
        if (parsedStandards.length > 0) {
          parsedStandards.forEach((standard) => {
            if (standard.number === ('')) {
              standard.display_number = standard.parent.number;
            } else {
              standard.display_number = standard.number;
            }
          });
        }
        this.matchedStandards = parsedStandards;
      },

      /**
       * Parse and process the standards json data fetched via standard set and grade filters search
       * and set it to store's matchedStandards var.
       * @param {String} matchedStandardsJson 
       */
      updateMatchedBrowseStandards(matchedStandardsJson) {
        const allNodes = JSON.parse(matchedStandardsJson);
        const flattenNodes = this.getFlattenNodes(allNodes);
        flattenNodes.forEach((standard) => {
          standard.display_number = standard.number || standard.description;
        });
        this.matchedStandards = flattenNodes;
      },

      /**
       * Parse and process the standards json data
       * and set it to store's matchedStandards var.
       * @param {String} matchedStandardsJson 
       */
      updateMatchedStandards(matchedStandardsJson, viewMode) {
        if (viewMode === 'BROWSE') {
          this.updateMatchedBrowseStandards(matchedStandardsJson);
        } else {
          this.updateMatchedKeywordStandards(matchedStandardsJson);
        }
      },

      /**
       * Converts an array of standard GUIDs to their corresponding display numbers.
       *
       * @param {Array.<String>} standardGuids
       * @return {Array.<String>} - Array of display standards for the matching vendor GUIDs.
       *
       * This function filters the `matchedStandards` array to find standards whose
       * `vendor_guid` matches any of the provided `standardGuids`.
       */
      convertStandardGuidToNumber(standardGuids) {
        if (!this.matchedStandards || !Array.isArray(this.matchedStandards)) {
          return [];
        }

        const filteredStandards = this.matchedStandards.filter((standard) =>
          standardGuids.includes(standard.vendor_guid)
        );

        const displayStandards = filteredStandards.map((standard) => ({
          display_number: standard.display_number,
          description: standard.description,
          vendor_guid: standard.vendor_guid,
        }));
        return displayStandards;
      },

      /**
       * Get the flatten nodes by traversing all given nodes and their children. 
       * @param {Array<object>} nodes 
       */
      getFlattenNodes(nodes) {
        const flattenNodes = [];
      
        function traverse(nodeList) {
          nodeList.forEach(node => {
            flattenNodes.push(node);
            if (node.children && node.children.length > 0) {
              traverse(node.children);
            }
          });
        }
      
        traverse(nodes);
        return flattenNodes;
      },

      removeStandardFromList(vendorGuid) {
        this.selectedStandards = this.selectedStandards.filter(
          (standard) => standard !== vendorGuid
        );
      },

      setSelectedStatus(status) {
        this.selectedStatus = status;
      },

      setSelectedContentType(contentType) {
        this.selectedContentType = contentType;
      },

      setSelectedSkills(skills) {
        this.selectedSkills = skills;
      },

      setSelectedRefinements(refinements) {
        this.selectedRefinements = refinements;
      },

      setVisibleRefinements(visibleRefinements) {
        this.visibleRefinements = visibleRefinements;
      },

      setSelectedStandardSet(standardSet) {
        this.selectedStandardSet = standardSet;
      },

      setShowBrowseTree(showBrowseTree) {
        this.showBrowseTree = showBrowseTree;
      },
    },
  }
);

export default useStandardsAssigningStore;
