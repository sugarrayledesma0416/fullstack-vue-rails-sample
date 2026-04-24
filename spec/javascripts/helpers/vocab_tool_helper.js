//this does not work
function vocab_ctrl_inject($rootScope, $controller, VocabWords) {
inject(function($rootScope, $controller, VocabWords) {

        scope = $rootScope.$new();
        ctrl = $controller(VocabCtrl, {
            $scope: scope,
            VocabWords: VocabWords
        });

        $httpBackend.flush();

        //our mock data is 2 objects long. check that scope.vocab words is same length
        expect(scope.vocab_words.length).toEqual(1);
    })


}
