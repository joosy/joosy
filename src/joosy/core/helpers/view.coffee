#= require joosy/core/joosy

#
# Rendering and string representation helpers
#
Joosy.helpers 'Application', ->

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
  # Converts \n into <br/> in your text
  #
  # @param [String] text      Text to convert
  #
  @nl2br = (text) ->
    text.toString().replace /\n/g, '<br/>'

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
