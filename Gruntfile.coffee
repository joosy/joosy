module.exports = (grunt) ->

  Sugar  = require 'sugar'
  Mincer = require 'mincer'
  FS     = require 'fs'

  #
  # Locations
  #
  locations =
    source:
      root: 'joosy.coffee'
      path: 'src'
      build: 'lib/joosy.js'
      extensions: (name) ->
        root: "joosy/extensions/#{name}"
        build: "lib/extensions/#{name}.js"
    specs:
      units:
        core: 'spec/joosy/core/**/*_spec.*'
        extensions: 'spec/joosy/extensions/**/*_spec.*'
      helpers: 'spec/helpers/**/*.*'
      build: '.grunt'

  specOptions = (category, specs) ->
    host: 'http://localhost:8888/'
    keepRunner: true
    outfile: "#{category}.html"
    vendor: [
      'components/sinonjs/sinon.js',
      'components/jquery/jquery.js',
      'components/jquery-form/jquery.form.js',
      'components/sugar/release/sugar-full.min.js'
    ],
    specs: "#{locations.specs.build}/#{specs}"
    helpers: locations.specs.build + '/' + locations.specs.helpers

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
        push: false

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
        files: [locations.specs.units.core, locations.specs.units.extensions, locations.specs.helpers]
        tasks: ['coffee', 'jasmine']

    coffee:
      specs:
        expand: true
        src: [locations.specs.units.core, locations.specs.units.extensions, locations.specs.helpers]
        dest: locations.specs.build
        ext: '.js'

    mince:
      core:
        include: [locations.source.path]
        src: locations.source.root
        dest: locations.source.build
      preloaders:
        include: [locations.source.path]
        src: locations.source.extensions('preloaders').root
        dest: locations.source.extensions('preloaders').build
      resources:
        include: [locations.source.path]
        src: locations.source.extensions('resources').root
        dest: locations.source.extensions('resources').build
      form:
        include: [locations.source.path]
        src: locations.source.extensions('form').root
        dest: locations.source.extensions('form').build

    coffeelint:
      source:
        files:
          src: [locations.source.path + '/joosy/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    jasmine:
      core:
        options: specOptions('core', locations.specs.units.core)
        src: locations.source.build

      extensions:
        options: specOptions('extensions', locations.specs.units.extensions)
        src: [locations.source.build].include ['preloaders', 'resources', 'form'].map (x) ->
          locations.source.extensions(x).build

  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['coffee', 'specs', 'src'], filepath

  #
  # Tasks
  #
  grunt.registerTask 'default', ['connect', 'build', 'watch']

  grunt.registerTask 'build', ['mince', 'coffee', 'jasmine:core:build', 'jasmine:extensions:build', 'bowerize']

  grunt.registerTask 'test', ['connect', 'mince', 'coffee', 'bowerize', 'jasmine']

  grunt.registerTask 'bowerize', ->
    bower = require './bower.json'
    meta  = require './package.json'

    bower.version = meta.version
    FS.writeFileSync 'bower.json', JSON.stringify(bower, null, 2)

  grunt.registerTask 'publish:ensureCommits', ->
    complete = @async()

    grunt.util.spawn {cmd: "git", args: ["status", "--porcelain" ]}, (error, result) ->
      if !!error || result.stdout.length > 0
        console.log ""
        console.log "Uncommited changes found. Please commit prior to release or use `--force`.".bold
        console.log ""
        complete false
      else
        complete true

  grunt.registerTask 'publish:gem', ->
    meta     = require './package.json'
    complete = @async()

    grunt.util.spawn {cmd: "gem", args: ["build", "joosy.gemspec"]}, (error, result) ->
      return complete false if error

      gem = "joosy-#{meta.version.replace('-', '.')}.gem"
      grunt.log.ok "Built #{gem}"

      grunt.util.spawn {cmd: "gem", args: ["push", gem]}, (error, result) ->
        return complete false if error
        grunt.log.ok "Published #{gem}"
        grunt.file.delete gem
        complete(true)

  grunt.registerTask 'publish', ['test', 'publish:ensureCommits', 'release', 'publish:gem']