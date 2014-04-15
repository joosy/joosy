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

  @beforeLoad (data) ->
    if @constructor.__mappedAttributes?
      for name, options of @constructor.__mappedAttributes
        klass = options.klass
        klass = klass() unless klass.build?

        if data[name] instanceof Array
          entries = data[name]
          data[name] = new klass::__collection klass
          data[name].load entries
        else if data[name]?
          data[name] = klass.build data[name]

    data

  @beforeSave (data) ->
    if @constructor.__mappedAttributes?
      data = Joosy.Module.merge {}, data

      for name, options of @constructor.__mappedAttributes
        continue unless data[name]?

        if options.save instanceof Function
          save = options.save.call this
        else
          save = options.save

        if save
          data["#{name}_attributes"] =
            if data[name].asSerializableData?
              data[name].asSerializableData()
            else
              throw new Error "Mapped attribute is not collection nor entity and cannot be saved"

        delete data[name]

    data

  #
  # Calls beforeSave hooks and converts the entity to serialized form
  #
  asSerializableData: (decoratedName = false) ->
    data = @__applyBeforeSaves(@data)

    if decoratedName
      req = {}
      req[@__entityName] = data
      req
    else
      data

# AMD wrapper
if define?.amd?
  define 'joosy/resources/entity', -> Joosy.Resources.Entity
