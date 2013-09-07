#= require joosy/joosy

#
# Rendering and string representation helpers
#
Joosy.helpers 'Application', ->

  # Little helpers for HTML escaping
  DOMtext = document.createTextNode("test")
  DOMnative = document.createElement("span")
  DOMnative.appendChild(DOMtext)

  #
  # Escapes HTML string
  #
  # @param [String] html                     String to escape
  # @return [String]                         Escaped string
  #
  @escapeOnce = (html) ->
    DOMtext.nodeValue = html
    DOMnative.innerHTML

  #
  # Generates HTML string
  #
  # @param [String]  name                    Tag name
  # @param [Object]  options                 Tag attributes
  # @param [Boolean] open                    Marks whether standalone tags (like <br>) should be kept open
  # @param [Boolean] escape                  Marks whether atribute values should be escaped
  # @return [String]                         Tag HTML string
  #
  @tag = (name, options={}, open=false, escape=true) ->
    element = document.createElement name
    temp    = document.createElement 'div'

    for name, value of options
      value = @escapeOnce(value) if escape
      element.setAttribute name, value

    temp.appendChild element
    tag = temp.innerHTML

    tag = tag.replace('/>', '>') if open
    tag

  #
  # Generates HTML tag string with given content
  #
  # @param [String] name                     Tag name
  # @param [Object] contentOrOptions         Tag attributes
  # @param [String] contentOrOptions         String content
  # @param [Object] options                  Tag attributes
  # @param [Boolean] escape                  Marks whether attribute values should be escaped
  # @return [String]                         Tag HTML string
  #
  # Possible arguments variations:
  #   1. @contentTag 'name', 'content'
  #   2. @contentTag 'name', {}, ->
  #   3. @contentTag 'name', {}, false, ->
  #   4. @contentTag 'name', ->
  #
  # Example
  #   != @contentTag 'div', {class: 'foo'}, =>
  #     != @contentTag 'hr'
  #
  @contentTag = (name, contentOrOptions=null, options=null, escape=true) ->
    # This is a bit painfull but this is
    # how we emulate Ruby block with lambda :(
    if typeof(contentOrOptions) == 'string'
      options ||= {}
      content   = contentOrOptions
    else if contentOrOptions.constructor == Object
      if typeof(options) == 'function'
        escape = true
        content = options()
      else
        escape = options
        content = escape()
      options = contentOrOptions
    else
      options = {}
      content = contentOrOptions()

    element = document.createElement name
    temp    = document.createElement 'div'

    for name, value of options
      value = @escapeOnce(value) if escape
      element.setAttribute name, value

    try
      element.innerHTML = content
    catch e
      # setting innerHTML fails in the IE for elements, which cann't have children (INPUT, for ex.)
      # suppress this error unless content looks valuable
      throw e if content

    temp.appendChild element
    temp.innerHTML

  #
  # Wraps the inline block into given template
  # Request template will receive the inline block as @yield parameter
  #
  # Example
  #   -# foo/baz template
  #   != @renderWrapped 'foo/bar', ->
  #     %b This string will be passed to 'foo/bar'
  #
  #   -# foo/bar template
  #   %h1 I'm the wrapper here!
  #     != @yield
  #
  @renderWrapped = (template, lambda) ->
    @render template, Joosy.Module.merge(this, yield: lambda())
