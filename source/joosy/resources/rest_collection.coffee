#= require ./collection

#
# REST collection data
#
class Joosy.Resources.RESTCollection extends Joosy.Resources.Collection
  #
  # @param [Joosy.Resources.REST] __resource        Resource this collection contains
  # @param [String] __where                         Location the collection has been fetched from
  #
  constructor: (@__resource, @__where) ->

  @prependBeforeLoad (data) ->
    if data.constructor == Object && !(data = data[inflection.pluralize(@__resource::__entityName)])
      throw new Error "Invalid data for `all` received: #{JSON.stringify(data)}"

    data

  @beforeLoad (data) ->
    for instance in data
      # Substitute interpolation mask with actual path
      instance.__source = @__resource.collectionPath @__where if @__where? && @__where.length > 1

    data

  reload: (options = {}, callback = false) ->
    if typeof options == 'function'
      callback = options
      options = {}

    @__resource.send @__where, 'GET', options, (error, rawData, xhr) =>
      @load rawData if rawData?

      callback?(error, this, rawData, xhr)
