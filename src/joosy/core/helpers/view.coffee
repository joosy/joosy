#= require joosy/core/joosy

#
# Rendering and string representation helpers
#
Joosy.helpers 'Application', ->

  #
  # Generates HTML tag string
  #
  # @param [String] name          Tag name
  # @param [Object] options       Tag attributes
  # @param [String] content       String content to inject
  # @param [Function] content     Function that will be evaluated and the result will be taken as a content
  #
  # Example
  #   != @tag 'div', {class: 'foo'}, =>
  #     != @tag 'hr'
  #
  @tag = (name, options={}, content='') ->
    content = content() if Object.isFunction(content)

    element = document.createElement name
    temp    = document.createElement 'div'

    Object.each options, (name, value) -> element.setAttribute name, value

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
