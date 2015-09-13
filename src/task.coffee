module.exports = (grunt) ->
	grunt.registerMultiTask "sunruse-influx", "Compiles and tests SUNRUSE.influx source code.", ->
		captured = this
		if not captured.filesSrc.length
			grunt.fail.warn "No source files found.  Please ensure that the src property matches files."
		else
			loaded = {}
			done = this.async()
			grunt.log.writeln "Reading source files..."
			remainingFiles = captured.filesSrc.length
			failures = 0
			for file in captured.filesSrc
				do (file) ->
					module.exports.fs.readFile file, "utf8", (err, data) ->
						if err
							grunt.fail.warn err
							failures++
						else
							loaded[file] = data
						if not --remainingFiles
							if failures
								done false
							else
								grunt.log.writeln "All files read, tokenizing..."
								tokenized = undefined
								try
									tokenized = module.exports.toolchain.tokenizer loaded
								catch error
									grunt.fail.warn error
									done false
									return
									
								waiting = 0
								failures = 0
									
								notifyWritingFile = -> waiting++
								notifyFileSucceeded = ->
									if not --waiting
										if failures
											grunt.fail.warn failures + " file(s) failed to write."
											done false
										else
											grunt.log.ok "All files written successfully."
											done true
								notifyFileFailed = ->
									failures++
									notifyFileSucceeded()
								
								for targetName, targetValue of captured.data.targets
									module.exports.target grunt, captured.data.outputs, targetName, targetValue, tokenized, notifyWritingFile, notifyFileSucceeded, notifyFileFailed
			
								if not waiting
									grunt.fail.warn "No files were created."
									done false
			
module.exports.toolchain = require "sunruse-influx-toolchain"
module.exports.target = require "./target"
module.exports.fs = require "fs"
