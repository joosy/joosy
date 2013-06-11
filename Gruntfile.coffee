module.exports = (grunt) ->

  Sugar  = require 'sugar'
  Mincer = require 'mincer'
  FS     = require 'fs'

  #
  # Locations
  #
  locations =
    source:
      root: 'joosy/joosy.coffee'
      path: 'src'
      build: 'lib/joosy.js'
    specs:
      units: 'spec/**/*_spec.*'
      helpers: 'spec/helpers/**/*.*'
      build: '.grunt'

  #
  # Grunt extensions
  #
  grunt.loadNpmTasks 'grunt-mincer'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-release'

  grunt.initConfig
    release:
      options:
        bump: false
        add: false
        commit: false

    connect:
      specs:
        options:
          port: 8888

    watch:
      source:
        files: [locations.source.path + '/**/*']
        tasks: ['mince', 'jasmine']
      specs:
        options:
          nospawn: true
        files: [locations.specs.units, locations.specs.helpers]
        tasks: ['coffee', 'jasmine']

    coffee:
      specs:
        expand: true
        src: [locations.specs.units, locations.specs.helpers]
        dest: locations.specs.build
        ext: '.js'

    mince:
      main:
        include: [locations.source.path]
        src: locations.source.root
        dest: locations.source.build

    coffeelint:
      source:
        files:
          src: [locations.source.path + '/joosy/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    jasmine:
      joosy:
        src: locations.source.build
        options:
          host: 'http://localhost:8888/'
          keepRunner: true
          outfile: 'index.html'
          vendor: [
            'components/sinonjs/sinon.js',
            'components/jquery/jquery.js',
            'components/jquery-form/jquery.form.js',
            'components/sugar/release/sugar-full.min.js'
          ],
          specs: locations.specs.build + '/' + locations.specs.units
          helpers: locations.specs.build + '/' + locations.specs.helpers

  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['coffee', 'specs', 'src'], filepath

  #
  # Tasks
  #
  grunt.registerTask 'default', ['connect', 'build', 'watch']

  grunt.registerTask 'build', ['mince', 'coffee', 'jasmine:joosy:build']

  grunt.registerTask 'test', ['connect', 'mince', 'coffee', 'jasmine']

  grunt.registerTask 'publish', ['test', 'release']