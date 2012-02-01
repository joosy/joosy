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

    @container = $ form
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
    if decorator?
      e = decorator resource.e
    else
      e = resource.e
    Object.each e, (key, val) =>
      key = resource.constructor.entityName() + "[#{key}]"
      @fields
        .filter("[name='#{key.underscore()}']:not(:file),[name='#{key.camelize(false)}']:not(:file)")
        .val val

    @container.attr 'action', resource.constructor.__buildSource(extension: resource.id)
    @__markMethod() if resource.id
    @container.attr 'method', 'POST'

  __success: (response, status, xhr) ->
    if xhr
      @success response
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
      Object.each errors, (field, notifications) =>
        if @substitutions[field]?
          field = @substitutions[field]
        input = @fields.filter("[name='#{field}']").addClass @invalidationClass
        @notification? input, notifications

  __markMethod: (method='PUT') ->
    method = $ '<input/>',
      type: 'hidden'
      name: '_method'
      value: method
    @container.append method
