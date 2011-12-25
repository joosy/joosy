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

  constructor: (form, @success) ->
    @container = $(form)
    @refreshElements()
    @__delegateEvents()

    @hasFiles = @fields.filter('input:file:enabled[value]').length > 0

    @__markIframe() if @hasFiles
    @__markMethod() if ['put', 'delete'].has @container.attr('method').toLowerCase()

    @container.ajaxForm
      iframe: @hasFiles
      dataType: 'json'
      beforeSend: => @__before(arguments...) 
      success: => @__success(arguments...)
      error: => @__error(arguments...)

  __success: (response) ->
    if !@hasFiles
      @success(response)
    else if response.status == 200
      @success(response.json)
    else
      @__error(response.json)

  __before: ->
    if !@before? || @before(arguments...)
      @fields.removeClass(@invalidationClass)
      
  __error: (data) ->
    errors = if data.responseText
      try
        Object.extended(jQuery.parseJSON(data.responseText))
      catch error
        Object.extended()
    else
      Object.extended(data)

    if !@error? || @error(errors)
      errors.each (field, notifications) =>
        field = @substitutions[field] if @substitutions[field]?
        input = @fields.filter("[name='#{field}']").addClass(@invalidationClass)
        @notification?(input, notifications)
  
  __markIframe: () ->
    mark = $ '<input />', 
      type: 'hidden'
      name: 'joosy-iframe'
      value: true
    @container.append mark
    
  __markMethod: () ->
    method = $ '<input/>',
      type: 'hidden'
      name: '_method'
      value: @container.attr('method')
    @container.append(method).attr('method', 'post')