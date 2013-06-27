#= require ./collection

#
# Collection of REST Resources
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
#
class Joosy.Resources.RESTCollection extends Joosy.Resources.Collection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Refetches the data from backend and triggers `changed`
  #
  # @param [Hash] options         See {Joosy.Resources.REST.find} for possible options
  # @param [Function] callback    Resulting callback
  #
  reload: (options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @model.__query @model.collectionPath(options), 'GET', options.params, (data) =>
      @load data
      callback?(data)
