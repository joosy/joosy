#= require joosy/joosy
#= require joosy/helpers/view

#
# Rendering and string representation helpers
#
Joosy.helpers 'Routes', ->

  @linkTo = (name='', url='', tagOptions={}) ->
    Joosy.Helpers.Application.tag 'a', Joosy.Module.merge(tagOptions, 'data-joosy': true, href: url), name