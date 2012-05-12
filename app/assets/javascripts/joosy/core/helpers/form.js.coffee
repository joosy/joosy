#= require joosy/core/joosy

#
# Form helper
#
Joosy.helpers 'Application', ->

  description = (resource, method) ->
    if resource instanceof Joosy.Resource.Generic
      id        = resource.id()
      resource  = resource.__entityName
      resource += resource + "_#{id}" if id

    name: resource + "[#{method}]"
    id:   resource + "_#{method}"

  input = (type, resource, method, options={}) ->
    description = description(resource, method)
    @tag 'input', options.merge(type: type, name: name, id: description.id, name: description.name)

  class Form
    constructor: (@context, @resource, @options) ->
    label: (method, options={}, content='') -> @context.label(@resource, method, options, content)
    textField: (method, options={}) -> @context.textField(@resource, method, options)
    fileField: (method, options={}) -> @context.fileField(@resource, method, options)
    hiddenField: (method, options={}) -> @context.hiddenField(@resource, method, options)
    passwordField: (method, options={}) -> @context.textField(@resource, method, options)
    radioButton: (method, tagValue, options={}) -> @context.radioButton(@resource, method, tagValue, options)
    textArea: (method, options={}) -> @context.textArea(@resource, method, options)
    check_box: (method, options={}, checkedValue=1, uncheckedValue=0) ->
      @context.check_box(@resource, method, options, checkedValue, uncheckedValue)

  @formFor = (resource, options={}, block=false) ->
    if Object.isFunction(options)
      block   = options
      options = {}

    uuid = Joosy.uuid()
    form = @tag 'form', {id: uuid}, block.call(this, new Form(this, resource, options))

    @onRefresh ->
      Joosy.Form.attach '#'+uuid, options.merge(resource: resource)

    form

  @label = (resource, method, options={}, content='') ->
    description = description(resource, method)
    if !Object.isObject(options)
      options = {}
      content = options

    @tag 'label', options.merge(for: description.id), content

  @textField     = (resource, method, options={}) -> input 'text', resource, method, options
  @fileField     = (resource, method, options={}) -> input 'file', resource, method, options
  @hiddenField   = (resource, method, options={}) -> input 'hidden', resource, method, options
  @passwordField = (resource, method, options={}) -> input 'password', resource, method, options

  @checkBox = (resource, method, options={}, checkedValue=1, uncheckedValue=0) ->
    description = description(resource, method)

    spy  = @tag 'input', type: 'hidden', name: description.name, id: description.id, value: uncheckedValue
    box  = @tag 'input', options.merge(type: 'checkbox', name: description.name, id: description.id, value: checkedValue)

    spy+box

  @radioButton = (resource, method, tagValue, options={}) ->
    @tag 'input', options.merge{type: 'radio', value: tagValue}.merge(description resource, method)

  @textArea = (resource, method, options={}) ->
    value = options.value
    delete options.value

    @tag 'textarea', options.merge(description resource, method), value