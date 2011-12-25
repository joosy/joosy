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

    @container.ajaxForm
      success: => @success?(arguments...)
      complete: => @complete?(arguments...)
      
      beforeSend: => 
        if !@before? || @before(arguments...)
          @fields.removeClass(@invalidationClass)
          
      error: (evt, xhr, status, error) => 
        if !@error? || @error(arguments...)
          errors = Object.extended(jQuery.parseJSON(xhr.responseText))
          
          errors.each (field, notifications) ->
            field = @substitutions[field] if substitutions[field]?
            input = @fields.filter("[name=#{field}]").addClass(@invalidationClass)
            @notification?(input, notifications)