#= require ./array

#
# REST collection data
#
class Joosy.Resources.RESTCollection extends Joosy.Resources.Array
  constructor: (resource, where) ->
    @__resource = resource
    @__where = where

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
