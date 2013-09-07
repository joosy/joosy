#= require joosy/joosy
#= require joosy/helpers/view

#
# Rendering and string representation helpers
#
Joosy.helpers 'Routes', ->

  @linkTo = (name='', url='', tagOptions={}) ->

    # (url, tagOptions, block) ->
    if typeof(tagOptions) == 'function'
      block = tagOptions
      [url, tagOptions] = [name, url]
      name = block()

    Joosy.Helpers.Application.contentTag 'a', name, Joosy.Module.merge(tagOptions, 'data-joosy': true, href: url)