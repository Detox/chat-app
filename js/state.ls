/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (detox-utils, async-eventer)
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
			messages	: detox-utils.ArrayMap()
			ui			:
				active_contact	: null
				# TODO

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'		= 0
				..'name'		= ''
				..'seed'		= null
				..'settings'	=
					'announce'	: true
					# TODO
				..'secrets'		= []
				..'contacts'	= [
					# TODO: This is just for demo purposes
					[
						[6, 148, 79, 1, 76, 156, 177, 211, 195, 184, 108, 220, 189, 121, 140, 15, 134, 174, 141, 222, 146, 77, 20, 115, 211, 253, 148, 149, 128, 147, 190, 125]
						'Fake contact'
						(+Date)
					]
				]

		# Normalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])
		for secret in @_state['secrets']
			secret['secret']	= Uint8Array.from(secret['secret'])
		# Each contact item is an array `[public_key, name, last_time_active]`
		for contact in @_state['contacts']
			contact[0]	= Uint8Array.from(contact[0])

		# TODO: This is just for demo purposes
		@_local_state.messages.set(
			@_state['contacts'][0][0],
			[
				[true, +(new Date), 'Received message']
				[false, +(new Date), 'Sent message']
			]
		)
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
			@_local_state.online = !!online
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
			@_local_state.announced = !!announced
			@'fire'('announced_changed')
		/**
		 * @return {boolean}
		 */
		'get_ui_active_contact' : ->
			@_local_state.ui.active_contact
		/**
		 * @param {!Uint8Array} public_key
		 */
		'set_ui_active_contact' : (public_key) !->
			@_local_state.ui.active_contact = public_key
			@'fire'('ui_active_contact_changed')
		/**
		 * @return {boolean}
		 */
		'get_settings_announce' : ->
			@_state['settings']['announce']
		/**
		 * @param {boolean} announce
		 */
		'set_settings_announce' : (announce) !->
			@_state['settings']['announce']	= !!announce
			@'fire'('settings_announce_changed')
		/**
		 * @return {!Array<!Object>}
		 */
		'get_contacts' : ->
			@_state['contacts']
		/**
		 * @param {!Uint8Array} public_key
		 *
		 * @return {!Array<!Array>} Each inner array is `[from, date, text]`, where `received` is `true` if message was received and `false` if sent to a friend
		 */
		'get_contact_messages' : (public_key) ->
			@_local_state.messages.get(public_key) || []
		/**
		 * @param {!Uint8Array}	public_key
		 * @param {boolean}		from		`true` if message was received and `false` if sent to a friend
		 * @param {number}		date
		 * @param {string} 		text
		 */
		'add_contact_message' : (public_key, from, date, text) !->
			if !@_local_state.messages.has(public_key)
				@_local_state.messages.set(public_key, [])
			messages	= @_local_state.messages.get(public_key)
			messages.push([from, date, text])
			@'fire'('contact_messages_changed')
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

define(['@detox/utils', 'async-eventer'], Wrapper)
