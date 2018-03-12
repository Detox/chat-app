/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (async-eventer)
	global_state	= Object.create(null)
	!function State (name, initial_state)
		if !(@ instanceof State)
			return new State(name, initial_state)
		async-eventer.call(@)

		if !initial_state
			# TODO: localStorage for simplicity, will likely change to IndexedDB in future
			initial_state	= localStorage.getItem(name)
			initial_state	=
				if initial_state
					JSON.parse(initial_state)
				else
					Object.create(null)

		# State that is preserved across restarts
		@_state	= initial_state

		# State that is only valid for current session
		@_local_state =
			online		: false
			announced	: false

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'		= 0
				..'name'		= ''
				..'seed'		= null
				..'settings'	=
					'announce_myself'	: true
					# TODO
				..'secrets'		= []
				..'contacts'	= []

		# Normalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])
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

	State:: =
		/**
		 * @param {Function} callback Callback to be executed once state is ready
		 *
		 * @return {boolean} Whether state is ready
		 */
		'ready' : (callback) ->
			if callback
				@_ready.then(callback)
			Boolean(@_state['seed'])
		/**
		 * @return {Uint8Array} Seed if configured or `null` otherwise
		 */
		'get_seed' : ->
			@_state['seed']
		/**
		 * @param {!Uint8Array} seed
		 */
		'set_seed' : (seed) !->
			@_state['seed']	= Uint8Array.from(seed)
			if @_ready_resolve
				@_ready_resolve()
				delete @_ready_resolve
			@'fire'('seed_changed')
		/**
		 * @return {Uint8Array} Seed if configured or `null` otherwise
		 */
		'get_name' : ->
			@_state['name']
		/**
		 * @param {string} name
		 */
		'set_name' : (name) !->
			@_state['name']	= String(name)
			@'fire'('name_changed')
		/**
		 * @return {boolean}
		 */
		'get_online' : ->
			@_local_state.online
		/**
		 * @param {boolean} online
		 */
		'set_online' : (online) !->
			@_local_state.online = online
			@'fire'('online_changed')
		/**
		 * @return {boolean}
		 */
		'get_announced' : ->
			@_local_state.announced
		/**
		 * @param {boolean} announced
		 */
		'set_announced' : (announced) !->
			@_local_state.announced = announced
			@'fire'('announced_changed')
		/**
		 * @return {boolean}
		 */
		'get_settings_announce_myself' : ->
			@_state['settings']['announce_myself']
		/**
		 * @param {boolean} announce_myself
		 */
		'set_settings_announce_myself' : (announce_myself) !->
			@_state['settings']['announce_myself']	= announce_myself
			@'fire'('settings_announce_myself_changed')
		/**
		 * @return {!Array<!Object>}
		 */
		'get_contacts' : ->
			@_state['contacts']
		# TODO: Many more methods here

	State:: = Object.assign(Object.create(async-eventer::), State::)
	Object.defineProperty(State::, 'constructor', {enumerable: false, value: State})

	{
		'State'			: State
		/**
		 * @param {string}	name
		 * @param {!Object}	initial_state
		 *
		 * @return {!detoxState}
		 */
		'get_instance'	: (name, initial_state) ->
			if !(name of global_state)
				global_state[name]	= State(initial_state)
			global_state[name]
	}

define(['async-eventer'], Wrapper)
