#= require ./collection

#
# Collection data
#
class Joosy.Resources.Collection extends Joosy.Resources.Array
  @registerPlainFilters 'beforeSave'

  #
  # @param [Joosy.Modules.Resources.Model] __resource        Resource this collection contains
  # @param [Array]                         collection        Data this collection contains
  #
  constructor: (@__resource, collection) ->
    super collection

  @beforeLoad (data) ->
    data.map (x) =>
      instance = @__resource.build x
      instance

  #
  # Calls beforeSave hooks and converts the collection to serialized form
  #
  asSerializableData: ->
    @map (entity) ->
      entity.asSerializableData()

# AMD wrapper
if define?.amd?
  define 'joosy/resources/collection', -> Joosy.Resources.Collection
