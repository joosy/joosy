require 'sugar'

semver = require 'semver'

module.exports = (grunt) ->
  #
  # Common settings
  #
  testemOptions = (vendor, specs) ->
    return {
      src: Array.create([
          'bower_components/sinonjs/sinon.js',
          'bower_components/sugar/release/sugar-full.min.js',
          'spec/helpers/*.coffee'
        ], vendor, 'joosy.coffee', specs)
      assets:
        setup: ->
          grunt.grill.assetter('development').environment
      options:
        parallel: 8
        launch_in_dev: ['PhantomJS'],
        launch_in_ci: ['PhantomJS', 'Chrome', 'Firefox', 'Safari', 'IE7', 'IE8', 'IE9']
    }

  #
  # Grunt extensions
  #
  grunt.loadNpmTasks 'grill'
  grunt.loadNpmTasks 'grunt-contrib-testem'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-gh-pages'

  #
  # Config
  #
  grunt.initConfig
    grill:
      assets:
        destination: 'build'
        paths: 'source'
        root: ['joosy.coffee', 'joosy/extensions/*']

    coffeelint:
      source:
        files:
          src: 'source/joosy/**/*.coffee'
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
      core: testemOptions(
        'bower_components/jquery/jquery.js', 
        'spec/joosy/core/**/*_spec.coffee'
      )
      zepto: testemOptions(
        'bower_components/zepto/zepto.js', 
        'spec/joosy/core/**/*_spec.coffee'
      )
      'environments-global': testemOptions(
        'bower_components/jquery/jquery.js', 
        'spec/joosy/environments/global_spec.coffee'
      )
      'environments-amd': testemOptions(
        [
          'bower_components/jquery/jquery.js', 
          'bower_components/requirejs/require.js'
        ],
        'spec/joosy/environments/amd_spec.coffee'
      )
      extensions: testemOptions(
        [
          'bower_components/jquery/jquery.js', 
          'bower_components/jquery-form/jquery.form.js'
        ],
        [
          'joosy/extensions/*',
          'spec/joosy/extensions/**/*_spec.coffee'
        ]
      )

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

  grunt.registerTask 'build', 'grill:compile'

  grunt.registerTask 'test', ->
    grunt.task.run 'coffeelint'
    grunt.task.run if @args[0] then "testem:run:#{@args[0]}" else 'testem'

  grunt.registerTask 'publish', [
    'test',
    'build',
    'ensureCommits',
    'gh-pages',
    'release',
    'gemify'
  ]

  #
  # Building
  #
  grunt.registerTask 'bowerize', ->
    bower = require './bower.json'
    meta  = require './package.json'

    bower.version = meta.version
    grunt.file.write 'bower.json', JSON.stringify(bower, null, 2)

  #
  # Publishing
  #
  grunt.registerTask 'ensureCommits', ->
    complete = @async()

    grunt.util.spawn {cmd: "git", args: ["status", "--porcelain" ]}, (error, result) ->
      if !!error || result.stdout.length > 0
        console.log ""
        console.log "Uncommited changes found. Please commit prior to release or use `--force`.".bold
        console.log ""
        complete false
      else
        complete true

  grunt.registerTask 'gemify', ->
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