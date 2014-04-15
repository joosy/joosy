#= require ./collection

#
# Collection data
#
class Joosy.Resources.Collection extends Joosy.Resources.Array
  #
  # @param [Joosy.Modules.Resources.Model] __resource        Resource this collection contains

  constructor: (@__resource, collection) ->
    super collection

  @beforeLoad (data) ->
    data.map (x) =>
      instance = @__resource.build x
      instance
