describe "target", ->
	target = undefined
	beforeEach ->
		target = require "./target"
	describe "imports", ->
		it "fs", ->
			expect(target.fs).toBe require "fs"
		it "mkpath", ->
			expect(target.mkpath).toBe require "mkpath"
		it "toolchain", ->
			expect(target.toolchain).toBe require "sunruse-influx-toolchain"
		it "path", ->
			expect(target.path).toBe require "path"
	describe "on calling", ->
		originalFs = originalMkpath = originalToolchain = originalPath = undefined
		beforeEach ->
			originalFs = target.fs
			originalMkpath = target.mkpath
			originalToolchain = target.toolchain
			originalPath = target.path
			target.mkpath = undefined
			target.path = {}
			target.fs = {}
			target.toolchain = {} 
		afterEach ->
			target.fs = originalFs
			target.mkpath = originalMkpath
			target.toolchain = originalToolchain
			target.path = originalPath
			
		grunt = outputs = platformInstance = targetInstance = notifyWritingFile = notifyFileSucceeded = notifyFileFailed = undefined 
		beforeEach ->
			grunt = 
				log: 
					writeln: jasmine.createSpy "writeln"
				fail:
					warn: jasmine.createSpy "warn"
				
			platformInstance = undefined
			
			outputs = 
				"output one name":
					name: "output one function name"
					input: "output one input"
					targetOptions:
						"another target name": "wrong options"
				"output two name":
					name: "output two function name"
					input: "output two input"
				"output three name":
					name: "output three function name"
					input: "output three input"
					targetOptions: 
						"target name": "target specific options"
						"another target name": "wrong options"
			targetInstance = 
				prefix: "filename prefix"
				suffix: "filename suffix" 
				platform: () ->
					expect(platformInstance).toBeUndefined()
					platformInstance =
						primitives:
							"test primitive a":
								assertionPass: "platform b primitive a assertion pass"
							"test primitive b":
								assertionPass: "platform b primitive b assertion pass"
							"test primitive c":
								assertionPass: "platform b primitive c assertion pass"
						compile: (_platform, input, output, options) ->
							expect(_platform).toBe platformInstance
							switch input
								when "output one input"
									expect(output).toEqual "output one output"
									expect(options).toBeUndefined()
									"output one native code"
								when "output two input"
									expect(output).toEqual "output two output"
									expect(options).toBeUndefined()
									"output two native code"
								when "output three input"
									expect(output).toEqual "output three output"
									expect(options).toEqual "target specific options"
									"output three native code"
								else expect(false).toBeTruthy()
			notifyWritingFile = jasmine.createSpy "notifyWritingFile"
			notifyFileSucceeded = jasmine.createSpy "notifyFileSucceeded"
			notifyFileFailed = jasmine.createSpy "notifyFileFailed"
		run = ->
			target grunt, outputs, "target name", targetInstance, "tokenized functions", notifyWritingFile, notifyFileSucceeded, notifyFileFailed
		shared = ->
			it "logs that the target is being built", ->
				run()
				expect(grunt.log.writeln).toHaveBeenCalledWith "Building for target \"target name\"..."
		afterAssertionsPass = (after) ->
			beforeEach ->
				target.mkpath = jasmine.createSpy "mkpath"
				target.fs.writeFile = jasmine.createSpy "writeFile"
				target.path.dirname = (input) ->
					switch input
						when "filename prefixoutput one namefilename suffix"
							"dirname one"
						when "filename prefixoutput two namefilename suffix"
							"dirname two"
						when "filename prefixoutput three namefilename suffix"
							"dirname three"
						else
							expect(false).toBeTruthy()
			describe "when all outputs are found successfully", ->
				beforeEach ->
					target.toolchain.findFunction = (_platform, input, functionName, log, logPrefix, cache) ->
						expect(_platform).toBe platformInstance
						expect(_platform.functions).toEqual "tokenized functions"
						expect(log).toBeNull()
						expect(logPrefix).toBeNull()
						expect(cache).toEqual {}
						
						# Ensures we aren't being given the same anonymous object.
						cache.x = 3
						
						switch functionName
							when "output one function name"
								expect(input).toEqual "output one input"
								return "output one output"
							when "output two function name"
								expect(input).toEqual "output two input"
								return "output two output"
							when "output three function name"
								expect(input).toEqual "output three input"
								return "output three output"
							else expect(false).toBeTruthy
				after()
				shared()
				it "logs that functions are being compiled", ->
					run()
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output one name\"... (function \"output one function name\" to filename \"filename prefixoutput one namefilename suffix\")"
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output two name\"... (function \"output two function name\" to filename \"filename prefixoutput two namefilename suffix\")"
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output three name\"... (function \"output three function name\" to filename \"filename prefixoutput three namefilename suffix\")"
				it "does not log an error", ->
					run()
					expect(grunt.fail.warn).not.toHaveBeenCalled()
				it "informs the task that the files are being written", ->
					run()
					expect(notifyWritingFile.calls.count()).toEqual 3
					expect(notifyFileSucceeded).not.toHaveBeenCalled()
					expect(notifyFileFailed).not.toHaveBeenCalled()
				it "creates the paths needed to write the output files", ->
					run()
					expect(target.mkpath.calls.allArgs()).toHaveSameItems [
						["dirname one", jasmine.any Function]
						["dirname two", jasmine.any Function]
						["dirname three", jasmine.any Function]
					]
				it "does not begin writing any files yet", ->
					run()
					expect(target.fs.writeFile).not.toHaveBeenCalled()
				describe "when all but one paths are created successfully", ->
					beforeEach ->
						run()
						(target.mkpath.calls.argsFor 0)[1] null
						(target.mkpath.calls.argsFor 2)[1] null
					it "does not log an error", ->
						expect(grunt.fail.warn).not.toHaveBeenCalled()
					it "does not inform the task of any further progress", ->
						expect(notifyWritingFile.calls.count()).toEqual 3
						expect(notifyFileSucceeded).not.toHaveBeenCalled()
						expect(notifyFileFailed).not.toHaveBeenCalled()
					it "begins writing the files for which paths are ready", ->
						expect(target.fs.writeFile.calls.allArgs()).toHaveSameItems [
							["filename prefixoutput one namefilename suffix", "output one native code", jasmine.any Function]
							["filename prefixoutput three namefilename suffix", "output three native code", jasmine.any Function]
						]
					describe "when files are written successfully", ->
						beforeEach ->
							(target.fs.writeFile.calls.argsFor 0)[2] null
							(target.fs.writeFile.calls.argsFor 1)[2] null
						it "does not log an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "informs the task of the progress", ->
							expect(notifyWritingFile.calls.count()).toEqual 3
							expect(notifyFileSucceeded.calls.count()).toEqual 2
							expect(notifyFileFailed).not.toHaveBeenCalled()
						it "does not create further paths or files", ->
							expect(target.mkpath.calls.count()).toEqual 3
							expect(target.fs.writeFile.calls.count()).toEqual 2
						describe "when the last path is created successfully", ->
							beforeEach ->
								(target.mkpath.calls.argsFor 1)[1] null
							it "does not inform the task of any further progress", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 2
								expect(notifyFileFailed).not.toHaveBeenCalled()
							it "does not log an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "writes the last file", ->
								expect(target.fs.writeFile.calls.allArgs()).toHaveSameItems [
									["filename prefixoutput one namefilename suffix", "output one native code", jasmine.any Function]
									["filename prefixoutput three namefilename suffix", "output three native code", jasmine.any Function]
									["filename prefixoutput two namefilename suffix", "output two native code", jasmine.any Function]
								]
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 3
							describe "when the last file succeeds", ->
								beforeEach ->
									(target.fs.writeFile.calls.argsFor 0)[2] null
								it "informs the task", ->
									expect(notifyWritingFile.calls.count()).toEqual 3
									expect(notifyFileSucceeded.calls.count()).toEqual 3
									expect(notifyFileFailed).not.toHaveBeenCalled()
								it "does not log an error", ->
									expect(grunt.fail.warn).not.toHaveBeenCalled()
								it "does not create further paths or files", ->
									expect(target.mkpath.calls.count()).toEqual 3
									expect(target.fs.writeFile.calls.count()).toEqual 3
							describe "when the last file fails", ->
								beforeEach ->
									(target.fs.writeFile.calls.argsFor 0)[2] "file two write error"
								it "informs the task of the failure", ->
									expect(notifyWritingFile.calls.count()).toEqual 3
									expect(notifyFileSucceeded.calls.count()).toEqual 2
									expect(notifyFileFailed.calls.count()).toEqual 1
								it "logs an error", ->
									expect(grunt.fail.warn).toHaveBeenCalledWith "file two write error"
								it "does not create further paths or files", ->
									expect(target.mkpath.calls.count()).toEqual 3
									expect(target.fs.writeFile.calls.count()).toEqual 3
						describe "when the last path is created unsuccessfully", ->
							beforeEach ->
								(target.mkpath.calls.argsFor 1)[1] "file two path error"
							it "logs an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "file two path error"
							it "informs the task of the failure", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 2
								expect(notifyFileFailed.calls.count()).toEqual 1
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
					describe "when files are written unsuccessfully", ->
						beforeEach ->
							(target.fs.writeFile.calls.argsFor 0)[2] "file one write error"
							(target.fs.writeFile.calls.argsFor 1)[2] null
						it "logs the error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "file one write error"
						it "informs the task of the progress", ->
							expect(notifyWritingFile.calls.count()).toEqual 3
							expect(notifyFileSucceeded.calls.count()).toEqual 1
							expect(notifyFileFailed.calls.count()).toEqual 1
						it "does not create further paths or files", ->
							expect(target.mkpath.calls.count()).toEqual 3
							expect(target.fs.writeFile.calls.count()).toEqual 2
						describe "when the last path is created successfully", ->
							beforeEach ->
								(target.mkpath.calls.argsFor 1)[1] null
							it "does not inform the task of any further progress", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 1
								expect(notifyFileFailed.calls.count()).toEqual 1
							it "writes the last file", ->
								expect(target.fs.writeFile.calls.allArgs()).toHaveSameItems [
									["filename prefixoutput one namefilename suffix", "output one native code", jasmine.any Function]
									["filename prefixoutput three namefilename suffix", "output three native code", jasmine.any Function]
									["filename prefixoutput two namefilename suffix", "output two native code", jasmine.any Function]
								]
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 3
							describe "when the last file succeeds", ->
								beforeEach ->
									(target.fs.writeFile.calls.argsFor 0)[2] null
								it "informs the task", ->
									expect(notifyWritingFile.calls.count()).toEqual 3
									expect(notifyFileSucceeded.calls.count()).toEqual 2
									expect(notifyFileFailed.calls.count()).toEqual 1
								it "does not create further paths or files", ->
									expect(target.mkpath.calls.count()).toEqual 3
									expect(target.fs.writeFile.calls.count()).toEqual 3
							describe "when the last file fails", ->
								beforeEach ->
									(target.fs.writeFile.calls.argsFor 0)[2] "file two write error"
								it "informs the task of the failure", ->
									expect(notifyWritingFile.calls.count()).toEqual 3
									expect(notifyFileSucceeded.calls.count()).toEqual 1
									expect(notifyFileFailed.calls.count()).toEqual 2
								it "logs an error", ->
									expect(grunt.fail.warn).toHaveBeenCalledWith "file two write error"
								it "does not create further paths or files", ->
									expect(target.mkpath.calls.count()).toEqual 3
									expect(target.fs.writeFile.calls.count()).toEqual 3
						describe "when the last path is created unsuccessfully", ->
							beforeEach ->
								(target.mkpath.calls.argsFor 1)[1] "file two path error"
							it "logs an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "file two path error"
							it "informs the task of the failure", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 1
								expect(notifyFileFailed.calls.count()).toEqual 2
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
						
				describe "when a path fails to create", ->
					beforeEach ->
						run()
						(target.mkpath.calls.argsFor 0)[1] null
						(target.mkpath.calls.argsFor 1)[1] null
						(target.mkpath.calls.argsFor 2)[1] "file three path error"
					it "logs an error", ->
						expect(grunt.fail.warn).toHaveBeenCalledWith "file three path error"
					it "informs the task of the failure", ->
						expect(notifyWritingFile.calls.count()).toEqual 3
						expect(notifyFileSucceeded.calls.count()).toEqual 0
						expect(notifyFileFailed.calls.count()).toEqual 1
					it "writes files for the successful", ->
						expect(target.fs.writeFile.calls.allArgs()).toHaveSameItems [
							["filename prefixoutput one namefilename suffix", "output one native code", jasmine.any Function]
							["filename prefixoutput two namefilename suffix", "output two native code", jasmine.any Function]
						]
					it "does not create further paths or files", ->
						expect(target.mkpath.calls.count()).toEqual 3
						expect(target.fs.writeFile.calls.count()).toEqual 2
					describe "when a file fails to write", ->
						beforeEach ->
							(target.fs.writeFile.calls.argsFor 0)[2] "file one write error"
						it "informs the task of the failure", ->
							expect(notifyWritingFile.calls.count()).toEqual 3
							expect(notifyFileSucceeded.calls.count()).toEqual 0
							expect(notifyFileFailed.calls.count()).toEqual 2
						it "logs an error", ->
						describe "when the other file succeeds", ->
							beforeEach ->
								(target.fs.writeFile.calls.argsFor 1)[2] null
							it "informs the task", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 1
								expect(notifyFileFailed.calls.count()).toEqual 2
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
						describe "when the other file fails", ->
							beforeEach ->
								(target.fs.writeFile.calls.argsFor 1)[2] "file two write error"
							it "informs the task of the failure", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 0
								expect(notifyFileFailed.calls.count()).toEqual 3
							it "logs an error", ->
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
					describe "when a file writes successfully", ->
						beforeEach ->
							(target.fs.writeFile.calls.argsFor 0)[2] null
						it "informs the task", ->
							expect(notifyWritingFile.calls.count()).toEqual 3
							expect(notifyFileSucceeded.calls.count()).toEqual 1
							expect(notifyFileFailed.calls.count()).toEqual 1
						describe "when the other file succeeds", ->
							beforeEach ->
								(target.fs.writeFile.calls.argsFor 1)[2] null
							it "informs the task", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 2
								expect(notifyFileFailed.calls.count()).toEqual 1
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
						describe "when the other file fails", ->
							beforeEach ->
								(target.fs.writeFile.calls.argsFor 1)[2] "file two write error"
							it "informs the task of the failure", ->
								expect(notifyWritingFile.calls.count()).toEqual 3
								expect(notifyFileSucceeded.calls.count()).toEqual 1
								expect(notifyFileFailed.calls.count()).toEqual 2
							it "logs an error", ->
							it "does not create further paths or files", ->
								expect(target.mkpath.calls.count()).toEqual 3
								expect(target.fs.writeFile.calls.count()).toEqual 2
					
			describe "when outputs cannot be found", ->
				beforeEach ->
					target.toolchain.findFunction = (_platform, input, functionName, log, logPrefix, cache) ->
						expect(_platform).toBe platformInstance
						expect(_platform.functions).toEqual "tokenized functions"
						expect(log).toBeNull()
						expect(logPrefix).toBeNull()
						expect(cache).toEqual {}
						
						# Ensures we aren't being given the same anonymous object.
						cache.x = 3
						
						switch functionName
							when "output one function name"
								expect(input).toEqual "output one input"
								return "output one output"
							when "output two function name"
								expect(input).toEqual "output two input"
								return null
							when "output three function name"
								expect(input).toEqual "output three input"
								return "output three output"
							else expect(false).toBeTruthy
				after()
				shared()
				it "logs that functions are being compiled", ->
					run()
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output one name\"... (function \"output one function name\" to filename \"filename prefixoutput one namefilename suffix\")"
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output two name\"... (function \"output two function name\" to filename \"filename prefixoutput two namefilename suffix\")"
					expect(grunt.log.writeln).toHaveBeenCalledWith "Compiling output \"output three name\"... (function \"output three function name\" to filename \"filename prefixoutput three namefilename suffix\")"
				it "logs an error", ->
					run()
					expect(grunt.fail.warn).toHaveBeenCalledWith "Failed to compile output \"output two name\" for target \"target name\".  (function \"output two function name\")"
				it "informs the task that the successful files are being written", ->
					run()
					expect(notifyWritingFile.calls.count()).toEqual 2
					expect(notifyFileSucceeded).not.toHaveBeenCalled()
					expect(notifyFileFailed).not.toHaveBeenCalled()
				it "creates the paths needed to write the output files", ->
					run()
					expect(target.mkpath.calls.allArgs()).toHaveSameItems [
						["dirname one", jasmine.any Function]
						["dirname three", jasmine.any Function]
					]
				
		assertionsEnabled = ->
			describe "when assertions pass", ->
				beforeEach ->
					target.toolchain.runAssertions = (_platform) ->
						expect(_platform).toBe platformInstance
						expect(_platform.functions).toEqual "tokenized functions"
						return [
								assertion:
									line:
										filename: "Test File A"
										line: 18
								resultType: "successful"
							,
								assertion:
									line:
										filename: "Test File A"
										line: 24
								resultType: "successful"
							,
								assertion:
									line:
										filename: "Test File B"
										line: 7
								resultType: "successful"
						]
				afterAssertionsPass ->
					it "logs that assertions are being ran", ->
						run()
						expect(grunt.log.writeln).toHaveBeenCalledWith "Running assertions..."
						expect(grunt.log.writeln).not.toHaveBeenCalledWith "Skipped running assertions."
			describe "when assertions fail", ->
				beforeEach ->
					target.toolchain.runAssertions = (_platform) ->
						expect(_platform).toBe platformInstance
						expect(_platform.functions).toEqual "tokenized functions"
						return [
								assertion:
									line:
										filename: "Test File A"
										line: 18
								resultType: "successful"
							,
								assertion:
									line:
										filename: "Test File A"
										line: 24
								resultType: "failedToCompile"
							,
								assertion:
									line:
										filename: "Test File B"
										line: 7
								resultType: "didNotReturnPrimitiveConstant"
								output:
									parameter:
										type: "a type"
							,
								assertion:
									line:
										filename: "Test File B"
										line: 9
								resultType: "primitiveTypeNotAssertable"
								output:
									primitive:
										type: "test primitive a"
										value: 123
							,
								assertion:
									line:
										filename: "Test File B"
										line: 11
								resultType: "primitiveValueIncorrect"								
								output:
									primitive:
										type: "test primitive b"
										value: [4, 8, 5]
						]
				shared()
				it "does not inform the task of any new files", ->
					expect(notifyWritingFile).not.toHaveBeenCalled()
					expect(notifyFileFailed).not.toHaveBeenCalled()
					expect(notifyFileSucceeded).not.toHaveBeenCalled()
				it "logs that assertions are being ran", ->
					run()
					expect(grunt.log.writeln).toHaveBeenCalledWith "Running assertions..."
					expect(grunt.log.writeln).not.toHaveBeenCalledWith "Skipped running assertions."
				it "logs the error", ->
					run()
					expect(grunt.fail.warn).toHaveBeenCalledWith 	"""
One or more assertion(s) failed:
Test File A
	Line 24 - Failed to compile
Test File B
	Line 7 - Did not return a primitive constant
	Line 9 - Returned non-assertable primitive type \"test primitive a\": 123
	Line 11 - Returned unexpected primitive value of type \"test primitive b\": [4,8,5] whereas \"platform b primitive b assertion pass\" was expected
																	"""
		describe "when assertions default to enabled", ->
			assertionsEnabled()
		describe "when assertions are enabled", ->
			beforeEach ->
				targetInstance.runAssertions = true
			assertionsEnabled()
		describe "when assertions are disabled", ->
			beforeEach ->
				targetInstance.runAssertions = false
			afterAssertionsPass ->
				it "logs that assertions are not being ran", ->
					run()
					expect(grunt.log.writeln).not.toHaveBeenCalledWith "Running assertions..."
					expect(grunt.log.writeln).toHaveBeenCalledWith "Skipped running assertions."