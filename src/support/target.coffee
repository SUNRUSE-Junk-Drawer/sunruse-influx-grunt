module.exports = (grunt, outputs, targetName, target, tokenized, notifyWritingFile, notifyFileSucceeded, notifyFileFailed) ->
	grunt.log.writeln "Building for target \"" + targetName + "\"..."
	platform = target.platform()
	platform.functions = tokenized
	if target.runAssertions isnt false
		grunt.log.writeln "Running assertions..."
		assertions = module.exports.toolchain.runAssertions platform
		groupedAssertions = {}
		for assertion in assertions
			if assertion.resultType isnt "successful"
				if not groupedAssertions[assertion.assertion.line.filename]
					groupedAssertions[assertion.assertion.line.filename] = "\n" + assertion.assertion.line.filename
					
				description = switch assertion.resultType
					when "successful" then "Successful"
					when "failedToCompile" then "Failed to compile"
					when "didNotReturnPrimitiveConstant" then "Did not return a primitive constant"
					when "primitiveTypeNotAssertable" then "Returned non-assertable primitive type \"" + assertion.output.primitive.type + "\": " + (JSON.stringify assertion.output.primitive.value)
					when "primitiveValueIncorrect" then "Returned unexpected primitive value of type \"" + assertion.output.primitive.type + "\": " + (JSON.stringify assertion.output.primitive.value) + " whereas " + (JSON.stringify platform.primitives[assertion.output.primitive.type].assertionPass) + " was expected"
					
				groupedAssertions[assertion.assertion.line.filename] += "\n\tLine " + assertion.assertion.line.line + " - " + description
		if (Object.keys groupedAssertions).length
			composed = "One or more assertion(s) failed:"
			composed += group for groupName, group of groupedAssertions
			grunt.fail.warn composed
			return
	else
		grunt.log.writeln "Skipped running assertions."
	for outputName, output of outputs
		do (outputName, output) ->
			filename = target.prefix + outputName + target.suffix
			grunt.log.writeln "Compiling output \"" + outputName + "\"... (function \"" + output.name + "\" to filename \"" + filename + "\")"
			built = module.exports.toolchain.findFunction platform, output.input, output.name, null, null, {}
			if not built
				grunt.fail.warn "Failed to compile output \"" + outputName + "\" for target \"" + targetName + "\".  (function \"" + output.name + "\")"
			else
				module.exports.mkpath (module.exports.path.dirname filename), (err) ->
					if err
						grunt.fail.warn err
						notifyFileFailed()
					else
						options = if output.targetOptions then output.targetOptions[targetName] else undefined
						module.exports.fs.writeFile filename, (platform.compile platform, output.input, built, options), (err) ->
							if err
								grunt.fail.warn err
								notifyFileFailed()
							else
								notifyFileSucceeded()
				notifyWritingFile()
	
module.exports.toolchain = require "sunruse-influx-toolchain"
module.exports.mkpath = require "mkpath"
module.exports.fs = require "fs"
module.exports.path = require "path"