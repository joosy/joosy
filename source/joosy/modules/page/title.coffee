#= require ../page

#
# Title management for Page (or possibly other widgets)
#
# @see Joosy.Page
# @mixin
#
Joosy.Modules.Page.Title =

  #
  # Sets the page HTML title.
  #
  # @note Title will be reverted on unload.
  #
  # @param [String] title       Title to set.
  # @param [String] separator   The string to use to `.join` when title is an array
  #
  # @example
  #   class TestPage extends Joosy.Page
  #     @title 'Test title'
  #
  # @example
  #   class TestPage extends Joosy.Page
  #     @title -> I18n.t('titles.test')
  #
  title: (title, separator=' / ') ->
    @afterLoad ->
      title = title.apply(@) if typeof(title) == 'function'
      title = title.join(separator) if title instanceof Array
      @__previousTitle = document.title
      document.title = title

    @afterUnload ->
      document.title = @__previousTitle