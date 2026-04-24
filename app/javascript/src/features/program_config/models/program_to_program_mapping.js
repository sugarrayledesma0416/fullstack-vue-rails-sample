import * as ajaxUtils from 'shared/ajax_utils';

/** Class representing ProgramToProgramMapping */
class ProgramToProgramMapping {
  /**
   * Set up the configutation required for initializing ProgramToProgramMapping.
   * @param {Object} localstore - localState variables of the ProgramMapping component.
   * @param {Object} modalParams - Source change modal params.
   */
  constructor(localstore, modalParams) {
    this.localstore = localstore;
    this.modalParams = modalParams;
  }

  /**
   * Handling for source program change.
   * @param {Object} options
   * @param {number} options.srcProgId - source program Id.
   * @param {string} options.selProgName - selected source program name.
   * @param {boolean} options.noCurrentSrcForDest - Whether there is current mapping for dest.
   */
  async onSrcProgramChange(options) {
    const noCurrentSrcForDest = options.noCurrentSrc;
    this.localstore.srcProgId = options.srcProgId;
    this.currentDestForSrc = await this.getDestForSrc(options.srcProgId);

    if (this.currentDestForSrc === null) {
      if (noCurrentSrcForDest) {
        this.modalParams.type = null;
        // There is no existing mapping for the current destination or selected source strands
        await this.getSourceProgramLessonsStrands(options.srcProgId);
      } else {
        // There is an existing mapping for this destination program
        this.setSrcChangeModalParams('mapping-change-src', options.srcProgName);
      }
    } else {
      this.showMappingInUse(noCurrentSrcForDest, options.srcProgName);
    }
  }

  /**
   * Show "Mapping already in use" modal.
   * @param {boolean} noCurrentSrcForDest - Whether there is current mapping for destination
   * @param {string} srcProgName - source program name
   */
  showMappingInUse(noCurrentSrcForDest, srcProgName) {
    if (noCurrentSrcForDest) {
      // Selected source is already in use by another destination program
      this.setSrcChangeModalParams('mapping-already-in-use', srcProgName);
    } else {
      // Selected source is already in use AND destination program has an exsiting mapping
      this.setSrcChangeModalParams('mapping-change-and-in-use', srcProgName);
    }
  }

  /**
   * Set the source change modal params.
   * @param {string} type - modal type
   * @param {string} srcProgName - source program name
   */
  setSrcChangeModalParams(type, srcProgName) {
    this.modalParams.type = type;

    if (type === 'mapping-change-src') {
      this.modalParams.header = srcProgName;
      this.modalParams.currentDestForSrcId = 0;
      this.modalParams.currentDestForSrcName = '';
      this.modalParams.confirmButtonText = 'Set Source';
    } else {
      this.modalParams.header = 'Already In Use';
      this.modalParams.currentDestForSrcId = this.currentDestForSrc.id;
      this.modalParams.currentDestForSrcName = this.currentDestForSrc.name;
      this.modalParams.newSrcProg = srcProgName;

      if (type === 'mapping-already-in-use') {
        this.modalParams.confirmButtonText = 'Delete Mapping';
      } else if (type === 'mapping-change-and-in-use') {
        this.modalParams.confirmButtonText = 'Delete & Set Source';
      }
    }
  }

  /**
   * Get current destination for source.
   * @param {number} srcProgId - source program Id.
   * @return {Promise} - promise that resolve to destination program.
   */
  getDestForSrc(srcProgId) {
    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        `/programs/${this.localstore.destProgId}/current_dest_for_src?src_prog=${srcProgId}`,
        (data) => {
          resolve(data.id ? data : null);
        }
      );
    });
  }

  /**
   * Cancel / Decline changing the source program.
   */
  declineSourceProgramChange() {
    // Populating source dropdown and lesson/strands with last successfully selected item.
    this.localstore.srcProgId = parseInt(sessionStorage.getItem('lastSelSrcProg'));
    document.querySelector('#mapping_src_program').value = this.localstore.srcProgId;
    this.getSourceProgramLessonsStrands(this.localstore.srcProgId);
  }

  /**
   * Confirm changing the source program.
   * @param {number} newSrcProgId - new source program Id.
   * @param {number} destProgIdForSrc - destination program Id for source.
   */
  async confirmSourceProgramChange(newSrcProgId, destProgIdForSrc) {
    await this.removeMapping(destProgIdForSrc);
    this.getSourceProgramLessonsStrands(newSrcProgId);
  }

  /**
   * Remove mapping between source and destination.
   * @param {number} destProgIdForSrc - destination program Id for source.
   * @return {Promise} - promise that remove the mapping.
   */
  removeMapping(destProgIdForSrc) {
    let url = `/programs/${this.localstore.destProgId}/remove_existing_mappings`;
    if (destProgIdForSrc !== 0) {
      url += `?current_dest_for_src=${destProgIdForSrc}`;
    }

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * Get lesson strands for source and destination.
   * @param {number} srcProgId - destination program Id for source.
   */
  async getSourceProgramLessonsStrands(srcProgId) {
    const destProgId = this.localstore.destProgId;

    const data = await new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        `/programs/${destProgId}/mapping_source_program?src_prog=${srcProgId}`,
        (data) => {
          resolve(data);
        }
      );
    });
    sessionStorage.setItem('lastSelSrcProg', srcProgId);
    this.localstore.lessons = data.program_configs;

    /* Reload Table component (to close open disclosure) on lesson change */
    this.localstore.tableKey += 1;
    this.localstore.sourceChanged = true;
  }

  /**
   * Get all strands for selected lesson for dynamic dropdown
   * @param {number} lessonId - lesson Id.
   * @return {Promise} - promise that resolve to lesson strands.
   */
  getDestLessonStrands(lessonId) {
    const destProgId = this.localstore.destProgId;

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        `/programs/${destProgId}/mapping_dest_lesson_strands?dest_lesson=${lessonId}`,
        (data) => {
          resolve(data.program_configs);
        }
      );
    });
  }

  /**
   * Automatically populates the dest lesson and strand dropdowns.
   * @param {number} srcProgId - source program Id.
   */
  async mapAutomatically(srcProgId) {
    const data = await new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        `/programs/${this.localstore.destProgId}/map_automatically?src_prog_id=${srcProgId}`,
        (data) => {
          resolve(data);
        }
      );
    });
    const concepts = this.localstore.lessons.flatMap((lesson) => lesson.concepts);
    /**
     * The body of a for-in should be wrapped in an if statement to filter
     * unwanted properties from the prototype.
     */
    for (const conceptId in data) {
      if (Object.prototype.hasOwnProperty.call(data, conceptId)) {
        const concept = concepts.find((concept) => concept.id == conceptId);
        const lessonId = data[conceptId].dest_lesson_id;
        const strandId = data[conceptId].dest_strand_id;

        this.getDestLessonStrands(lessonId).then((strands) => {
          concept.strands_for_dest_lesson_array = strands.map((strand) => [strand.name, strand.id]);
          concept.selected_lesson = lessonId;
          concept.selected_strand = strandId;
        });
      }
    }
  }
}

export default ProgramToProgramMapping;
