import ProgramToProgramMapping from 'features/program_config/models/program_to_program_mapping';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

const localstore = {
  lessons: [],
  destProgId: 1,
};

const modalParams = {
  confirmButtonText: '',
  currentDestForSrcId: '',
  currentDestForSrcName: '',
};


let getDestinationUrl = '';
let mapAutomaticallyUrl = '';
let mapDestinationLessonUrl = '';
let mappingSourceProgramUrl = '';
let removeMappingUrl = '';

describe('ProgramToProgramMapping', () => {
  let programToProgramMapping;
  document.body.innerHTML = '<div id="mapping_src_program"></div>';

  describe('onSrcProgramChange', () => {
    const params = {
      noCurrentSrc: true,
      srcProgId: 2,
    };
    getDestinationUrl = '/programs/1/current_dest_for_src?src_prog=2';
    mappingSourceProgramUrl = '/programs/1/mapping_source_program?src_prog=2';

    describe('When there is no mapping for the source and destination', () => {
      beforeEach(async () => {
        fetchMock.mock(getDestinationUrl, {
          status: 200, body: null,
        });
        fetchMock.mock(mappingSourceProgramUrl, { status: 200, body: [] });
        params.noCurrentSrc = true;
        programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        programToProgramMapping.onSrcProgramChange(params);
        await fetchMock.flush(true);
      });

      it(
        'makes an ajax request for the lesson strands for source and destination',
        () => {
          expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
            mappingSourceProgramUrl,
            jasmine.any(Function)
          );
        }
      );

      afterEach(() => fetchMock.restore());
    });

    describe('When there mapping for current destination but not for selected source', () => {
      beforeEach(async () => {
        fetchMock.mock(getDestinationUrl, {
          status: 200, body: null,
        });
        params.noCurrentSrc = false;
        programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
        programToProgramMapping.onSrcProgramChange(params);
        await fetchMock.flush(true);
      });

      it(
        'sets modal parameters according to type "mapping-change-src"',
        () => {
          expect(programToProgramMapping.modalParams.type).toBe('mapping-change-src');
          expect(programToProgramMapping.modalParams.confirmButtonText).toBe('Set Source');
        }
      );

      afterEach(() => fetchMock.restore());
    });

    describe('When there mapping for selected source  but not for current destination', () => {
      beforeEach(async () => {
        fetchMock.mock(getDestinationUrl, {
          status: 200, body: { id: 3, name: 'Test Program' },
        });
        params.noCurrentSrc = true;
        programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
        programToProgramMapping.onSrcProgramChange(params);
        await fetchMock.flush(true);
      });

      it(
        'sets modal parameters according to type "mapping-already-in-use"',
        () => {
          expect(programToProgramMapping.modalParams.type).toBe('mapping-already-in-use');
          expect(programToProgramMapping.modalParams.confirmButtonText).toBe('Delete Mapping');
        }
      );

      afterEach(() => fetchMock.restore());
    });

    describe('When there mapping for current destination and selected source', () => {
      beforeEach(async () => {
        fetchMock.mock(getDestinationUrl, {
          status: 200, body: { id: 3, name: 'Test Program' },
        });
        params.noCurrentSrc = false;
        programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
        programToProgramMapping.onSrcProgramChange(params);
        await fetchMock.flush(true);
      });

      it(
        'sets modal parameters according to type "mapping-change-and-in-use"',
        () => {
          expect(programToProgramMapping.modalParams.type).toBe('mapping-change-and-in-use');
          expect(programToProgramMapping.modalParams.confirmButtonText).toBe('Delete & Set Source');
        }
      );

      afterEach(() => fetchMock.restore());
    });
  });

  describe('getDestForSrc', () => {
    beforeEach(async () => {
      getDestinationUrl = '/programs/1/current_dest_for_src?src_prog=2';
      fetchMock.mock(getDestinationUrl, {
        status: 200, body: { id: 3, name: 'Test Program' },
      });
      programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      programToProgramMapping.getDestForSrc(2);
      await fetchMock.flush(true);
    });

    it(
      'makes an ajax request to get current destination for the source',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          getDestinationUrl,
          jasmine.any(Function)
        );
      }
    );

    afterEach(() => fetchMock.restore());
  });

  describe('declineSourceProgramChange', () => {
    beforeEach(async () => {
      mappingSourceProgramUrl = '/programs/1/mapping_source_program?src_prog=2';
      fetchMock.mock(mappingSourceProgramUrl, {
        status: 200, body: { id: 3, name: 'Test Program' },
      });
      programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      programToProgramMapping.declineSourceProgramChange();
      await fetchMock.flush(true);
    });

    it(
      'makes an ajax request for the lesson strands for old source and destination',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          mappingSourceProgramUrl,
          jasmine.any(Function)
        );
      }
    );

    afterEach(() => fetchMock.restore());
  });

  describe('confirmSourceProgramChange', () => {
    beforeEach(async () => {
      removeMappingUrl = '/programs/1/remove_existing_mappings?current_dest_for_src=2';
      mappingSourceProgramUrl = '/programs/1/mapping_source_program?src_prog=3';
      fetchMock.mock(removeMappingUrl, {
        status: 200, body: null,
      });

      fetchMock.mock(mappingSourceProgramUrl, {
        status: 200, body: null,
      });
      programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      programToProgramMapping.confirmSourceProgramChange(3, 2);
      await fetchMock.flush(true);
    });

    it(
      'makes an ajax request to remove mapping between destination and old source',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          removeMappingUrl,
          jasmine.any(Function)
        );
      }
    );

    it(
      'makes an ajax request for the lesson strands for new source and destination',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          mappingSourceProgramUrl,
          jasmine.any(Function)
        );
      }
    );

    afterEach(() => fetchMock.restore());
  });

  describe('getDestLessonStrands', () => {
    beforeEach(async () => {
      mapDestinationLessonUrl = '/programs/1/mapping_dest_lesson_strands?dest_lesson=2';
      fetchMock.mock(mapDestinationLessonUrl, {
        status: 200, body: null,
      });

      programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      programToProgramMapping.getDestLessonStrands(2);
      await fetchMock.flush(true);
    });

    it(
      'makes an ajax request to get all strands for selected lesson ',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          mapDestinationLessonUrl,
          jasmine.any(Function)
        );
      }
    );

    afterEach(() => fetchMock.restore());
  });

  describe('mapAutomatically', () => {
    beforeEach(async () => {
      localstore.lessons = [{ concepts: [{ id: 1 }] }];
      mapAutomaticallyUrl = '/programs/1/map_automatically?src_prog_id=2';
      mapDestinationLessonUrl = '/programs/1/mapping_dest_lesson_strands?dest_lesson=2';
      fetchMock.mock(mapAutomaticallyUrl, {
        status: 200, body: { 1: { dest_lesson_id: 2 }},
      });
      fetchMock.mock(mapDestinationLessonUrl, {
        status: 200, body: { program_configs: [] },
      });

      programToProgramMapping = new ProgramToProgramMapping(localstore, modalParams);
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      programToProgramMapping.mapAutomatically(2);
      await fetchMock.flush(true);
    });

    it(
      'makes an ajax request to map dest lesson and strand ',
      () => {
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          mapAutomaticallyUrl,
          jasmine.any(Function)
        );
      }
    );

    afterEach(() => fetchMock.restore());
  });
});
