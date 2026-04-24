//= require assessment

describe ("VHL.Assessments", function(){
  describe( '#update_assessment', function(){

    var request;

    beforeEach( function(){
      jasmine.Ajax.useMock();
      spyOn(VHL.Assessments, 'update_release_status');
      VHL.Assessments.update_assessment(24, 'blargh');
      request = mostRecentAjaxRequest();
    })

    it( 'makes a get request', function(){
      expect(request.method).toBe('GET');
    })

    it( 'updates the release status on successful get request', function(){
      request.response({status: 200, responseText: ''});
      expect(VHL.Assessments.update_release_status).toHaveBeenCalled();
    });
  });
});
