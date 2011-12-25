class Joosy.Resource extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  constructor: (@source, opts={}) ->
    @params = {}
    @data = {}
    $.extend @, opts
    @pk ||= 'id'
  
  fetch: (path, opts, callback) ->
    defaults =
      dataType : 'json'
      statusCode : @errorCallbacks()
      success : callback
    opts = $.extend {}, defaults, opts
    $.ajax Joosy.buildUrl(path+'.json', @params), opts
  
  load: (callback, opts={}) ->
    if opts.cache && @loaded
      callback @data
      return
    @fetch @source, {}, (data) =>
      data = @getIndex(data) if @getIndex
      @data = {} unless opts.append
      @appendData data
      @loaded = true
      callback data

  find: (id, callback) ->
    @fetch "#{@source}/#{id}", { data : @params }, (data) =>
      data = @getShow(data) if @getShow
      @appendData [data]
      callback.call(@, data)

  destroy: (id, callback) ->
    @fetch "#{@source}/#{id}", { type : 'DELETE' }, (data) =>
      callback.call(this) if callback

  appendData: (data) ->
    $.each data, (key, val) => @data[val[@pk]] = val

  setParams: (params, clean=false) ->
    @params = {} if clean
    $.extend @params, params

  attachForm: (form, opts={}) ->
    form = $(form) if typeof(form) == 'string'
    @fillForm(form, @data[opts.id]) unless opts.preload is false
    
    form.submit () =>
      $('input:submit', form).attr 'disabled', true
      @onAttachedFormSubmit form, opts.id, => $('input:submit', form).removeAttr('disabled')
      return false

  onAttachedFormSubmit: (form, id, doneCallback) ->
    onSuccess = (data) =>
      @persisted(data) if @persisted
      doneCallback()
    multipart = @detectFilesInForm form
    if multipart && !window.FormData
      @sendFormWithIframe form, id, @getEntityName(form), onSuccess
    else
      data = if multipart then @formToFormData(form, @getEntityName(form)) else @formToHash(form, @getEntityName(form))
      @sendItem data, id, onSuccess, () =>
        doneCallback()

  detectFilesInForm: (form) ->
    multipart = false
    for input in $('input:file', form)
      if input.files.length > 0
        multipart = true
        break
    return multipart
  
  getEntityName: (form) ->
    form.data('entity')

  formToFormData: (form, entity) ->
    data = new FormData()
    @eachSuccessfullElement form, true, (input) =>
      data.append @paramNameFor(entity, input), if input.attr('type') != 'file' then input.val() else input[0].files[0]
    return data

  formToHash: (form, entity) ->
    data = {}
    @eachSuccessfullElement form, false, (input) =>
      data[@paramNameFor(entity, input)] = input.val()
    return data

  eachSuccessfullElement: (form, withFiles, callback) ->
    $('input, select, textarea', form).each (key, input) =>
      input = $(input)
      unless input.attr('type') == 'submit' || !input.attr('name') || input.is('[disabled]') || (!withFiles && input.attr('type') == 'file')
        callback(input)

  sendItem: (data, id, onSuccess, onError) ->
    opts =
      data : data
      type : (if id then 'PUT' else 'POST')
    $.extend opts, { processData: false, contentType: false } if data instanceof FormData
    @fetch (if id then "#{@source}/#{id}" else @source), opts, onSuccess

  sendFormWithIframe: (form, id, entity, onSuccess) ->
    frame_form = form.clone()
    frame_form.attr enctype: 'multipart/form-data', method: 'POST', action: (if id then "#{@source}/#{id}.json" else @source+'.json')
    
    @eachSuccessfullElement frame_form, true, (input) =>
      if input.attr('name') && input.is('textarea') # jquery bug: does not clone textarea value
        input.val $("textarea[name='#{input.attr('name')}']", form).val()
      input.attr 'name', @paramNameFor(entity, input)

    csrf_token = $('meta[name=csrf-token]').attr 'content'
    csrf_param = $('meta[name=csrf-param]').attr 'content'
    frame_form.append "<input type='hidden' name='#{csrf_param}' value='#{csrf_token}' />"
    
    frame_form.prepend '<input name="_method" type="hidden" value="put" />' if id
    
    frame = $('<iframe></iframe>')
    frame.attr 'src', if /^https/i.test(window.location.href || '') then 'javascript:false' else 'about:blank'
    $('body').append frame
    frame.hide()
    frame.contents().find('body').append frame_form
    frame_form.submit()
    frame.bind 'load', (e) => @checkIframeState(frame, onSuccess)

  checkIframeState: (frame, onSuccess) ->
    # TODO: How can we understand 422 Unacceptable entity?
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

  fillForm: (form, data, entity=false) ->
    $.each data, (key, val) ->
      rkey = if entity then "#{entity}[#{key}]" else key
      input = $("[name='#{rkey}']", form)
      if input.attr('type') == 'file'
        input.data 'url', val
      else
        input.val val

  defineAction: (name, path, opts={}) ->
    opts.on ||= 'collection'
    opts.type ||= 'GET'
    @['load'+name] = (id, data, callback) ->
      $.ajax (if opts.on == 'collection' then "#{@source}/#{path}.json" else "#{@source}/#{id}/#{path}.json"),
        data : if opts.on == 'collection' then id else data
        type : opts.type
        dataType : 'json'
        statusCode : @errorCallbacks()
        success : if opts.on == 'collection' then data else callback