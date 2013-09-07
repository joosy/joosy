#
# @private
#
class Form
  constructor: (@context, @resource, @options) ->

  __extend: (options) ->
    options.extendIds = @options.extendIds
    options

  for type in ['text', 'file', 'hidden', 'password']
    do (type) =>
      @::[type+'Field'] = (property, options={}) ->
        @context[type+'Field'] @resource, property, @__extend(options)

  label: (property, options={}, content='') ->
    # (property, content) ->
    if arguments.length == 2
      content = options
      options = {}

    @context.label @resource, property, @__extend(options), content

  radioButton: (property, tagValue, options={}) ->
    @context.radioButton @resource, property, tagValue, @__extend(options)

  textArea: (property, options={}) ->
    @context.textArea @resource, property, @__extend(options)

  checkBox: (property, options={}, checkedValue=1, uncheckedValue=0) ->
    @context.checkBox @resource, property, @__extend(options), checkedValue, uncheckedValue

  select: (property, selectOptions={}, options={}) ->
    @context.select @resource, property, selectOptions, @__extend(options)

#
# Form helper
#
Joosy.helpers 'Application', ->

  separateOptions = (options, keys) ->
    attributes = {}
    parameters = {}

    for key, value of options
      if keys.indexOf(key) != -1
        parameters[key] = value
      else
        attributes[key] = value

    [parameters, attributes]

  #
  # Generates main attributes of a single field for a form
  #
  # @param [String]  resource            Name of resource
  # @param [Object]  resource            Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String]  property            Name of attribute the field is for
  # @param [Boolean] extendIds           Marks whether DOM id of a field should contain primary key of resource
  # @param [String]  idSuffix            Suffix to append to DOM id
  # @param [Hash]    DOM attributes      Initial set that should be extended
  #
  domify = (resource, property, extendIds, idSuffix, attributes) ->
    if resource.__entityName? && resource.id?
      resourceId = resource.id()
      resource   = resource.__entityName

    unless attributes
      attributes = {}
    else
      attributes = Joosy.Module.merge {}, attributes

    attributes.name  = resource
    attributes.name += if property.match(/^\[.*\]$/) then property else "[#{property}]"

    # Parameterizing property
    property = property.replace(/[^a-z0-9\-_]+/gi, '_')
    property = property.replace /^_+|_+$|(_)_+/g, '$1'
    property = property.toLowerCase()

    attributes.id  = resource
    attributes.id += "_#{resourceId}" if resourceId? && extendIds
    attributes.id += "_#{property}"
    attributes.id += "_#{idSuffix}" if idSuffix

    attributes

  #
  # Generates input field
  #
  input = (type, resource, property, extendIds, idSuffix, attributes={}) =>
    attributes.type = type
    attributes = domify(resource, property, extendIds, idSuffix, attributes)

    @tag 'input', attributes

  #
  # ======================================================================
  #

  #
  # Instantiates a form builder
  #
  # @param [String]   resource             Name of resource
  # @param [Object]   resource             Instance of something that includes Joosy.Modules.Resources.Module
  # @param [Function] block                Inline template that will be rendered as a form
  # @param [Object] options
  #
  # @option options [Boolean] extendIds    Marks if DOM ids of fields should include primary key of resource (default: false)
  #
  # @example
  #   != @formFor Resource, {extendIds: true}, (form) =>
  #     != form.textField 'property'
  #
  @formFor = (resource, options={}, block) ->
    # (options, block) ->
    if arguments.length == 2
      block   = options
      options = {}

    attributes = Joosy.Module.merge(options.html || {}, id: uuid)
    uuid = Joosy.uuid()
    form = new Form @, resource, options

    @tag 'form', attributes, block?.call(@, form)

  #
  # Generates `label` tag
  #
  # @param [String] resource               Name of resource
  # @param [Object] resource               Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String] property               Attribute of a resource to use
  # @param [Object] options
  # @option options [Boolean] extendIds    Marks if DOM ids of fields should include primary key of resource (default: false)
  # @param [String] content                Content of the label
  #
  @label = (resource, property, options={}, content='') ->
    # (resource, property, content) ->
    if arguments.length == 3
      content = options
      options = {}

    [parameters, attributes] = separateOptions options, ['extendIds']

    attributes.for = domify(resource, property, parameters.extendIds, '', attributes).id

    @contentTag 'label', content, attributes

  #
  # Set of typical generators for basic inputs: textField, fileField, hiddenField, passwordField
  #
  for type in ['text', 'file', 'hidden', 'password']
    do (type) =>
      @[type+'Field'] = (resource, property, options={}) ->
        [parameters, attributes] = separateOptions options, ['extendIds']

        input type, resource, property, parameters.extendIds, '', attributes

  #
  # Generates a radio button
  #
  # @param [String] resource               Name of resource
  # @param [Object] resource               Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String] property               Attribute of a resource to use
  # @param [Object] options
  # @option options [Boolean] extendIds    Marks if DOM ids of fields should include primary key of resource (default: false)
  # @param [String] tagValue               Value of the button
  #
  @radioButton = (resource, property, tagValue, options={}) ->
    [parameters, attributes] = separateOptions(options, ['extendIds'])

    attributes.value = tagValue
    input 'radio', resource, property, options.extendIds, tagValue, attributes

  #
  # Generates a checkbox
  #
  # @param [String] resource               Name of resource
  # @param [Object] resource               Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String] property               Attribute of a resource to use
  # @param [Object] options
  # @option options [Boolean] extendIds    Marks if DOM ids of fields should include primary key of resource (default: false)
  # @param [String] checkedValue           Value for the checked condition
  # @param [String] uncheckedValue         Value for the unchecked condition
  #
  @checkBox = (resource, property, options={}, checkedValue=1, uncheckedValue=0) ->
    [parameters, attributes] = separateOptions(options, ['extendIds'])

    spyAttributes = domify resource, property, parameters.extendIds, '', attributes
    spy = @tag 'input', name: spyAttributes.name, value: uncheckedValue, type: 'hidden'

    attributes.value = checkedValue
    box = input 'checkbox', resource, property, parameters.extendIds, '', attributes

    spy+box

  #
  # Generates a select
  #
  # @param [String] resource                Name of resource
  # @param [Object] resource                Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String] property                Attribute of a resource to use
  # @param [Object] options
  # @option options [Boolean] extendIds     Marks if DOM ids of fields should include primary key of resource (default: false)
  # @option options [String] value          Sets current value of a select
  # @option options [Boolean] includeBlank  Marks if select should contain blank starting option
  # @param [Object] selectOptions           Options to build select with `{foo: 'bar'}`
  # @param [Array] selectOptions            Options to build select with `['foo', 'bar']`
  #
  @select = (resource, property, rawSelectOptions, options) ->
    [parameters, attributes] = separateOptions(options, ['extendIds', 'value', 'includeBlank'])

    if rawSelectOptions instanceof Array
      selectOptions = rawSelectOptions
    else
      selectOptions = []
      selectOptions.push [val, key] for key, val of rawSelectOptions

    selectOptions.unshift ['', ''] if parameters.includeBlank
    selectOptions = selectOptions.reduce (str, vals) =>
      params = if (vals instanceof Array) then ['option', vals[0], { value: vals[1] }] else ['option', vals, {}]
      if parameters.value == (if (vals instanceof Array) then vals[1] else vals)
        params[2].selected = 'selected'
      str += @contentTag.apply @, params
    , ''

    @contentTag 'select', selectOptions, domify(resource, property, parameters.extendIds, '', attributes)

  #
  # Generates a text area
  #
  # @param [String] resource               Name of resource
  # @param [Object] resource               Instance of something that includes Joosy.Modules.Resources.Module
  # @param [String] property               Attribute of a resource to use
  # @param [Object] options
  # @option options [Boolean] extendIds    Marks if DOM ids of fields should include primary key of resource (default: false)
  # @option options [String] value         Value of the text area
  #
  @textArea = (resource, property, options={}) ->
    [parameters, attributes] = separateOptions(options, ['extendIds', 'value'])
    @contentTag 'textarea', parameters.value, domify(resource, property, parameters.extendIds, '', attributes)
