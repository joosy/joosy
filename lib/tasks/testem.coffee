Path = require 'path'

module.exports = (grunt) ->

  grunt.registerTask 'testem:generate', ->
    unless @args[0]
      grunt.config.requires 'testem'
      return Object.each grunt.config.get('testem'), (key, value) ->
        grunt.task.run "testem:generate:#{key}"

    grunt.config.requires "testem.#{@args[0]}"

    coffee = []
    source = grunt.file.expand grunt.config.get("testem.#{@args[0]}.src")

    serve  = source.map (name) ->
      if Path.extname(name) == '.coffee'
        destination = ".grunt/#{Path.dirname(name)}/#{Path.basename(name, '.coffee')}.js"
        coffee.push "coffee -o #{Path.dirname(destination)} -c #{name}"
        destination
      else
        name

    result =
      framework: 'jasmine',
      src_files: source
      serve_files: serve
      before_tests: 'grunt mince;'+coffee.join(';')
      launch_in_dev: ['PhantomJS'],
      launch_in_ci: ['PhantomJS', 'Chrome', 'Firefox', 'Safari', 'IE7', 'IE8', 'IE9']

    grunt.file.write "spec/#{@args[0]}.json", JSON.stringify(result, null, 2)

  grunt.registerTask 'testem:ci', ->
    unless @args[0]
      grunt.config.requires 'testem'
      return Object.each grunt.config.get('testem'), (key, value) ->
        grunt.task.run "testem:ci:#{key}"

    complete = @async()

    grunt.config.requires "testem.#{@args[0]}"

    command = "node_modules/.bin/testem"
    options = ['ci', '-f', "spec/#{@args[0]}.json", '-R', 'dot', '-P', '8']

    grunt.util.spawn {cmd: command, args: options, opts: {stdio: [0,1,2]}}, (error, result) ->
      grunt.fatal "Tests did not succed" if error
      complete()

  grunt.registerTask 'testem:run', ->
    complete = @async()

    command = "node_modules/.bin/testem"
    options = ['-f', "spec/#{@args[0]}.json"]

    grunt.util.spawn {cmd: command, args: options, opts: {stdio: [0,1,2]}}, (error, result) ->
      complete()