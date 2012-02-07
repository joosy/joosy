#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container

class Joosy.Form extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container

  invalidationClass: 'field_with_errors'
  substitutions: {}

  elements:
    'fields': 'input,select,textarea'

  @submit: (form, opts={}) ->
    form = new @(form, opts)
    form.container.submit()
    form.unbind()
    null

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

  unbind: ->
    @container.unbind('submit').find('input:submit,input:image,button:submit').unbind('click');

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

  __success: (response, status, xhr) ->
    if xhr
      @success? response
    else if response.status == 200
      @success response.json
    else
      @__error response.json

  __before: (xhr, settings) ->
    if !@before? || @before(arguments...) is true
      @fields.removeClass @invalidationClass

  __error: (data) ->
    errors = if data.responseText
      try
        jQuery.parseJSON data.responseText
      catch error
        {}
    else
      data

    if !@error? || @error(errors) is true
      errors = @__stringifyErrors(errors)
      
      Object.each errors, (field, notifications) =>
        input = @fields.filter("[name='#{field}']").addClass @invalidationClass
        @notification? input, notifications

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