##
# This module can be used to enforce a particular $state based workflow.
# Override the `validTransitions` constant to customize workflow enforcement.
#
mod = angular.module('transitionGateway', [
  'ui.router',
  'angularSpinner',
  'idCacheFactories'
])

mod.constant('validTransitions', {
  'root': ['dialer.ready'],
  'abort': ['dialer.ready'],
  'dialer.ready': ['abort', 'dialer.hold'],
  'dialer.hold': ['abort', 'dialer.active', 'dialer.stop'],
  'dialer.active': ['abort', 'dialer.wrap', 'dialer.stop', 'dialer.active.transfer.selected', 'dialer.active.transfer.reselected', 'dialer.active.transfer.conference'],
  'dialer.active.transfer.selected': ['abort', 'dialer.active', 'dialer.wrap', 'dialer.active.transfer.conference', 'dialer.active.transfer.reselect'],
  'dialer.active.transfer.reselect': ['abort', 'dialer.active', 'dialer.wrap', 'dialer.active.transfer.conference', 'dialer.active.transfer.selected'],
  'dialer.active.transfer.conference': ['abort', 'dialer.active', 'dialer.wrap'],
  'dialer.wrap': ['abort', 'dialer.hold', 'dialer.stop', 'dialer.ready'],
  'dialer.stop': ['abort', 'dialer.ready']
})

mod.factory('transitionValidator', [
  '$rootScope', 'validTransitions', 'ErrorCache', 'HouseholdCache', 'usSpinnerService',
  ($rootScope,   validTransitions,   ErrorCache,   HouseholdCache,   usSpinnerService) ->
    {
      reviewTransition: (eventObj, toState, toParams, fromState, fromParams) ->
        toName   = toState.name
        fromName = fromState.name || 'root'
        getPhone = ->
          household = HouseholdCache.get('data')
          phone   = ''
          if household? and household.phone?
            phone = household.phone
          phone
        getMeta = ->
          caller = CallStationCache.get('caller')
          campaign = CallStationCache.get('campaign')
          {caller, campaign}

        entry = validTransitions[fromName]

        if !entry? || entry.indexOf(toName) == -1
          phone = getPhone()
          ErrorCache.put('InvalidTransition prevented', {toName, fromName, phone})
          $rootScope.transitionInProgress = false
          usSpinnerService.stop('global-spinner')
          eventObj.preventDefault()

      start: ->
        if angular.isFunction(@stop)
          @stop()
        @stop = $rootScope.$on('$stateChangeStart', @reviewTransition)

      stop: ->
    }
])
