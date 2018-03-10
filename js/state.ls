/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (async-eventer)
	global_state	= Object.create(null)
	!function detox-state (name, initial_state)
		if !(@ instanceof detox-state)
			return new detox-state(name, initial_state)
		async-eventer.call(@)

		if !initial_state
			# TODO: localStorage for simplicity, will likely change to IndexedDB in future
			initial_state	= localStorage.getItem(name)
			initial_state	=
				if initial_state
					JSON.parse(initial_state)
				else
					Object.create(null)
		@_state	= initial_state

		# v0 of the state structure
		if !('version' of !@_state)
			@_state['version']	= 0
			@_state['profile']	= {
				'name'		: ''
				'seed'		: null
				'secrets'	: []
			}
			@_state['contacts']	= []

		# Normalize state after deserialization
		@_state['profile']['seed']	= Uint8Array.from(@_state['profile']['seed'])
		for secret in @_state['secrets']
			secret['secret']	= Uint8Array.from(secret['secret'])
		for contact in @_state['contacts']
			contact['public_key']	= Uint8Array.from(contact['public_key'])
			for secret in contact['secrets']
				secret['secret']	= Uint8Array.from(secret['secret'])

		@_ready = new Promise (resolve) !~>
			# Seed is necessary for operation
			if @_state['seed']
				resolve()
			else
				@_ready_resolve	= resolve

	detox-state:: = Object.create(async-eventer::)
	detox-state::
		/**
		 * @param {Function} callback Callback to be executed once state is ready
		 *
		 * @return {boolean} Whether state is ready
		 */
		..'ready' = (callback) ->
			if callback
				@_ready.then(callback)
			Boolean(@_state['profile']['seed'])
		/**
		 * @return {Uint8Array} Seed if configured or `null` otherwise
		 */
		..'get_seed' = ->
			@_state['profile']['seed']
		/**
		 * @param {!Uint8Array} seed
		 */
		..'set_seed' = (seed) !->
			@_state['profile']['seed']	= Uint8Array.from(seed)
			if @_ready_resolve
				@_ready_resolve()
				delete @_ready_resolve
		/**
		 * @return {!Array<!Object>}
		 */
		..'get_contacts' = ->
			@_state['contacts']
		# TODO: Many more methods here

	Object.defineProperty(detox-state::, 'constructor', {enumerable: false, value: detox-state})

	{
		/**
		 * @param {string}	name
		 * @param {!Object}	initial_state
		 *
		 * @return {!detoxState}
		 */
		'get_instance'	: (name, initial_state) ->
			if !(name of global_state)
				global_state[name]	= detox-state(initial_state)
			global_state[name]
	}

define(['async-eventer'], Wrapper)
