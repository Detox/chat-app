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
			network_state		: State['NETWORK_STATE_OFFLINE']
			announcement_state	: State['ANNOUNCEMENT_STATE_NOT_ANNOUNCED']

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'		= 0
				..'name'		= ''
				..'seed'		= null
				..'settings'	= {} # TODO
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

	State.'NETWORK_STATE_OFFLINE'				= 0
	State.'NETWORK_STATE_ONLINE'				= 1
	State.'ANNOUNCEMENT_STATE_NOT_ANNOUNCED'	= 0
	State.'ANNOUNCEMENT_STATE_ANNOUNCED'		= 1
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
			@'fire'('seed_updated')
		/**
		 * @return {number} One of `State.NETWORK_STATE_*` constants
		 */
		'get_network_state' : ->
			@_local_state.network_state
		/**
		 * @param {number} network_state One of `State.NETWORK_STATE_*` constants
		 */
		'set_network_state' : (network_state) !->
			switch network_state
				case State['NETWORK_STATE_OFFLINE'], State['NETWORK_STATE_ONLINE']
					@_local_state.network_state = network_state
					@'fire'('network_state_updated')
		/**
		 * @return {number} One of `State.NETWORK_STATE_*` constants
		 */
		'get_announcement_state' : ->
			@_local_state.announcement_state
		/**
		 * @param {number} announcement_state One of `State.ANNOUNCEMENT_STATE_*` constants
		 */
		'set_announcement_state' : (announcement_state) !->
			switch announcement_state
				case State['ANNOUNCEMENT_STATE_NOT_ANNOUNCED'], State['ANNOUNCEMENT_STATE_ANNOUNCED']
					@_local_state.announcement_state = announcement_state
					@'fire'('announcement_state_updated')
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
