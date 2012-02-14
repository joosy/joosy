#= require joosy/core/joosy

#
# Rendering and string representation helpers
#
Joosy.helpers 'Application', ->
  
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