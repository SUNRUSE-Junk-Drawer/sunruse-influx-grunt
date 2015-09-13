module.exports = (grunt) ->
    grunt.loadNpmTasks pkg for pkg in [
            "grunt-contrib-watch"
            "grunt-contrib-coffee"
            "grunt-contrib-clean"
            "grunt-contrib-copy"
            "grunt-jasmine-nodejs"
        ]
    
    grunt.registerTask "build", ["clean:build", "coffee:build", "copy:build"]
    grunt.registerTask "test", ["jasmine_nodejs:unit"]
    grunt.registerTask "deploy", ["clean:deploy", "copy:deploy"]
        
    grunt.initConfig
        clean:
            build: "build"
            deploy: "deploy"
        jasmine_nodejs:
            options:
                specNameSuffix: ".js"
                reporters:
                    console:
                        verbosity: 0
            unit: 
                specs: ["build/**/*-unit.js"]
        copy:
            build:
                files: [
                    expand: true
                    cwd: "src"
                    src: ["**/*.sh"]
                    dest: "build"
                ]
            deploy:
                files: [
                    expand: true
                    cwd: "build"
                    src: ["**/*.js", "!**/*-unit.js", "**/*.sh"]
                    dest: "deploy"
                ]
        coffee:
            build:
                files: [
                        expand: true
                        src: ["**/*.coffee"]
                        dest: "build"
                        ext: ".js"
                        cwd: "src"
                ]
        watch:
            options:
                atBegin: true
            files: ["src/**/*"]
            tasks: ["build", "test", "deploy"]