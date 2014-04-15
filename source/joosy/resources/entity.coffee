#= require ./hash
#= require joosy/modules/resources/model
#= require ./collection

#
# Resource without backend
#
# @concern Joosy.Modules.Resources.Model
#
class Joosy.Resources.Entity extends Joosy.Resources.Hash
  @concern Joosy.Modules.Resources.Model

  @registerPlainFilters 'beforeSave'

  #
  # Calls beforeSave hooks and converts the entity to serialized form
  #
  asSerializableData: ->
    @__applyBeforeSaves(@data)

# AMD wrapper
if define?.amd?
  define 'joosy/resources/entity', -> Joosy.Resources.Entity
