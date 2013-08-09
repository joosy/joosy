#= require joosy/joosy
#= require joosy/helpers/view

#
# Rendering and string representation helpers
#
Joosy.helpers 'Routes', ->

  @linkTo = (name='', url='', tagOptions={}) ->
    if Object.isFunction tagOptions
      url = name
      tagOptions = url
      name = tagOptions()

    Joosy.Helpers.Application.contentTag 'a', name, Joosy.Module.merge(tagOptions, 'data-joosy': true, href: url)