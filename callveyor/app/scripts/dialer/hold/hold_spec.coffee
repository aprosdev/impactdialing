describe 'dialer.hold', ->
  $stateFake  = {}
  dialerFake  = {}
  flashFake   = {}
  spinnerFake = {}
  callStation = {
    caller: {
      id: 42
      session_id: 12
    }
    campaign: {
      type: 'Power'
    }
  }
  contact = {
    data: {
      id: 9
      fields: {
        first_name: 'Awnry'
        last_name: 'Aviary'
      }
    }
  }
  household = {
    phone: '123-543-1234'
    members: [contact.data]
  }

  beforeEach module('callveyor.dialer.hold', ($provide) ->
    ->
      $provide.value('$state', $stateFake)
      $provide.value('idHttpDialerFactory', dialerFake)
      $provide.value('idFlashFactory', flashFake)
      $provide.value('usSpinnerService', spinnerFake)
  )

  describe 'HoldCtrl.buttons', ->
    $rootScope    = ''
    $scope        = ''
    $state        = ''
    $cacheFactory = ''
    $controller   = ''

    beforeEach(inject(
      (_$rootScope_, _$state_, _$cacheFactory_, _$controller_) ->
        $rootScope             = _$rootScope_
        $scope                 = $rootScope
        $controller            = _$controller_
        $state                 = _$state_
        $cacheFactory          = _$cacheFactory_
        $state.go              = jasmine.createSpy('-$state.go spy-')
        dialerFake.dialContact = jasmine.createSpy('-idHttpDialerFactory.dialContact spy-')
        flashFake.now          = jasmine.createSpy('-idFlashFactory.now spy-')

        $controller('HoldCtrl.buttons', {$scope, callStation})
    ))

    it 'assigns callStation.campaign to $scope.hold.campaign', ->
      expect($scope.hold.campaign).toEqual(callStation.campaign)

    describe '$scope.hold.stopCalling()', ->
      it 'transitions to dialer.stop', ->
        $scope.hold.stopCalling()
        expect($state.go).toHaveBeenCalledWith('dialer.stop')

    describe '$scope.hold.dial()', ->
      describe '$cacheFactory("Household") exists and has "data"', ->
        beforeEach ->
          $cacheFactory.get('Household').put('data', household)

        it 'updates status message', ->
          curStatus = $scope.hold.callStatusText
          $scope.hold.dial()
          expect($scope.hold.callStatusText).not.toEqual(curStatus)

        it 'sets $scope.transitionInProgress to true', ->
          expect($scope.transitionInProgress).toBeFalsy()
          $scope.hold.dial()
          expect($scope.transitionInProgress).toBeTruthy()

        it 'calls idHttpDialerFactory.dialContact(caller_id, {session_id: Num, phone: Num})', ->
          caller_id = callStation.caller.id
          params = {
            phone: household.phone
            session_id: callStation.caller.session_id
          }
          $scope.hold.dial()
          expect(dialerFake.dialContact).toHaveBeenCalledWith(caller_id, params)
