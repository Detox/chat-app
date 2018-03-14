/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (detox-utils, async-eventer)
	are_arrays_equal	= detox-utils['are_arrays_equal']
	ArrayMap			= detox-utils['ArrayMap']
	ArraySet			= detox-utils['ArraySet']

	global_state		= Object.create(null)
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
			online			: false
			announced		: false
			messages		: ArrayMap()
			ui				:
				active_contact	: null
				# TODO
			online_contacts	: ArraySet()

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'		= 0
				..'nickname'	= ''
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
						0
						0
					]
				]

		# Normalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])
		for secret in @_state['secrets']
			secret['secret']	= Uint8Array.from(secret['secret'])
		# Each contact item is an array `[friend_id, name, last_time_active, last_read_message]`
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
			old_seed		= @_state['seed']
			new_seed		= Uint8Array.from(seed)
			@_state['seed']	= new_seed
			if @_ready_resolve
				@_ready_resolve()
				delete @_ready_resolve
			@'fire'('seed_changed', new_seed, old_seed)
		/**
		 * @return {Uint8Array} Seed if configured or `null` otherwise
		 */
		'get_nickname' : ->
			@_state['nickname']
		/**
		 * @param {string} nickname
		 */
		'set_nickname' : (nickname) !->
			old_nickname		= @_state['nickname']
			new_nickname		= String(nickname)
			@_state['nickname']	= new_nickname
			@'fire'('nickname_changed', new_nickname, old_nickname)
		/**
		 * @return {boolean}
		 */
		'get_online' : ->
			@_local_state.online
		/**
		 * @param {boolean} online
		 */
		'set_online' : (online) !->
			old_online				= @_local_state.online
			new_online				= !!online
			@_local_state.online	= new_online
			@'fire'('online_changed', new_online, old_online)
		/**
		 * @return {boolean}
		 */
		'get_announced' : ->
			@_local_state.announced
		/**
		 * @param {boolean} announced
		 */
		'set_announced' : (announced) !->
			old_announced			= @_local_state.announced
			new_announced			= !!announced
			@_local_state.announced	= new_announced
			@'fire'('announced_changed', new_announced, old_announced)
		/**
		 * @return {boolean}
		 */
		'get_ui_active_contact' : ->
			@_local_state.ui.active_contact
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'set_ui_active_contact' : (friend_id) !->
			old_active_contact				= @_local_state.ui.active_contact
			new_active_contact				= Uint8Array.from(friend_id)
			@_local_state.ui.active_contact = new_active_contact
			@'fire'('ui_active_contact_changed', new_active_contact, old_active_contact)
		/**
		 * @return {boolean}
		 */
		'get_settings_announce' : ->
			@_state['settings']['announce']
		/**
		 * @param {boolean} announce
		 */
		'set_settings_announce' : (announce) !->
			old_announce					= @_state['settings']['announce']
			new_announce					= !!announce
			@_state['settings']['announce']	= new_announce
			@'fire'('settings_announce_changed')
		/**
		 * @return {!Array<!Object>}
		 */
		'get_contacts' : ->
			@_state['contacts']
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {string}		nickname
		 */
		'add_contact' : (friend_id, nickname) !->
			# TODO: Secrets support
			for contact in @_state['contacts']
				if are_arrays_equal(friend_id, contact[0])
					return
			new_contact	= [Uint8Array.from(friend_id), nickname, 0, 0]
			@_state['contacts'].push(new_contact)
			@'fire'('contact_added', new_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'has_contact' : (friend_id) ->
			for contact in @_state['contacts']
				if are_arrays_equal(friend_id, contact[0])
					return true
			false
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {string}		nickname
		 */
		'set_contact_nickname' : (friend_id, nickname) !->
			for contact, i in @_state['contacts']
				if are_arrays_equal(friend_id, contact[0])
					old_contact				= contact.slice()
					new_contact				= contact.slice()
					new_contact[1]			= nickname
					@_state['contacts'][i]	= new_contact
					@'fire'('contact_updated', new_contact, old_contact)
					@'fire'('contacts_changed')
					break
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'del_contact' : (friend_id) !->
			for contact, i in @_state['contacts']
				if are_arrays_equal(friend_id, contact[0])
					@_state['contacts'].splice(i, 1)
					@'fire'('contact_deleted', contact)
					@'fire'('contacts_changed')
					break
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_online_contacts' : ->
			Array.from(@_local_state.online_contacts)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'add_online_contact' : (friend_id) ->
			@_local_state.online_contacts.add(friend_id)
			@'fire'('contact_online', friend_id)
			@'fire'('online_contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'has_online_contact' : (friend_id) ->
			@_local_state.online_contacts.has(friend_id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'del_online_contact' : (friend_id) ->
			@_local_state.online_contacts.delete(friend_id)
			@'fire'('contact_offline', friend_id)
			@'fire'('online_contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 *
		 * @return {!Array<!Array>} Each inner array is `[from, date, text]`, where `received` is `true` if message was received and `false` if sent to a friend
		 */
		'get_contact_messages' : (friend_id) ->
			@_local_state.messages.get(friend_id) || []
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {boolean}		from		`true` if message was received and `false` if sent to a friend
		 * @param {number}		date
		 * @param {string} 		text
		 */
		'add_contact_message' : (friend_id, from, date, text) !->
			if !@_local_state.messages.has(friend_id)
				@_local_state.messages.set(friend_id, [])
			friend_id	= Uint8Array.from(friend_id)
			messages	= @_local_state.messages.get(friend_id)
			message		= [from, date, text]
			messages.push(message)
			@'fire'('contact_messages_changed', friend_id, message)
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
