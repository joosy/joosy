require 'sugar'

Mincer = require 'mincer'
semver = require 'semver'

module.exports = (grunt) ->
  #
  # Common settings
  #
  locations =

    source:
      root:  'joosy.coffee'
      path:  'source'
      build: 'build/joosy.js'

      extensions: (name) ->
        root:  "joosy/extensions/#{name || '*'}"
        build: "build/joosy/extensions/#{name || '**/*'}.js"

    specs: [
      'bower_components/sinonjs/sinon.js',
      'bower_components/sugar/release/sugar-full.min.js',
      'spec/helpers/*.coffee'
    ]

  testem =
    parallel: 8
    launch_in_dev: ['PhantomJS'],
    launch_in_ci: ['PhantomJS', 'Chrome', 'Firefox', 'Safari', 'IE7', 'IE8', 'IE9']

  #
  # Grunt extensions
  #
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
        src: locations.specs
          .include('bower_components/jquery/jquery.js')
          .include(locations.source.build)
          .include('spec/joosy/core/**/*_spec.coffee')
        options: testem
      zepto:
        src: locations.specs
          .include('bower_components/zepto/zepto.js')
          .include(locations.source.build)
          .include('spec/joosy/core/**/*_spec.coffee')
        options: testem
      'environments-global':
        src: locations.specs
          .include('bower_components/jquery/jquery.js')
          .include(locations.source.build)
          .include('spec/joosy/environments/global_spec.coffee')
        options: testem
      'environments-amd':
        src: locations.specs
          .include('bower_components/jquery/jquery.js')
          .include('bower_components/requirejs/require.js')
          .include(locations.source.build)
          .include('spec/joosy/environments/amd_spec.coffee')
        options: testem
      extensions:
        src: locations.specs
          .include('bower_components/jquery/jquery.js')
          .include(locations.source.build)
          .include('bower_components/jquery-form/jquery.form.js')
          .include(locations.source.extensions().build)
          .include('spec/joosy/extensions/**/*_spec.coffee')
        options: testem

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
    grunt.task.run if @args[0] then "testem:run:#{@args[0]}" else 'testem'

  grunt.registerTask 'publish', ['testem', 'publish:ensureCommits', 'doc', 'release', 'publish:gem']


  #
  # Building
  #
  grunt.registerMultiTask 'mince', ->
    Mincer.CoffeeEngine.configure bare: false
    environment = new Mincer.Environment
    environment.appendPath x for x in @data.include
    grunt.file.write @data.dest, environment.findAsset(@data.src).toString()

  grunt.registerTask 'bowerize', ->
    bower = require './bower.json'
    meta  = require './package.json'

    bower.version = meta.version
    grunt.file.write 'bower.json', JSON.stringify(bower, null, 2)

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

  #
  # Documentation
  #
  grunt.registerTask 'doc', ['doc:prepare', 'doc:generate']

  grunt.registerTask 'doc:generate', ->
    complete = @async()
    version = JSON.parse(grunt.file.read 'package.json').version.split('-')
    version = version[0]+'-'+version[1]?.split('.')[0]
    destination = "doc/#{version}"
    args = ['source', '--output-dir', destination]

    git = (args, callback) ->
      grunt.util.spawn {cmd: "git", args: args, opts: {stdio: [0,1,2], cwd: 'doc'}}, callback

    date = (version) ->
      return undefined unless version
      Date.create(grunt.file.read "doc/#{version}/DATE").format "{d} {Month} {yyyy}"

    git ['pull'], (error, result) ->
      grunt.fatal "Error pulling from git" if error

      grunt.file.delete destination if grunt.file.exists destination
      grunt.util.spawn {cmd: "codo", args: args, opts: {stdio: [0,1,2]}}, (error, result) ->
        grunt.fatal "Error generating docs" if error
        grunt.file.write "#{destination}/DATE", (new Date).toISOString()

        versions = []
        for version in grunt.file.expand({cwd: 'doc'}, '*')
          versions.push version if semver.valid(version)

        versions = versions.sort(semver.rcompare)
        edge     = versions.find (x) -> x.has('-')
        stable   = versions.find (x) -> !x.has('-')
        versions = versions.remove edge, stable

        versions = {
          edge:
            version: edge
            date: date(edge)
          stable:
            version: stable
            date: date(stable)
          versions: versions.map (x) -> { version: x, date: date(x) }
        }
        grunt.file.write 'doc/versions.js', "window.versions = #{JSON.stringify(versions)}"

        git ['add', '-A'], (error, result) ->
          grunt.fatal "Error adding files" if error

          git ['commit', '-m', "Updated at #{(new Date).toISOString()}"], (error, result) ->
            grunt.fatal "Error commiting" if error

            git ['push', 'origin', 'gh-pages'], (error, result) ->
              grunt.fatal "Error pushing" if error
              complete()

  grunt.registerTask 'doc:prepare', ->
    if grunt.file.exists 'doc'
      unless grunt.file.exists 'doc/.git'
        grunt.fatal "Documentation directory exists. Please remove it"
      else
        return

    complete = @async()

    base = process.cwd()
    git = (args, callback) ->
      grunt.util.spawn {cmd: "git", args: args, opts: {stdio: [0,1,2]}}, callback

    git ["clone", "git@github.com:joosy/joosy.git", "doc"], (error, result) ->
      grunt.fatal "Erorr cloning repo" if error
      process.chdir 'doc'

      git ["checkout", "gh-pages"], (error, result) ->
        grunt.fatal "Erorr checking branch out" if error

        process.chdir base
        complete()