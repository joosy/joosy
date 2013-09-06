#
# Form helper
#
Joosy.helpers 'Application', ->

  description = (resource, method, extendIds, idSuffix) ->
    if resource.__entityName? && resource.id?
      id        = resource.id()
      resource  = resource.__entityName

    name: resource + "#{if method.match(/^\[.*\]$/) then method else "[#{method}]"}"
    id:   resource + (if id && extendIds then '_'+id else '') + "_#{method.parameterize().underscore()}" + (if idSuffix then '_'+idSuffix else '')

  input = (type, resource, method, options={}) =>
    d = description(resource, method, options.extendIds, options.idSuffix)
    delete options.extendIds
    delete options.idSuffix
    @tag 'input', Joosy.Module.merge {type: type, name: d.name, id: d.id}, options

  #
  # @private
  #
  class Form
    constructor: (@context, @resource, @options) ->

    label: (method, options={}, content='') ->
      if !Object.isObject(options)
        content = options
        options = {}

      @context.label(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options), content)

    radioButton: (method, tagValue, options={}) -> @context.radioButton(@resource, method, tagValue, Joosy.Module.merge(extendIds: @options.extendIds, options))
    textArea: (method, options={}) -> @context.textArea(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options))
    checkBox: (method, options={}, checkedValue=1, uncheckedValue=0) -> @context.checkBox(@resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options), checkedValue, uncheckedValue)
    select: (method, options={}, htmlOptions={}) -> @context.select @resource, method, options, Joosy.Module.merge(extendIds: @options.extendIds, htmlOptions)

  ['text', 'file', 'hidden', 'password'].each (type) =>
    Form.prototype[type+'Field'] = (method, options={}) ->
      @context[type+'Field'] @resource, method, Joosy.Module.merge(extendIds: @options.extendIds, options)

  @formFor = (resource, options={}, block) ->
    if Object.isFunction(options)
      block   = options
      options = {}

    uuid = Joosy.uuid()
    form = @tag 'form', Joosy.Module.merge(options.html || {}, id: uuid), block?.call(this, new Form(this, resource, options))
    form

  @label = (resource, method, options={}, content='') ->
    if !Object.isObject(options)
      content = options
      options = {}

    d = description(resource, method, options.extendIds)
    delete options.extendIds

    @contentTag 'label', content, Joosy.Module.merge(options, for: d.id)

  ['text', 'file', 'hidden', 'password'].each (type) =>
    @[type+'Field'] = (resource, method, options={}) -> input type, resource, method, options

  @radioButton = (resource, method, tagValue, options={}) -> input 'radio', resource, method, Joosy.Module.merge(value: tagValue, idSuffix: tagValue, options)

  @checkBox = (resource, method, options={}, checkedValue=1, uncheckedValue=0) ->
    spy = @tag 'input', Joosy.Module.merge(name: description(resource, method).name, value: uncheckedValue, type: 'hidden')
    box = input 'checkbox', resource, method, Joosy.Module.merge(value: checkedValue, options)

    spy+box

  @select = (resource, method, options, htmlOptions) ->
    if Object.isObject options
      opts = []
      for key, val of options
        opts.push [val, key]
    else
      opts = options
    if htmlOptions.includeBlank
      delete htmlOptions.includeBlank
      opts.unshift ['', '']
    opts = opts.reduce (str, vals) =>
      params = if Object.isArray vals then ['option', vals[0], { value: vals[1] }] else ['option', vals, {}]
      if htmlOptions.value == (if Object.isArray(vals) then vals[1] else vals)
        params[2].selected = 'selected'
      str += @contentTag.apply @, params
    , ''
    extendIds = htmlOptions.extendIds
    delete htmlOptions.value
    delete htmlOptions.extendIds
    @contentTag 'select', opts, Joosy.Module.merge(description(resource, method, extendIds), htmlOptions)

  @textArea = (resource, method, options={}) ->
    value     = options.value
    extendIds = options.extendIds
    delete options.value
    delete options.extendIds

    @contentTag 'textarea', value, Joosy.Module.merge(description(resource, method, extendIds), options)
