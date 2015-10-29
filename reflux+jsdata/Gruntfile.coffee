#
# Copyright (C) 2015 by Looker Data Services, Inc.
# All rights reserved.
#

module.exports = (grunt)->

    grunt.loadTasks tasks for tasks in grunt.file.expand './node_modules/grunt-*/tasks'

    grunt.config.init

        rsync:
            images:
                options:
                    src: './src/images/'
                    dest: './dist/static/images/'
                    recursive: true
            server_source:
                options:
                    src: './src/coffee/*'
                    dest: './dist/'
                    exclude: ['client/']
                    recursive: true

        clean:
            dist: ['./dist']

        jade:
            pages:
                options:
                    pretty: true
                files: [
                    expand: true
                    cwd:  './src/jade/pages'
                    src:  '**/*.jade'
                    dest: './dist/static'
                    ext:  '.html'
                ]
            templates:
                options:
                    client: true
                    node: true
                    processName: (f)->
                        f = f.replace './src/jade/templates/', ''
                        f = f.replace '.jade', ''
                        f = f.replace /\//g, '_'
                        return f
                files:
                    './src/coffee/client/templates.js': ['./src/jade/templates/**/*.jade']

        mochaTest:
            options:
                bail:     true
                color:    true
                reporter: 'dot'
                require: [
                    'coffee-script/register'
                    './test/test_helper.coffee'
                ]
                verbose: true
            src: ['./test/**/*.test.coffee', './test/**/*.test.js']

        sass:
            all:
                files:
                    './dist/static/main.css': ['./src/scss/main.scss']

        watch:
            client_source:
                files: ['./src/coffee/client/**/*.coffee']
                tasks: ['browserify']
            images:
                files: ['./src/images/**/*']
                tasks: ['rsync:images']
            jade_pages:
                files: ['./src/jade/pages/**/*.jade']
                tasks: ['jade:pages']
            jade_templates:
                files: ['./src/jade/templates/**/*.jade']
                tasks: ['jade:templates', 'browserify']
            sass:
                files: ['./src/**/*.scss']
                tasks: ['sass']
            server_source:
                files: ['./src/coffee/server/**/*.coffee']
                tasks: ['rsync:server_source']
            shared_source:
                files: ['./src/coffee/*.coffee', './src/coffee/model/**/*.coffee']
                tasks: ['rsync:server_source', 'browserify']
            test:
                files: ['./src/**/*.coffee', './test/**/*.coffee']
                tasks: ['test']

    grunt.registerTask 'default', ['test', 'build']

    grunt.registerTask 'browserify', "Bundle source files needed in the browser", ->
        grunt.file.mkdir './dist/static'

        done = this.async()
        options = cmd:'browserify', args:[
            '--extension=.coffee'
            '--external=axios'
            '--transform=coffeeify'
            '--outfile=./dist/static/client.js'
            './src/coffee/client/client.coffee'
        ]
        grunt.util.spawn options, (error)->
            console.log error if error?
            done()

    grunt.registerTask 'build', ['jade', 'rsync', 'sass', 'browserify']

    grunt.registerTask 'start', "Start the music-site server at port 8080", ->
      done = this.async()
      grunt.util.spawn cmd:'./scripts/start', opts:{stdio:'inherit'}, -> done()

    grunt.registerTask 'test', ['mochaTest']
