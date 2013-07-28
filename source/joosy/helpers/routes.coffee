#= require joosy/joosy
#= require joosy/helpers/view

#
# Rendering and string representation helpers
#
Joosy.helpers 'Routes', ->

  @linkTo = (name='', url='', tagOptions={}) ->
    Joosy.Helpers.Application.contentTag 'a', name, Joosy.Module.merge(tagOptions, 'data-joosy': true, href: url)