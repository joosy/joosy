#= require joosy/core/joosy

#
# Set of system-wide helpers built-in into Joosy
#
# @class Joosy.Helpers.Application
#
Joosy.helpers 'Application', ->
  
  #
  # Converts \n into <br/> in your text
  #
  # @param [String] text      Text to convert
  #
  @nl2br = (text) ->
    text.toString().replace /\n/g, '<br/>'
