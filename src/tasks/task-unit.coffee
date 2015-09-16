require "jasmine-collection-matchers"
describe "task", ->
	task = undefined
	beforeEach ->
		task = require "./task"
	describe "imports", ->
		it "toolchain", ->
			expect(task.toolchain).toBe require "sunruse-influx-toolchain"
		it "target", ->
			expect(task.target).toBe require "./../support/target"
		it "fs", ->
			expect(task.fs).toBe require "fs"
	describe "on calling", ->
		originalToolchain = originalTarget = originalFs = grunt = undefined
		beforeEach ->
			originalToolchain = task.toolchain
			originalTarget = task.target
			originalFs = task.fs
			task.toolchain = task.target = task.fs = undefined
			grunt = 
				registerMultiTask: jasmine.createSpy()
			task grunt
		afterEach ->
			task.toolchain = originalToolchain
			task.target = originalTarget
			task.fs = originalFs
		it "defines a Grunt task", ->
			expect(grunt.registerMultiTask.calls.allArgs()).toEqual [["sunruse-influx", "Compiles and tests SUNRUSE.influx source code.", jasmine.any Function]]
		describe "on running the Grunt task", ->
			run = scope = undefined
			beforeEach ->
				scope = {}
				run = ->
					(grunt.registerMultiTask.calls.argsFor 0)[2].call scope
			describe "without source files", ->
				beforeEach ->
					scope.filesSrc = []
					grunt.fail = 
						warn: jasmine.createSpy "warn"
					run()
				it "raises an error", ->
					expect(grunt.fail.warn).toHaveBeenCalledWith "No source files found.  Please ensure that the src property matches files."
			describe "with source files", ->
				async = callbacks = undefined 
				beforeEach ->
					async = jasmine.createSpy "async"
					async.and.callFake ->
						expect(async.calls.count()).toEqual 1
						
					scope.async = jasmine.createSpy "async factory"
					scope.async.and.callFake ->
						expect(scope.async.calls.count()).toEqual 1
						async
					
					callbacks = []
					
					task.fs = 
						readFile: (filename, encoding, callback) ->
							expect(encoding).toEqual "utf8"
							callbacks.push
								filename: filename
								callback: callback
								
					grunt.log = 
						writeln: jasmine.createSpy "write log"
						
					grunt.fail =
						warn: jasmine.createSpy "write fail warn"
							
					scope.filesSrc = ["filename one", "filename two", "filename three"]					
					run()
				it "attempts to read the files", ->
					expect(callbacks).toHaveSameItems [
								filename: "filename one"
								callback: jasmine.any Function
							,
								filename: "filename two"
								callback: jasmine.any Function
							,
								filename: "filename three"
								callback: jasmine.any Function
						]
				it "starts an asynchronous task", ->
					expect(scope.async.calls.count()).toEqual 1
				it "does not yet mark the asynchronous task as done", ->
					expect(async).not.toHaveBeenCalled()
				it "logs that files are being read", ->
					expect(grunt.log.writeln).toHaveBeenCalledWith "Reading source files..."
				it "does not raise an error", ->
					expect(grunt.fail.warn).not.toHaveBeenCalled()
					
				successTests = (go) ->
					describe "on successful tokenization", ->
						beforeEach ->
							scope.data =
								outputs: "target outputs" 
								targets: 
									"target name one": "target data one"
									"target name two": "target data two"
									"target name three": "target data three"
							task.target = jasmine.createSpy "target"
							task.toolchain = 
								tokenizer: jasmine.createSpy "tokenizer"
							task.toolchain.tokenizer.and.callFake (files) ->
								expect(files).toEqual
									"filename one": "content one"
									"filename two": "content two"
									"filename three": "content three"
								expect(grunt.fail.warn).not.toHaveBeenCalled()
								expect(grunt.log.writeln).toHaveBeenCalledWith "All files read, tokenizing..."
								"tokenized functions"
							grunt.log.ok = jasmine.createSpy "ok"
						describe "when no files are created", ->
							beforeEach ->
								go()
							it "does not write a success message", ->
								expect(grunt.log.ok).not.toHaveBeenCalled()
							it "writes a failure message", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "No files were created."
							it "marks the asynchronous task as done unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
							it "delegates to build each target", ->
								expect(task.target.calls.allArgs()).toHaveSameItems [
									[grunt, "target outputs", "target name one", "target data one", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
									[grunt, "target outputs", "target name two", "target data two", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
									[grunt, "target outputs", "target name three", "target data three", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
								]
								expect(task.target.calls.argsFor(0)[5]).toBe task.target.calls.argsFor(1)[5]
								expect(task.target.calls.argsFor(0)[5]).toBe task.target.calls.argsFor(2)[5]
								expect(task.target.calls.argsFor(0)[6]).toBe task.target.calls.argsFor(1)[6]
								expect(task.target.calls.argsFor(0)[6]).toBe task.target.calls.argsFor(2)[6]
								expect(task.target.calls.argsFor(0)[7]).toBe task.target.calls.argsFor(1)[7]
								expect(task.target.calls.argsFor(0)[7]).toBe task.target.calls.argsFor(2)[7]
						describe "when files are created by targets", ->
							beforeEach ->
								task.target.and.callFake (grunt, outputs, targetName, target, tokenized, notifyWritingFile, notifyFileSucceeded, notifyFileFailed) ->
									switch targetName
										when "target name one"
											notifyWritingFile()
											notifyWritingFile()
										when "target name three"
											notifyWritingFile()
											notifyWritingFile()
											notifyWritingFile()
								go()
							it "does not write a success message", ->
								expect(grunt.log.ok).not.toHaveBeenCalled()
							it "does not write a failure message", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "does not mark the asynchronous task as done", ->
								expect(async).not.toHaveBeenCalled()
							it "delegates to build each target", ->
								expect(task.target.calls.allArgs()).toHaveSameItems [
									[grunt, "target outputs", "target name one", "target data one", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
									[grunt, "target outputs", "target name two", "target data two", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
									[grunt, "target outputs", "target name three", "target data three", "tokenized functions", (jasmine.any Function), (jasmine.any Function), (jasmine.any Function)]
								]
								expect(task.target.calls.argsFor(0)[5]).toBe task.target.calls.argsFor(1)[5]
								expect(task.target.calls.argsFor(0)[5]).toBe task.target.calls.argsFor(2)[5]
								expect(task.target.calls.argsFor(0)[6]).toBe task.target.calls.argsFor(1)[6]
								expect(task.target.calls.argsFor(0)[6]).toBe task.target.calls.argsFor(2)[6]
								expect(task.target.calls.argsFor(0)[7]).toBe task.target.calls.argsFor(1)[7]
								expect(task.target.calls.argsFor(0)[7]).toBe task.target.calls.argsFor(2)[7]
							describe "when all but one file has written successfully", ->
								beforeEach ->
									task.target.calls.argsFor(0)[6]()
									task.target.calls.argsFor(0)[6]()
									task.target.calls.argsFor(0)[6]()
									task.target.calls.argsFor(0)[6]()
								it "does not write a failure message", ->
									expect(grunt.fail.warn).not.toHaveBeenCalled()
								it "does not write a success message", ->
									expect(grunt.log.ok).not.toHaveBeenCalled()
								it "does not mark the asynchronous task as done", ->
									expect(async).not.toHaveBeenCalled()
								describe "when the last file writes successfully", ->
									beforeEach ->
										task.target.calls.argsFor(0)[6]()
									it "does not write a failure message", ->
										expect(grunt.fail.warn).not.toHaveBeenCalled()
									it "writes a success message", ->
										expect(grunt.log.ok).toHaveBeenCalledWith "All files written successfully."
									it "marks the asynchronous task as done successfully", ->
										expect(async).toHaveBeenCalledWith true
								describe "when the last file writes unsuccessfully", ->
									beforeEach ->
										task.target.calls.argsFor(0)[7]()
									it "writes a failure message", ->
										expect(grunt.fail.warn).toHaveBeenCalledWith "1 file(s) failed to write."
									it "does not write a success message", ->
										expect(grunt.log.ok).not.toHaveBeenCalled()
									it "marks the asynchronous task as done unsuccessfully", ->
										expect(async).toHaveBeenCalledWith false
							describe "when a file fails but not all have finished", ->
								beforeEach ->
									task.target.calls.argsFor(0)[6]()
									task.target.calls.argsFor(0)[7]()
									task.target.calls.argsFor(0)[6]()
									task.target.calls.argsFor(0)[6]()
								it "does not write a failure message", ->
									expect(grunt.fail.warn).not.toHaveBeenCalled()
								it "does not write a success message", ->
									expect(grunt.log.ok).not.toHaveBeenCalled()
								it "does not mark the asynchronous task as done", ->
									expect(async).not.toHaveBeenCalled()
								describe "when the last file finishes successfully", ->
									beforeEach ->
										task.target.calls.argsFor(0)[6]()
									it "writes a failure message", ->
										expect(grunt.fail.warn).toHaveBeenCalledWith "1 file(s) failed to write."
									it "does not write a success message", ->
										expect(grunt.log.ok).not.toHaveBeenCalled()
									it "marks the asynchronous task as done unsuccessfully", ->
										expect(async).toHaveBeenCalledWith false
								describe "when the last file finishes unsuccessfully", ->
									beforeEach ->
										task.target.calls.argsFor(0)[7]()
									it "writes a failure message", ->
										expect(grunt.fail.warn).toHaveBeenCalledWith "2 file(s) failed to write."
									it "does not write a success message", ->
										expect(grunt.log.ok).not.toHaveBeenCalled()
									it "marks the asynchronous task as done undefined", ->
										expect(async).toHaveBeenCalledWith false
					describe "on failing to tokenize", ->
						beforeEach ->
							task.toolchain = 
								tokenizer: jasmine.createSpy "tokenizer"
							task.toolchain.tokenizer.and.callFake (files) ->
								expect(files).toEqual
									"filename one": "content one"
									"filename two": "content two"
									"filename three": "content three"
								expect(grunt.fail.warn).not.toHaveBeenCalled()
								expect(grunt.log.writeln).toHaveBeenCalledWith "All files read, tokenizing..."
								throw "tokenization error"
							go()
						it "raises the error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "tokenization error"
						it "marks the asynchronous task as done unsuccessfully", ->
							expect(async).toHaveBeenCalledWith false
				describe "the first file succeeds", ->
					beforeEach ->
						callbacks[0].callback null, "content one"
					it "does not raise an error", ->
						expect(grunt.fail.warn).not.toHaveBeenCalled()
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the second file succeeds", ->
						beforeEach ->
							callbacks[1].callback null, "content two"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							successTests -> callbacks[2].callback null, "content three"
						describe "the third file fails", ->
							beforeEach ->
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file succeeds", ->
						beforeEach ->
							callbacks[2].callback null, "content three"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							successTests -> callbacks[1].callback null, "content two"
						describe "the second file fails", ->
							beforeEach ->
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the second file fails", ->
						beforeEach ->
							callbacks[1].callback "error two", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file fails", ->
							beforeEach ->
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file fails", ->
						beforeEach ->
							callbacks[2].callback "error three", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file fails", ->
							beforeEach ->
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
				describe "the first file fails", ->
					beforeEach ->
						callbacks[0].callback "error one", null
					it "raises an error", ->
						expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the second file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[1].callback null, "content two"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[2].callback null, "content three"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the second file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[1].callback "error two", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[2].callback "error three", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
								
				describe "the second file succeeds", ->
					beforeEach ->
						callbacks[1].callback null, "content two"
					it "does not raise an error", ->
						expect(grunt.fail.warn).not.toHaveBeenCalled()
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the first file succeeds", ->
						beforeEach ->
							callbacks[0].callback null, "content one"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							successTests -> callbacks[2].callback null, "content three"
						describe "the third file fails", ->
							beforeEach ->
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file succeeds", ->
						beforeEach ->
							callbacks[2].callback null, "content three"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							successTests -> callbacks[0].callback null, "content one"
						describe "the first file fails", ->
							beforeEach ->
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file fails", ->
						beforeEach ->
							callbacks[0].callback "error one", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file fails", ->
							beforeEach ->
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file fails", ->
						beforeEach ->
							callbacks[2].callback "error three", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file fails", ->
							beforeEach ->
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
				describe "the second file fails", ->
					beforeEach ->
						callbacks[1].callback "error two", null
					it "raises an error", ->
						expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the first file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[0].callback null, "content one"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[2].callback null, "content three"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[0].callback "error one", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the third file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback null, "content three"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the third file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[2].callback "error three", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the third file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[2].callback "error three", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
								
				describe "the third file succeeds", ->
					beforeEach ->
						callbacks[2].callback null, "content three"
					it "does not raise an error", ->
						expect(grunt.fail.warn).not.toHaveBeenCalled()
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the second file succeeds", ->
						beforeEach ->
							callbacks[1].callback null, "content two"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							successTests -> callbacks[0].callback null, "content one"
						describe "the first file fails", ->
							beforeEach ->
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file succeeds", ->
						beforeEach ->
							callbacks[0].callback null, "content one"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							successTests -> callbacks[1].callback null, "content two"
						describe "the second file fails", ->
							beforeEach ->
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the second file fails", ->
						beforeEach ->
							callbacks[1].callback "error two", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file fails", ->
							beforeEach ->
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file fails", ->
						beforeEach ->
							callbacks[0].callback "error one", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file fails", ->
							beforeEach ->
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "raises an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
				describe "the third file fails", ->
					beforeEach ->
						callbacks[2].callback "error three", null
					it "raises an error", ->
						expect(grunt.fail.warn).toHaveBeenCalledWith "error three"
					it "does not end the task yet", ->
						expect(async).not.toHaveBeenCalled()
					describe "the second file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[1].callback null, "content two"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file succeeds", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[0].callback null, "content one"
						it "does not raise an error", ->
							expect(grunt.fail.warn).not.toHaveBeenCalled()
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the second file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[1].callback "error two", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the first file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback null, "content one"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the first file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[0].callback "error one", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
					describe "the first file fails", ->
						beforeEach ->
							grunt.fail.warn.calls.reset()
							callbacks[0].callback "error one", null
						it "raises an error", ->
							expect(grunt.fail.warn).toHaveBeenCalledWith "error one"
						it "does not end the task yet", ->
							expect(async).not.toHaveBeenCalled()
						describe "the second file succeeds", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback null, "content two"
							it "does not raise an error", ->
								expect(grunt.fail.warn).not.toHaveBeenCalled()
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
						describe "the second file fails", ->
							beforeEach ->
								grunt.fail.warn.calls.reset()
								callbacks[1].callback "error two", null
							it "raises an error", ->
								expect(grunt.fail.warn).toHaveBeenCalledWith "error two"
							it "ends the task unsuccessfully", ->
								expect(async).toHaveBeenCalledWith false
