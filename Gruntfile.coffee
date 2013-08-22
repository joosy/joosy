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
  grunt.loadNpmTasks 'grunt-gh-pages'

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

    'gh-pages':
      docs:
        options:
          add: true
          clone: 'doc'
          command:
            cmd: 'grunt'
            args: ['doc']

    testem:
      core:
        src: Array.create(
          locations.specs,
          'bower_components/jquery/jquery.js',
          locations.source.build,
          'spec/joosy/core/**/*_spec.coffee'
        )
        options: testem
      zepto:
        src: Array.create(
          locations.specs,
          'bower_components/zepto/zepto.js',
          locations.source.build,
          'spec/joosy/core/**/*_spec.coffee'
        )
        options: testem
      'environments-global':
        src: Array.create(
          locations.specs,
          'bower_components/jquery/jquery.js',
          locations.source.build,
          'spec/joosy/environments/global_spec.coffee'
        )
        options: testem
      'environments-amd':
        src: Array.create(
          locations.specs,
          'bower_components/jquery/jquery.js',
          'bower_components/requirejs/require.js',
          locations.source.build,
          'spec/joosy/environments/amd_spec.coffee'
        )
        options: testem
      extensions:
        src: Array.create(
          locations.specs,
          'bower_components/jquery/jquery.js',
          locations.source.build,
          'bower_components/jquery-form/jquery.form.js',
          locations.source.extensions().build,
          'spec/joosy/extensions/**/*_spec.coffee'
        )
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
  grunt.registerTask 'doc', ->
    complete = @async()

    version     = require('./package.json').version.split('-')
    version     = version[0]+'-'+version[1]?.split('.')[0]
    destination = "doc/#{version}"

    date = (version) ->
      return undefined unless version
      Date.create(grunt.file.read "doc/#{version}/DATE").format "{d} {Month} {yyyy}"

    args = ['source', '--output-dir', destination]
    grunt.file.delete destination if grunt.file.exists destination

    grunt.util.spawn {cmd: "codo", args: args, opts: {stdio: [0,1,2]}}, (error, result) ->
      grunt.fatal "Error generating docs" if error
      grunt.file.write "#{destination}/DATE", (new Date).toISOString()

      versions = []
      for version in grunt.file.expand({cwd: 'doc'}, '*')
        versions.push version if semver.valid(version)

      versions = versions.sort(semver.rcompare)
      edge     = versions.filter((x) -> x.has('-')).first()
      stable   = versions.filter((x) -> !x.has('-')).first()
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