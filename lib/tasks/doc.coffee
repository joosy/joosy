semver = require 'semver'

module.exports = (grunt) ->

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