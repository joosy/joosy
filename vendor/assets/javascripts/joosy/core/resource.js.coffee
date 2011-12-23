class Joosy.Resource extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  data:   {}
  params: {}

  constructor: (@source, opts={}) ->
    $.extend @, opts
    @pk ||= 'id'

  fetch: (callback) ->
    $.ajax Joosy.buildUrl(@source+'.json', @params),
      success    : callback
      dataType   : 'json'
      statusCode : @errorCallbacks()

  load: (callback, append=false) ->
    @fetch (data) =>
      @data = {} unless append
      @appendData(data)
      callback.call @, data

  find: (id, callback) ->
    $.ajax Joosy.buildUrl("#{@source}/#{id}.json", @params),
      dataType   : 'json'
      statusCode : @errorCallbacks()
      success    : (data) =>
                     data = @getShow(data) if @getShow
                     @appendData [data]
                     callback.call(@, data)

  destroy: (id, callback) ->
    $.ajax "#{@source}/#{id}.json",
      type       : 'DELETE'
      dataType   : 'json'
      statusCode : @errorCallbacks()
      success    : (data) =>
                     callback.call(this) if callback

  appendData: (data) ->
    $.each data, (key, val) => @data[val[@pk]] = val

  setParams: (params, clean=false) ->
    if clean
      @params = $.extend {}, params
    else
      $.extend @params, params

  attachForm: (form, opts={}) ->
    form = $(form) if typeof(form) == 'string'
    @fillForm(form, @data[opts.id]) unless opts.preload is false
    form.submit () =>
      $('input:submit', form).attr('disabled', true)
      [withIframe, data] = @getFormData(form)
      @sendItem withIframe, data, opts.id, (data) =>
        $('input:submit', form).removeAttr('disabled')
        @persisted(data) if @persisted
      , () =>
        $('input:submit', form).removeAttr('disabled')
      return false

  getFormData: (form) ->
    multipart = false
    data = {}
    entity = form.data('entity')
    for input in $('input:file', form)
      if input.files.length > 0
        multipart = true
        break
    unless multipart
      [false, @formToHash form, entity]
    else
      if window.FormData
        [false, @formToFormData form, entity]
      else
        [true, @formToIframeForm form, entity]

  formToFormData: (form, entity) ->
    data = new FormData()
    @eachSuccessfullElement form, true, (input) ->
      data.append "#{entity}[#{input.attr('name')}]", if input.attr('type') != 'file' then input.val() else input[0].files[0]
    return data

  formToHash: (form, entity) ->
    data = {}
    @eachSuccessfullElement form, false, (input) ->
      data["#{entity}[#{input.attr('name')}]"] = input.val()
    return data

  formToIframeForm: (form, entity) ->
    frame_form = form.clone()
    @eachSuccessfullElement frame_form, true, (input) ->
      input.attr 'name', "#{entity}[#{input.attr('name')}]"
      # jquery bug: does not clone textarea value
      input.val $('#'+input.attr('id'), form).val() if input.attr('id') && input.is('textarea')
    frame_form.attr enctype: 'multipart/form-data', method: 'POST'
    csrf_token = $('meta[name=csrf-token]').attr 'content'
    csrf_param = $('meta[name=csrf-param]').attr 'content'
    frame_form.append "<input type='hidden' name='#{csrf_param}' value='#{csrf_token}' />"
    return frame_form

  eachSuccessfullElement: (form, withFiles, callback) ->
    $('input, select, textarea', form).each (key, input) =>
      input = $(input)
      unless input.attr('type') == 'submit' || !input.attr('name') || input.is('[disabled]') || (!withFiles && input.attr('type') == 'file')
        callback(input)

  sendItem: (withIframe, data, id, onSuccess, onError) ->
    unless withIframe
      opts =
        data       : data
        type       : (if id then 'PUT' else 'POST')
        dataType   : 'json'
        statusCode : @errorCallbacks(onError)
        success    : onSuccess
      $.extend opts, { processData: false, contentType: false } if data instanceof FormData
      $.ajax (if id then "#{@source}/#{id}.json" else @source), opts
    else
      frame = $('<iframe></iframe>')
      frame.attr 'src', if /^https/i.test(window.location.href || '') then 'javascript:false' else 'about:blank'
      $('body').append frame
      frame.hide()
      frame.contents().find('body').append data
      data.append '<input name="_method" type="hidden" value="put" />' if id
      data.attr 'action', (if id then "#{@source}/#{id}.json" else @source)
      data.submit()
      frame.bind 'load', (e) => @checkIframeState(frame, onSuccess)

  checkIframeState: (frame, onSuccess) ->
    onSuccess $.parseJSON frame[0].contentDocument.body.innerHTML.replace(/^<[^>]+>/, '').replace(/<\/[^>]+>$/, '')
    frame.remove()

  errorCallbacks: (onError) ->
    422 : (xhr) =>
            @invalid($.parseJSON xhr.responseText) if @invalid
            onError.call(this) if onError
    401 : ->
            alert 'Unauthorized'
            onError.call(this) if onError
    403 : ->
            alert('Forbidden')
            onError.call(this) if onError

  fillForm: (form, data) ->
    $.each data, (key, val) ->
      input = $("[name=#{key}]", form)
      if input.attr('type') == 'file'
        input.data 'url', val
      else
        input.val val

  defineAction: (name, path, opts={}) ->
    opts.on ||= 'collection'
    opts.type ||= 'GET'
    @['load'+name] = (id, data, callback) ->
      $.ajax (if opts.on == 'collection' then "#{@source}/#{path}.json" else "#{@source}/#{id}/#{path}.json"),
        data       : if opts.on == 'collection' then id else data
        type       : opts.type
        dataType   : 'json'
        statusCode : @errorCallbacks()
        success    : if opts.on == 'collection' then data else callback