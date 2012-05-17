#= require joosy/core/joosy

#
# Form helper
#
Joosy.helpers 'Application', ->

  description = (resource, method, extendIds) ->
    if resource instanceof Joosy.Resource.Generic
      id        = resource.id()
      resource  = resource.__entityName

    name: resource + "#{if method.match(/^\[.*\]$/) then method else "[#{method}]"}"
    id:   resource + (if id && extendIds then '_'+id else '') + "_#{method.parameterize().underscore()}"

  input = (type, resource, method, options={}) =>
    d = description(resource, method, options.extendIds)
    delete options.extendIds
    @tag 'input', Joosy.Module.merge {type: type, name: d.name, id: d.id}, options

  class Form
    constructor: (@context, @resource, @options) ->
    label: (method, options={}, content='') -> @context.label(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options), content)
    textField: (method, options={}) -> @context.textField(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    fileField: (method, options={}) -> @context.fileField(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    hiddenField: (method, options={}) -> @context.hiddenField(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    passwordField: (method, options={}) -> @context.passwordField(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    radioButton: (method, tagValue, options={}) -> @context.radioButton(@resource, method, tagValue, Joosy.Module.merge(extendIds: @options.extendIds, options))
    textArea: (method, options={}) -> @context.textArea(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    checkBox: (method, options={}, checkedValue=1, uncheckedValue=0) ->
      @context.checkBox(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options), checkedValue, uncheckedValue)

  @formFor = (resource, options={}, block) ->
    if Object.isFunction(options)
      block   = options
      options = {}

    uuid = Joosy.uuid()
    form = @tag 'form', Joosy.Module.merge(options.html || {}, id: uuid), block?.call(this, new Form(this, resource, options))

    @onRefresh? -> Joosy.Form.attach '#'+uuid, Joosy.Module.merge(options, resource: resource)

    form

  @label = (resource, method, options={}, content='') ->
    if !Object.isObject(options)
      content = options
      options = {}

    d = description(resource, method, options.extendIds)
    delete options.extendIds

    @tag 'label', Joosy.Module.merge(options, for: d.id), content

  @textField     = (resource, method, options={}) -> input 'text', resource, method, options
  @fileField     = (resource, method, options={}) -> input 'file', resource, method, options
  @hiddenField   = (resource, method, options={}) -> input 'hidden', resource, method, options
  @passwordField = (resource, method, options={}) -> input 'password', resource, method, options
  @radioButton = (resource, method, tagValue, options={}) -> input 'radio', resource, method, Joosy.Module.merge(value: tagValue, options)

  @checkBox = (resource, method, options={}, checkedValue=1, uncheckedValue=0) ->
    spy = input 'hidden', resource, method, value: uncheckedValue, extendIds: options.extendIds
    box = input 'checkbox', resource, method, Joosy.Module.merge(value: checkedValue, options)

    spy+box

  @textArea = (resource, method, options={}) ->
    value     = options.value
    extendIds = options.extendIds
    delete options.value
    delete options.extendIds

    @tag 'textarea', Joosy.Module.merge(description(resource, method, extendIds), options), value