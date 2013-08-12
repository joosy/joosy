#= require joosy/joosy
#= require joosy/helpers/view

#
# Rendering and string representation helpers
#
Joosy.helpers 'Routes', ->

  @linkTo = (name='', url='', tagOptions={}) ->
    if Object.isFunction tagOptions
      block = tagOptions
      [url, tagOptions] = [name, url]
      name = block()

    Joosy.Helpers.Application.contentTag 'a', name, Joosy.Module.merge(tagOptions, 'data-joosy': true, href: url)