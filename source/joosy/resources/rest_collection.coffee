#= require ./array

#
# REST collection data
#
class Joosy.Resources.RESTCollection extends Joosy.Resources.Array
  #
  # @param [Joosy.Resources.REST] __resource        Resource this collection contains
  # @param [String] __where                         Location the collection has been fetched from
  #
  constructor: (@__resource, @__where) ->

  @beforeLoad (data) ->
    if data.constructor == Object && !(data = data[inflection.pluralize(@__resource::__entityName)])
      throw new Error "Invalid data for `all` received: #{JSON.stringify(data)}"

    data.map (x) =>
      instance = @__resource.build x
      # Substitute interpolation mask with actual path
      instance.__source = @__resource.collectionPath @__where if @__where.length > 1
      instance

  reload: (options = {}, callback = false) ->
    if typeof options == 'function'
      callback = options
      options = {}

    @__resource.send @__where, 'GET', options, (error, rawData, xhr) =>
      @load rawData if rawData?

      callback?(error, this, rawData, xhr)
