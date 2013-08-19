require 'sugar'

module.exports = (grunt) ->
  #
  # Locations
  #
  locations =
    source:
      root: 'joosy.coffee'
      path: 'source'
      build: 'build/joosy.js'
      extensions: (name) ->
        root: "joosy/extensions/#{name || '*'}"
        build: "build/joosy/extensions/#{name || '**/*'}.js"
    specs:
      helpers: [
        'bower_components/sinonjs/sinon.js',
        'bower_components/sugar/release/sugar-full.min.js',
        'spec/helpers/*.coffee'
      ]

  testemOptions =
    parallel: 8
    launch_in_dev: ['PhantomJS'],
    launch_in_ci: ['PhantomJS', 'Chrome', 'Firefox', 'Safari', 'IE7', 'IE8', 'IE9']

  #
  # Grunt extensions
  #
  grunt.loadTasks 'lib/tasks'
  grunt.loadNpmTasks 'grunt-contrib-testem'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-release'

  #
  # Config
  #
  grunt.initConfig
    mince:
      core:
        include: [locations.source.path]
        src: locations.source.root
        dest: locations.source.build
      resources:
        include: [locations.source.path]
        src: locations.source.extensions('resources').root
        dest: locations.source.extensions('resources').build
      form:
        include: [locations.source.path]
        src: locations.source.extensions('resources-form').root
        dest: locations.source.extensions('resources-form').build

    coffeelint:
      source:
        files:
          src: [locations.source.path + '/joosy/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    testem:
      core:
        src: locations.specs.helpers
          .include('bower_components/jquery/jquery.js')
          .include(locations.source.build)
          .include('spec/joosy/core/**/*_spec.coffee')
        options: testemOptions
      zepto:
        src: locations.specs.helpers
          .include('bower_components/zepto/zepto.js')
          .include(locations.source.build)
          .include('spec/joosy/core/**/*_spec.coffee')
        options: testemOptions
      'environments-global':
        src: locations.specs.helpers
          .include('bower_components/jquery/jquery.js')
          .include(locations.source.build)
          .include('spec/joosy/environments/global_spec.coffee')
        options: testemOptions
      'environments-amd':
        src: locations.specs.helpers
          .include('bower_components/jquery/jquery.js')
          .include('bower_components/requirejs/require.js')
          .include(locations.source.build)
          .include('spec/joosy/environments/amd_spec.coffee')
        options: testemOptions
      extensions:
        src: locations.specs.helpers
          .include('bower_components/jquery/jquery.js')
          .include('bower_components/jquery-form/jquery.form.js')
          .include(locations.source.build)
          .include(locations.source.extensions().build)
          .include('spec/joosy/extensions/**/*_spec.coffee')
        options: testemOptions

    release:
      options:
        bump: false
        add: false
        commit: false
        push: false

  #
  # Main tasks
  #
  grunt.registerTask 'default', 'testem'

  grunt.registerTask 'test', ->
    grunt.fatal "Specify module to run manual tests for" unless @args[0]

    grunt.task.run "testem:generate:#{@args[0]}"
    grunt.task.run "testem:run:#{@args[0]}"

  grunt.registerTask 'publish', ['testem:ci', 'publish:ensureCommits', 'doc', 'release', 'publish:gem']
