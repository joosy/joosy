#= require joosy/core/joosy

#
# Form helper
#
Joosy.helpers 'Application', ->

  description = (resource, method) ->
    if resource instanceof Joosy.Resource.Generic
      id        = resource.id()
      resource  = resource.__entityName
      resource += "_#{id}" if id

    name: resource + "#{if method.match(/^\[.*\]$/) then method else "[#{method}]"}"
    id:   resource + "_#{method.parameterize().underscore()}"

  input = (type, resource, method, options={}) =>
    d = description(resource, method)
    @tag 'input', Joosy.Module.merge options, {type: type, name: d.name, id: d.id}

  class Form
    constructor: (@context, @resource, @options) ->
    label: (method, options={}, content='') -> @context.label(@resource, method, options, content)
    textField: (method, options={}) -> @context.textField(@resource, method, options)
    fileField: (method, options={}) -> @context.fileField(@resource, method, options)
    hiddenField: (method, options={}) -> @context.hiddenField(@resource, method, options)
    passwordField: (method, options={}) -> @context.passwordField(@resource, method, options)
    radioButton: (method, tagValue, options={}) -> @context.radioButton(@resource, method, tagValue, options)
    textArea: (method, options={}) -> @context.textArea(@resource, method, options)
    checkBox: (method, options={}, checkedValue=1, uncheckedValue=0) ->
      @context.checkBox(@resource, method, options, checkedValue, uncheckedValue)

  @formFor = (resource, options={}, block) ->
    if Object.isFunction(options)
      block   = options
      options = {}

    uuid = Joosy.uuid()
    form = @tag 'form', Object.merge(options.html || {}, id: uuid), block?.call(this, new Form(this, resource, options))

    @onRefresh? -> Joosy.Form.attach '#'+uuid, Object.merge(options, resource: resource)

    form

  @label = (resource, method, options={}, content='') ->
    d = description(resource, method)
    if !Object.isObject(options)
      content = options
      options = {}

    @tag 'label', Joosy.Module.merge(options, for: d.id), content

  @textField     = (resource, method, options={}) -> input 'text', resource, method, options
  @fileField     = (resource, method, options={}) -> input 'file', resource, method, options
  @hiddenField   = (resource, method, options={}) -> input 'hidden', resource, method, options
  @passwordField = (resource, method, options={}) -> input 'password', resource, method, options

  @checkBox = (resource, method, options={}, checkedValue=1, uncheckedValue=0) ->
    d = description(resource, method)

    spy  = @tag 'input', type: 'hidden', name: d.name, id: d.id, value: uncheckedValue
    box  = @tag 'input', Joosy.Module.merge(options, type: 'checkbox', name: d.name, id: d.id, value: checkedValue)

    spy+box

  @radioButton = (resource, method, tagValue, options={}) ->
    options = Joosy.Module.merge(options, type: 'radio', value: tagValue)
    @tag 'input', Joosy.Module.merge(options, description resource, method)

  @textArea = (resource, method, options={}) ->
    value = options.value
    delete options.value

    @tag 'textarea', Joosy.Module.merge(options, description resource, method), value