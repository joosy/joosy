#
# AJAXifies form including file uploads and stuff. Built on top of jQuery.Form.
#
# Joosy.Form automatically cares of form validation highlights. It can
# read common server error responses and add .field_with_errors class to proper
# field.
#
# If you don't have resource associated with form (#fill), it will try to find fields
# by exact keywords from response. Otherwise it will search for resource_name[field].
#
# @example Joosy.Form usage
#   form = new Joosy.Form, -> (response)
#     console.log "Saved and got some: #{response}"
#
#   form.progress = (percent) -> console.log "Uploaded by #{percent}%"
#   form.fill @resource
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.DOM
#
class Joosy.Form extends Joosy.Module
  @include Joosy.Modules.DOM
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Marks the CSS class to use to mark invalidated fields
  #
  invalidationClass: 'field_with_errors'

  #
  # List of mappings for fields of invalidated data which comes from server
  #
  # If you have something like {foo: 'bar', bar: 'baz'} coming from server
  # substitutions = {foo: 'foo_id'} will change it to {foo_id: 'bar', bar: 'baz'}
  #
  substitutions: {}

  #
  # List of elements for internal usage
  #
  @mapElements
    'fields': 'input,select,textarea'

  #
  # Makes one AJAX request with form data without binding
  #
  # @see #constructor
  #
  # @param [Element] form          Instance of HTML form element
  # @param [Hash] options          Options
  #
  @submit: (form, options={}) ->
    form = new @(form, options)
    form.$container.submit()
    form.unbind()
    null

  @attach: ->
    new Joosy.Form arguments...

  #
  # During initialization replaces your basic form submit with AJAX request
  #
  # @note If method of form differs from POST or GET it will simulate it
  # by adding hidden _method input. In this cases the method itself will be
  # set to POST.
  #
  # @note For browsers having no support of HTML5 Forms it may do an iframe requests
  # to handle file uploading.
  #
  # @param [jQuery] form        Form element instance
  # @param [Hash] options       Options
  #
  # @option options [Function] before        `(XHR) -> Bollean` to trigger right before submit.
  #   By default will run form invalidation cleanup. This behavior can be canceled
  #   by returning false from your own before callback. Both of callbacks will run if
  #   you return true.
  #
  # @option options [Function] success       `(Object) -> null` triggers on 2xx HTTP code from server.
  #   Pases in the parsed JSON.
  #
  # @option options [Function] progress      `(Float) -> null` runs periodically while form is uploading
  #
  # @option options [Function] error         `(Object) -> Boolean` triggers if server responded with anything but 2xx.
  #   By default will run form invalidation routine. This behavior can be canceled
  #   by returning false from your own error callback. Both of callbacks will run if
  #   you return true.
  #
  # @option options [Joosy.Resources.Base] resource        The resource to fill the form with
  # @option options [String] resourceName                  The string to use as a resource name prefix for fields to match invalidation
  # @option options [String] action                        Action URL for the form
  # @option options [String] method                        HTTP method, for example PUT, that will passed in _method param
  # @option options [Boolean] debounce                     Drop submit events while there is a pending submit request
  #
  constructor: (form, options={}) ->
    if Object.isFunction options
      @success = options
    else
      Object.each options, (key, value) =>
        @[key] = value

    @$container = $(form)
    return if @$container.length == 0

    @__assignElements()
    @__delegateEvents()

    method = @$container.get(0).getAttribute('method')?.toLowerCase()
    if method && !['get', 'post'].any method
      @__markMethod method
      @$container.attr 'method', 'POST'

    @$container.ajaxForm
      dataType: 'json'
      beforeSend: =>
        return false if @__debounce arguments...
        @__before arguments...
        @__pending_request = true
        @debugAs this, 'beforeSend: pending_request = true'
        true
      success: =>
        @__pending_request = false
        @debugAs this, 'success: pending_request = false'
        @__success arguments...
      error: =>
        @__pending_request = false
        @debugAs this, 'error: pending_request = false'
        @__error arguments...
      xhr: =>
        xhr = $.ajaxSettings.xhr()
        if xhr.upload? && @progress
          xhr.upload.onprogress = (event) =>
            if event.lengthComputable
              @progress (event.position / event.total * 100).round 2
        xhr

    if @resource?
      @fill(@resource, options)
      delete @resource

    if @action?
      @$container.attr 'action', @action
      @$container.attr 'method', 'POST'

    if @method?
      @__markMethod @method

  #
  # Resets form submit behavior to default
  #
  unbind: ->
    @$container.unbind('submit').find('input:submit,input:image,button:submit').unbind('click')

  #
  # Links current form with given resource and sets values of form inputs from with it.
  # Form will use give resource while doing invalidation routine.
  #
  # @param [Resource] resource      Resource to fill fields with
  # @param [Hash] options           Options
  #
  # @option options [Function] decorator     `(Object) -> Object` decoration callback
  #   Pases in the parsed JSON.
  #
  # @option options [String] action          Action URL for the form
  #
  fill: (resource, options) ->
    resource = resource.build() if Object.isFunction(resource.build)
    @__resource = resource

    if options?.decorator?
      data = options.decorator resource.data
    else
      data = resource.data

    filler = (data, scope) =>
      return if data.__joosy_form_filler_lock
      data.__joosy_form_filler_lock = true
      Object.each data, (property, val) =>
        key = @concatFieldName scope, property
        input = @$fields("[name='#{key}']:not(:file),[name='#{key.underscore()}']:not(:file),[name='#{key.camelize(false)}']:not(:file)")
        if input.length > 0
          if input.is ':checkbox'
            if val
              input.attr 'checked', 'checked'
            else
              input.removeAttr 'checked'
          else if input.is ':radio'
            input.filter("[value='#{val}']").attr 'checked', 'checked'
          else
            input.val val
        if val instanceof Joosy.Resources.RESTCollection
          for entity, i in val.data
            filler entity.data, @concatFieldName(scope, "[#{property}_attributes][#{i}]")
        else if val instanceof Joosy.Resources.REST
          filler val.data, @concatFieldName(scope, "[#{property}_attributes][0]")
        else if Object.isObject(val) || Object.isArray(val)
          filler val, key
        else
      delete data.__joosy_form_filler_lock

    filler data, resource.__entityName || options.resourceName

    $('input[name=_method]', @$container).remove()
    @__markMethod(options?.method || 'PUT') if resource.id()

    url = options?.action || (if resource.id()? then resource.memberPath() else resource.collectionPath())

    @$container.attr 'action', url
    @$container.attr 'method', 'POST'

  #
  # Submit the HTML Form
  #
  submit: ->
    @$container.submit()

  #
  # Serializes form into query string.
  #
  # @param [Boolean] skipMethod         Determines if we should skip magical _method field
  #
  # @return [String]
  #
  serialize: (skipMethod=true) ->
    data = @$container.serialize()
    data = data.replace /\&?\_method\=put/i, '' if skipMethod

    data

  #
  # Inner success callback.
  #
  __success: (response, status, xhr) ->
    if xhr
      @success? response
    else if 200 <= response.status < 300
      @success response.json
    else
      @__error response.json

  #
  # Inner before callback.
  # By default will clean invalidation.
  #
  __before: (xhr, settings) ->
    if !@before? || @before(arguments...) is true
      @$fields().removeClass @invalidationClass

  #
  # Inner error callback.
  # By default will trigger basic invalidation.
  #
  __error: (data) ->
    errors = if data.responseText
      try
        data = jQuery.parseJSON(data.responseText)
      catch error
        {}
    else
      data

    if !@error? || @error(errors) is true
      errors = @__stringifyErrors(errors)

      Object.each errors, (field, notifications) =>
        input = @findField(field).addClass @invalidationClass
        @notification? input, notifications

      return errors

    return false

  #
  # Aborts form submit if there is already another one pending XHR
  #
  __debounce: (xhr) ->
    @debugAs this, "debounce: pending_request == #{@__pending_request}"
    if @__pending_request && @debounce != false
      if @debounce || Joosy.Form.debounceForms
        xhr.abort()
        @debugAs this, "debounce: xhr aborted"
        return true
    false

  #
  # Finds field by field name.
  # This is not inlined since we want to override
  # or monkeypatch it from time to time
  #
  # @param [String] field         Name of field to find
  #
  findField: (field) ->
    @$fields("[name='#{field}']")

  #
  # Simulates REST methods by adding hidden _method input with real method
  # while setting POST as the transport method
  #
  # @param [String] method      Real method to simulate
  #
  __markMethod: (method='PUT') ->
    method = $('<input/>',
      type: 'hidden'
      name: '_method'
      value: method
    )
    @$container.append method

  #
  # Prepares server response for default error handler
  # Turns all possible response notations into form notation (foo[bar])
  # Every direct field of incoming data will be decorated by @substitutions
  #
  # @example Flat validation result
  #   { field1: ['error'] }             # input
  #   { field1: ['error'] }             # if form was not associated with Resource by {#fill}
  #   { "fluffy[field1]": ['error']}    # if form was associated with Resource (named fluffy)
  #
  # @example Complex validation result
  #   { foo: { bar: { baz: ['error'] } } }    # input
  #   { "foo[bar][bar]": ['error'] }          # output
  #
  # @param [Object] errors        Data to prepare
  #
  # @return [Hash<String, Array>]          Flat hash with field names in keys and arrays
  #   of errors in values
  #
  __stringifyErrors: (errors) ->
    result = {}

    Object.each errors, (field, notifications) =>
      if @substitutions[field]?
        field = @substitutions[field]

      if Object.isObject(notifications) || @isArrayOfObjects(notifications)
        Object.each @__foldInlineEntities(notifications), (key, value) ->
          result[field+key] = value
      else
        if field.indexOf(".") != -1
          splited = field.split '.'
          field   = splited.shift()
          if @resourceName || @__resource
            name    = @resourceName || @__resource.__entityName
            field   = name + "[#{field}]"
          field  += "[#{f}]" for f in splited

        else if @resourceName || @__resource
          name  = @resourceName || @__resource.__entityName
          field = name + "[#{field}]"

        result[field] = notifications

    result

  #
  # Flattens complex inline structures into form notation
  #
  # @example Basic flattening
  #   data  = foo: { bar: { baz: [] } }
  #   inner = @__foldInlineEntities(data.foo, 'foo')
  #
  #   inner # { "foo[bar][baz]": [] }
  #
  # @param [Object] hash      Structure to fold
  # @param [String] scope     Prefix for resulting scopes
  # @param [Object] result    Context of result for recursion
  #
  # @return [Hash]
  #
  __foldInlineEntities: (hash, scope="", result={}) ->
    Object.each hash, (key, value) =>
      if Object.isObject(value) || @isArrayOfObjects(value)
        @__foldInlineEntities(value, "#{scope}[#{key}]", result)
      else
        result["#{scope}[#{key}]"] = value

    result

  concatFieldName: (wrapper, name) ->
    items = @splitFieldName(wrapper).concat @splitFieldName(name)
    "#{items[0]}[#{items.slice(1).join('][')}]"

  splitFieldName: (name) ->
    items = name.split('][')
    first = items[0].split('[')
    if first.length == 2
      if first[0].isBlank()
        items.splice 0, 1, first[1]
      else
        items.splice 0, 1, first[0], first[1]
      items[items.length - 1] = items[items.length - 1].split(']')[0]
    items

  isArrayOfObjects: (array) ->
    Object.isArray(array) && array.every((elem) -> Object.isObject(elem))
