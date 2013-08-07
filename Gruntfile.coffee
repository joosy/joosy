module.exports = (grunt) ->

  Sugar  = require 'sugar'
  Mincer = require 'mincer'
  FS     = require 'fs'
  semver = require 'semver'

  #
  # Locations
  #
  locations =
    source:
      root: 'joosy.coffee'
      path: 'source'
      build: 'build/joosy.js'
      extensions: (name) ->
        root: "joosy/extensions/#{name}"
        build: "build/joosy/extensions/#{name}.js"
    specs:
      units:
        environments: 'spec/joosy/environments/*_spec.*'
        core: 'spec/joosy/core/**/*_spec.*'
        extensions: 'spec/joosy/extensions/**/*_spec.*'
      helpers: 'spec/helpers/**/*.*'
      build: '.grunt'

  specOptions = (category, specs, vendor=[]) ->
    host: 'http://localhost:8888/'
    keepRunner: true
    outfile: "spec/#{category}.html"
    vendor: [
      'bower_components/sinonjs/sinon.js',
      'bower_components/sugar/release/sugar-full.min.js'
    ].concat(vendor),
    specs: "#{locations.specs.build}/#{specs}"
    helpers: locations.specs.build + '/' + locations.specs.helpers

  #
  # Grunt extensions
  #
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
        tasks: ['mince']
      specs:
        options:
          nospawn: true
        files: [ locations.specs.helpers ].add(Object.values locations.specs.units)
        tasks: ['coffee']

    coffee:
      specs:
        expand: true
        src: [ locations.specs.helpers ].add(Object.values locations.specs.units)
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
        src: locations.source.extensions('resources-form').root
        dest: locations.source.extensions('resources-form').build

    coffeelint:
      source:
        files:
          src: [locations.source.path + '/joosy/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    jasmine:
      core:
        options: specOptions('core', locations.specs.units.core, [
            'bower_components/jquery/jquery.js'
          ])
        src: locations.source.build

      zepto:
        options: specOptions('zepto', locations.specs.units.core, [
            'bower_components/zepto/zepto.js'
          ])
        src: locations.source.build

      'environments-global':
        options: specOptions('environments-global', ['spec/joosy/environments/global*'], [
            'bower_components/jquery/jquery.js'
          ])
        src: locations.source.build

      'environments-amd':
        options: specOptions('environments-amd', ['spec/joosy/environments/amd*'], [
            'bower_components/jquery/jquery.js',
            'bower_components/requirejs/require.js'
          ])
        src: locations.source.build

      extensions:
        options: specOptions('extensions', locations.specs.units.extensions, [
            'bower_components/jquery/jquery.js',
            'bower_components/jquery-form/jquery.form.js'
          ])
        src: [locations.source.build].include ['preloaders', 'resources', 'resources-form'].map (x) ->
          locations.source.extensions(x).build

  #
  # Preparations
  #
  grunt.registerTask 'prepare', ->
    complete = @async()

    base = process.cwd()
    git = (args, callback) ->
      grunt.util.spawn {cmd: "git", args: args, opts: {stdio: [0,1,2]}}, callback

    if grunt.file.exists 'doc'
      grunt.fatal "Documentation directory exists. Please remove it"

    git ["clone", "git@github.com:joosy/joosy.git", "doc"], (error, result) ->
      grunt.fatal "Erorr cloning repo" if error
      process.chdir 'doc'

      git ["checkout", "gh-pages"], (error, result) ->
        grunt.fatal "Erorr checking branch out" if error

        process.chdir base
        complete()

  #
  # Builders
  #
  grunt.registerMultiTask 'mince', ->
    Mincer.CoffeeEngine.configure bare: false
    environment = new Mincer.Environment
    environment.appendPath x for x in @data.include
    grunt.file.write @data.dest, environment.findAsset(@data.src).toString()

  grunt.registerTask 'default', ['connect', 'build', 'watch']

  grunt.registerTask 'build', ['mince', 'coffee', 'jasmine:core:build', 'jasmine:extensions:build', 'bowerize']

  grunt.registerTask 'test', ['connect', 'mince', 'coffee', 'bowerize', 'jasmine']

  grunt.registerTask 'bowerize', ->
    bower = require './bower.json'
    meta  = require './package.json'

    bower.version = meta.version
    FS.writeFileSync 'bower.json', JSON.stringify(bower, null, 2)

  #
  # Documentation
  #
  grunt.registerTask 'doc', ->
    complete = @async()
    version = require('./package.json').version.split('-')[0]
    destination = "doc/#{version}"
    args = ['source', '--output-dir', destination]

    git = (args, callback) ->
      grunt.util.spawn {cmd: "git", args: args, opts: {stdio: [0,1,2], cwd: 'doc'}}, callback

    git ['pull'], (error, result) ->
      grunt.fatal "Error pulling from git" if error

      grunt.file.delete destination if grunt.file.exists destination
      grunt.util.spawn {cmd: "codo", args: args, opts: {stdio: [0,1,2]}}, (error, result) ->
        grunt.fatal "Error generating docs" if error

        versions = []
        for version in grunt.file.expand({cwd: 'doc'}, '*')
          versions.push version if semver.valid(version)
        console.log versions.sort semver.rcompare

        # git ['add', '-A'], (error, result) ->
        #   grunt.fatal "Error adding files" if error

        #   git ['commit', '-m', "Updated at #{new Date}"], (error, result) ->
        #     grunt.fatal "Error commiting" if error

        #     git ['push', 'origin', 'gh-pages'], (error, result) ->
        #       grunt.fatal "Error pushing" if error
        #       complete()


  #
  # Publishing
  #
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

  grunt.registerTask 'publish', ['test', 'publish:ensureCommits', 'doc', 'release', 'publish:gem']