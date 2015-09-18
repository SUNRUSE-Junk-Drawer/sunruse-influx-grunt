A Grunt task to compile SUNRUSE.influx code to native code.  To use, define the following configuration:

* sunruse-influx:
	* (target name):
		* src:
		An array of one or more glob strings specifying the source code files to compile.
		
		* outputs:
		An object where the keys are the filenames to generate, and the values are objects describing how to generate those files:
		
			* name:
			String specifying the function to be compiled.
			
			* input:
			A value object (see sunruse-influx-toolchain documentation) to compile as input to the function.
			
			* targetOptions:
			An object where the keys are the names of the targets and the values are the options to pass to the platform when compiling.  See the platforms' own documentation for what can be entered here.
			
		* targets:
		An object, where the keys are user-friendly names and the values are objects containing:
			
			* platform:
			The platform module instance to use, e.g. require("sunruse-influx-platforms-javascript")
			
			* runAssertions: (defaults to true)
			When truthy, assertions will be ran before compiling any output code.  If any fail, output code will not be compiled.
			
			* prefix: (defaults to empty string)
			A string prepended to filenames specified in "outputs".
			
			* suffix: (defaults to empty string)
			A string appended to filenames specified in "outputs".
			
An example which compiles the function "test-function" to "built/file-one-a.js" using sunruse-influx-platforms-javascript:

    "sunruse-influx": {
		"target-one": {
			src: ["influx-src/**/*.influx"],
			outputs: {
				"file-one-a": {
					name: "test-function"
					input: {
						score: 0,
						properties: {
							a: {
								primitive: {
									type: "bool",
									value: false
								}
							}
						}
					}
				}
			},
			targets: {
				"Browser": {
					platform: require("sunruse-influx-platforms-javascript"),
					runAssertions: true,
					prefix: "built/",
					suffix: ".js"
				}
			}
		}
	}