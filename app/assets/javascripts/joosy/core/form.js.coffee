#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container

#
# AJAXifies form including file uploads and stuff. Built on top of jQuery.Form
#
# Joosy.Form automatically cares of form validation hihglights. It can
# read common server error responses and add .field_with_errors class to proper 
# field.
#
# If you don't have resource associated (#fill) with form it will try to find fields
# by exact keywords from response. Otherwise it will search for resource_name[field].
#
#
# Example
#   form = new Joosy.Form, -> (response)
#     console.log "Saved and got some: #{response}"
#
#   form.progress = (percent) -> console.log "Uploaded by #{percent}%"
#   form.fill @resource
#
class Joosy.Form extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container

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
  elements:
    'fields': 'input,select,textarea'

  #
  # Submits your form once and unbinds leaving it simple form without AJAX
  #
  # @param [Element] form       Instance of HTML form element
  # @param [Object] opts        Map of additional options (see constructor)
  #
  @submit: (form, opts={}) ->
    form = new @(form, opts)
    form.container.submit()
    form.unbind()
    null

  #
  # During initialization replaces your basic form submit with AJAX request
  #
  # If method of form differs from POST or GET it will simulate it
  # by adding hidden _method input. In this cases the method itself will be
  # set to POST.
  #
  # For browsers having no support of HTML5 Forms it may do an iframe requests
  # to handle file uploading.
  #
  # Supported options are:
  #
  # * before: `(XHR) -> Boolean` triggers right before submit.
  #   By default will run form invalidation cleanup. This behavior can be canceled
  #   by returning false from your own before callback. Both of callbacks will run if
  #   you return true.
  #
  # * success: `(Object) -> null` triggers on 200 HTTP code from server. Pases 
  #   in the parsed JSON.
  #
  # * progress: `(Float) -> null` runs peridically while form is uploading.
  #
  # * error: `(Object) -> Boolean` triggers if server responsed with anything but 200.
  #   By default will run form invalidation routine. This behavior can be canceled
  #   by returning false from your own error callback. Both of callbacks will run if
  #   you return true.
  # 
  #
  constructor: (form, opts={}) ->
    if Object.isFunction opts
      @success = opts
    else
      Object.each opts, (key, value) =>
        @[key] = value

    @container = $(form)
    @refreshElements()
    @__delegateEvents()

    method = @container.get(0).getAttribute('method')?.toLowerCase()
    if method && !['get', 'post'].has method
      @__markMethod method
      @container.attr 'method', 'POST'

    @container.ajaxForm
      dataType: 'json'
      beforeSend: =>
        @__before arguments...
      success: =>
        @__success arguments...
      error: =>
        @__error arguments...
      xhr: =>
        xhr = $.ajaxSettings.xhr()
        if xhr.upload? && @progress
          xhr.upload.onprogress = (event) =>
            if event.lengthComputable
              @progress (event.position / event.total * 100).round 2
        xhr

  #
  # Resets form submit behavior
  #
  unbind: ->
    @container.unbind('submit').find('input:submit,input:image,button:submit').unbind('click');

  #
  # Sets values of form inputs from given resource.
  # Form will remember given resource and will use it while doing
  # invalidation routine.
  #
  # @param [Resource] resource      Resource to fill fields with
  # @param [Function] decorator     Decoration callback
  #
  fill: (resource, decorator) ->
    @__resource = resource
    
    if decorator?
      e = decorator resource.e
    else
      e = resource.e
    Object.each e, (key, val) =>
      key = resource.__entityName + "[#{key}]"
      input = @fields.filter("[name='#{key.underscore()}']:not(:file),[name='#{key.camelize(false)}']:not(:file)")
      unless input.is ':checkbox'
        input.val val
      else
        if val
          input.attr 'checked', 'checked'
        else
          input.removeAttr 'checked'

    @container.attr 'action', resource.constructor.__buildSource(extension: resource.id)
    @__markMethod() if resource.id
    @container.attr 'method', 'POST'

  #
  # Submit the HTML Form
  #
  submit: ->
    @container.submit()
  
  #
  # Serializes form into query string
  #
  # @param [Boolean] skipMethod         Determines if we should skip magical _method field
  #
  serialize: (skipMethod=true) ->
    data = @container.serialize()
    data = data.replace /\&?\_method\=put/i, '' if skipMethod
    
    data

  #
  # Inner success callback
  #
  __success: (response, status, xhr) ->
    if xhr
      @success? response
    else if response.status == 200
      @success response.json
    else
      @__error response.json

  #
  # Inner before callback
  # By default will clean invalidation
  #
  __before: (xhr, settings) ->
    if !@before? || @before(arguments...) is true
      @fields.removeClass @invalidationClass

  #
  # Inner error callback
  # By default will trigger basic invalidation
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
        input = @__findField(field).addClass @invalidationClass
        @notification? input, notifications
        
  #
  # Finds field by field name.
  # This is not inlined since we want to override
  # or monkeypatch it from time to time
  #
  # @param [String] field         Name of field to find
  #
  __findField: (field) ->
    @fields.filter("[name='#{field}']")

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
    @container.append method
    
  #
  # Prepares server response for default error handler
  # Turns all possible response notations into form notation (foo[bar])
  # Every direct field of incoming data will be decorated by @substitutions
  #
  # Possible notations:
  #
  # * Flat validation result
  #   # input
  #   { field1: ['error'] }
  #   # if form was not associated with @__resource (see #fill)
  #   { "field1": ['error'] }
  #   # if form was associated with resource (named fluffy)
  #   { "fluffy[field1]": ['error']}
  #
  # * Complex validation result
  #   # input
  #   { foo: { bar: { baz: ['error'] } } }
  #   # output
  #   { "foo[bar][bar]": ['error'] }
  #
  # @param [Object] errors        Data to prepare
  #
  __stringifyErrors: (errors) ->
    result = {}
    
    Object.each errors, (field, notifications) =>
      if @substitutions[field]?
        field = @substitutions[field]

      if Object.isObject notifications
        Object.each @__foldInlineEntities(notifications), (key, value) ->
          result[field+key] = value
      else
        if field.indexOf(".") != -1
          splited = field.split '.'
          field   = splited.shift()
          field   = @__resource.__entityName + "[#{field}]" if @__resource
          field  += "[#{f}]" for f in splited
      
        else if @__resource
          field = @__resource.__entityName + "[#{field}]"

        result[field] = notifications

    result

  #
  # Flattens complex inline structures into form notation
  #
  # Example:
  #   data  = foo: { bar: { baz: [] } }
  #   inner = @__foldInlineEntities(data.foo, 'foo')
  #
  #   inner # { "foo[bar][baz]": [] }
  #
  # @param [Object] hash      Structure to fold
  # @param [String] scope     Prefix for resulting scopes
  # @param [Object] result    Context of result for recursion
  #
  __foldInlineEntities: (hash, scope="", result={}) ->
    Object.each hash, (key, value) =>
      if Object.isObject(value)
        @__foldInlineEntities(value, "#{scope}[#{key}]", result)
      else
        result["#{scope}[#{key}]"] = value

    result