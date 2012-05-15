class Joosy.Resource.RESTCollection extends Joosy.Resource.Collection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  load: (entities, notify=true) ->
    super entities, false
    @trigger 'changed' if notify
    this

  reload: (options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @model.__query @model.collectionPath(options), 'GET', options.params, (data) =>
      @load data
      callback?(data)