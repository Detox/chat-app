/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
if typeof requirejs == 'function'
	requirejs['config'](
		'baseUrl'	: '.'
		'paths'		:
			'@detox/base-x'				: 'node_modules/@detox/base-x/index'
			'@detox/chat'				: 'node_modules/@detox/chat/src/index'
			'@detox/core'				: 'node_modules/@detox/core/src/index'
			'@detox/crypto'				: 'node_modules/@detox/crypto/src/index'
			'@detox/dht'				: 'node_modules/@detox/dht/src/index'
			'@detox/nodes-manager'		: 'node_modules/@detox/nodes-manager/src/index'
			'@detox/routing'			: 'node_modules/@detox/routing/src/index'
			'@detox/simple-peer'		: 'node_modules/@detox/simple-peer/simplepeer.min'
			'@detox/transport'			: 'node_modules/@detox/transport/src/index'
			'@detox/utils'				: 'node_modules/@detox/utils/src/index'
			'array-map-set'				: 'node_modules/array-map-set/src/index'
			'async-eventer'				: 'node_modules/async-eventer/src/index'
			'es-dht'					: 'node_modules/es-dht/src/index'
			'autosize'					: 'node_modules/autosize/dist/autosize'
			'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index'
			'k-bucket-sync'				: 'node_modules/k-bucket-sync/src/index'
			'merkle-tree-binary'		: 'node_modules/merkle-tree-binary/src/index'
			'hotkeys-js'				: 'node_modules/hotkeys-js/dist/hotkeys'
			'marked'					: 'node_modules/marked/marked.min'
			'pako'						: 'node_modules/pako/dist/pako'
			'random-bytes-numbers'		: 'node_modules/random-bytes-numbers/src/index'
			'ronion'					: 'node_modules/ronion/src/index'
			'swipe-listener'			: 'node_modules/swipe-listener/dist/swipe-listener'
		'packages'	: [
			{
				'name'		: 'aez.wasm'
				'location'	: 'node_modules/aez.wasm'
				'main'		: 'src/index'
			}
			{
				'name'		: 'blake2.wasm',
				'location'	: 'node_modules/blake2.wasm',
				'main'		: 'src/index'
			}
			{
				'name'		: 'ed25519-to-x25519.wasm'
				'location'	: 'node_modules/ed25519-to-x25519.wasm'
				'main'		: 'src/index'
			}
			{
				'name'		: 'noise-c.wasm'
				'location'	: 'node_modules/noise-c.wasm'
				'main'		: 'src/index'
			}
			{
				'name'		: 'supercop.wasm'
				'location'	: 'node_modules/supercop.wasm'
				'main'		: 'src/index'
			}
		]
	)
else
	/**
	 * Simple RequireJS-like implementation that replaces alameda and should be enough for bundled modules
	 */
	defined_modules	= {}
	current_module	= {exports: null}
	wait_for		= {}
	/**
	 * @param {string} name
	 * @param {string} base_name
	 *
	 * @return {*}
	 */
	get_defined_module = (name, base_name) ->
		if name == 'exports'
			{}
		else if name == 'module'
			current_module
		else
			if name.startsWith('./')
				name	= base_name.split('/').slice(0, -1).join('/') + '/' + name.substr(2)
			defined_modules[name]
	/**
	 * @param {!Array<string>}	dependencies
	 * @param {string}			base_name
	 * @param {!Function}		fail_callback
	 *
	 * @return {Array}
	 */
	load_dependencies = (dependencies, base_name, fail_callback) ->
		loaded_dependencies = []
		if dependencies.every((dependency) ->
			loaded_dependency = get_defined_module(dependency, base_name)
			if !loaded_dependency
				fail_callback(dependency)
				return false
			loaded_dependencies.push(loaded_dependency)
			true
		)
			loaded_dependencies
		else
			null
	/**
	 * @param {string}		name
	 * @param {!Function}	callback
	 */
	add_wait_for = (name, callback) !->
		wait_for[][name].push(callback)
	/**
	 * @param {!Array<string>}	dependencies
	 * @param {!Function}		callback
	 *
	 * @return {!Promise}
	 */
	window['require'] = window['requirejs'] = (dependencies, callback) ->
		new Promise (resolve) !->
			loaded_dependencies = load_dependencies(
				dependencies
				''
				(dependency) !->
					add_wait_for(
						dependency
						->
							window['require'](dependencies, (...loaded_dependencies) !->
								if callback
									callback(...loaded_dependencies)
								resolve(loaded_dependencies)
							)
					)
			)
			if loaded_dependencies
				if callback
					callback(...loaded_dependencies)
				resolve(loaded_dependencies)
	/**
	 * @param {string}			name
	 * @param {!Array<string>}	dependencies
	 * @param {!Function}		wrapper
	 */
	window['define'] = (name, dependencies, wrapper) !->
		if !wrapper
			wrapper			= dependencies
			dependencies	= []
		loaded_dependencies = load_dependencies(
			dependencies
			name
			(dependency) !->
				add_wait_for(
					dependency
					->
						define(name, dependencies, wrapper)
				)
		)
		if loaded_dependencies
			defined_modules[name] = wrapper(...loaded_dependencies) || current_module.exports
			if wait_for[name]
				wait_for[name].forEach (resolve) !->
					resolve()
				delete wait_for[name]
	define['amd'] = {}
