/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function create_array_object (properties_list)
	/**
	 * @constructor
	 */
	!function ArrayObject (array)
		if !(@ instanceof ArrayObject)
			return new ArrayObject(array)

		@'array'	= array

	ArrayObject::'clone'	= ->
		ArrayObject(@'array'slice())

	for let property, array_index in properties_list
		Object.defineProperty(ArrayObject::, property,
			get	: ->
				@'array'[array_index]
			set	: (value) !->
				@'array'[array_index]	= value
		)
	ArrayObject

function Wrapper (detox-utils, async-eventer)
	are_arrays_equal	= detox-utils['are_arrays_equal']
	ArrayMap			= detox-utils['ArrayMap']
	ArraySet			= detox-utils['ArraySet']
	base58_encode		= detox-utils['base58_encode']

	global_state		= Object.create(null)
	/**
	 * @constructor
	 */
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
			online							: false
			announced						: false
			messages						: ArrayMap()
			ui								:
				active_contact	: null
				# TODO
			online_contacts					: ArraySet()
			contacts_with_pending_messages	: ArraySet()

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'		= 0
				..'nickname'	= ''
				..'seed'		= null
				..'settings'	=
					'announce'				: true
					'bootstrap_nodes'		: [
						# TODO: This is just for demo purposes, in future must change to real bootstrap node(s)
						{
							'node_id'	: '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29'
							'host'		: '127.0.0.1'
							'port'		: 16882
						}
					]
					'bucket_size'			: 5
					'ice_servers'			: [
						{urls: 'stun:stun.l.google.com:19302'}
						{urls: 'stun:global.stun.twilio.com:3478?transport=udp'}
					]
					'max_pending_segments'	: 10
					'online'				: true
					'packets_per_second'	: 5
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

		# Denormalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])

		for secret in @_state['secrets']
			secret['secret']	= Uint8Array.from(secret['secret'])

		@_state['contacts']	= ArrayMap(
			for contact in @_state['contacts']
				contact[0]	= Uint8Array.from(contact[0])
				contact 	= Contact(contact)
				[contact['id'], contact]
		)

		# TODO: This is just for demo purposes
		@_local_state.messages.set(
			Array.from(@_state['contacts'].keys())[0],
			[
				Message([0, true, +(new Date), +(new Date), 'Received message'])
				Message([1, false, +(new Date), +(new Date), 'Sent message'])
			]
		)

		for contact_id in Array.from(@_state['contacts'].keys())
			@_update_contact_with_pending_messages(contact_id)

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
		'set_seed' : (new_seed) !->
			old_seed		= @_state['seed']
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
		 * @return {boolean} `true` if connected to network
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
		'set_ui_active_contact' : (new_active_contact) !->
			old_active_contact				= @_local_state.ui.active_contact
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
		'get_settings_bootstrap_nodes' : ->
			@_state['settings']['bootstrap_nodes']
		/**
		 * @param {string}		node_id
		 * @param {string}		host
		 * @param {number}		port
		 */
		'add_settings_bootstrap_node' : (node_id, host, port) !->
			bootstrap_node	=
				'node_id'	: node_id
				'host'		: host
				'port'		: port
			@_state['settings']['bootstrap_nodes'].push(bootstrap_node)
			@'fire'('settings_bootstrap_node_added', bootstrap_node)
			@'fire'('settings_bootstrap_nodes_changed')
		/**
		 * @param {!Array<!Object>} bootstrap_nodes
		 */
		'set_settings_bootstrap_nodes' : (bootstrap_nodes) !->
			old_bootstrap_nodes						= @_state['settings']['bootstrap_nodes']
			@_state['settings']['bootstrap_nodes']	= bootstrap_nodes
			@'fire'('settings_bootstrap_nodes_changed')
		/**
		 * @return {number}
		 */
		'get_settings_bucket_size' : ->
			@_state['settings']['bucket_size']
		/**
		 * @param {number} bucket_size
		 */
		'set_settings_bucket_size' : (bucket_size) !->
			old_bucket_size						= @_state['bucket_size']
			@_state['settings']['bucket_size']	= bucket_size
			@'fire'('settings_bucket_size_changed', bucket_size, old_bucket_size)
		/**
		 * @return {!Array<!Object>}
		 */
		'get_settings_ice_servers' : ->
			@_state['settings']['ice_servers']
		/**
		 * @param {!Array<!Object>} ice_servers
		 */
		'set_settings_ice_servers' : (ice_servers) !->
			old_ice_servers						= @_state['settings']['ice_servers']
			@_state['settings']['ice_servers']	= ice_servers
			@'fire'('settings_ice_servers_changed')
		/**
		 * @return {number}
		 */
		'get_settings_max_pending_segments' : ->
			@_state['settings']['max_pending_segments']
		/**
		 * @param {number} max_pending_segments
		 */
		'set_settings_max_pending_segments' : (max_pending_segments) !->
			old_max_pending_segments						= @_state['max_pending_segments']
			@_state['settings']['max_pending_segments']	= max_pending_segments
			@'fire'('settings_max_pending_segments_changed', max_pending_segments, old_max_pending_segments)
		/**
		 * @return {boolean} `false` if application works completely offline
		 */
		'get_settings_online' : ->
			@_state['settings']['online']
		/**
		 * @param {boolean} online
		 */
		'set_settings_online' : (online) !->
			old_online						= @_state['online']
			@_state['settings']['online']	= online
			@'fire'('settings_online_changed', online, old_online)
		/**
		 * @return {number}
		 */
		'get_settings_packets_per_second' : ->
			@_state['settings']['packets_per_second']
		/**
		 * @param {number} packets_per_second
		 */
		'set_settings_packets_per_second' : (packets_per_second) !->
			old_packets_per_second						= @_state['packets_per_second']
			@_state['settings']['packets_per_second']	= packets_per_second
			@'fire'('settings_packets_per_second_changed', packets_per_second, old_packets_per_second)
		/**
		 * @return {!Contact[]}
		 */
		'get_contacts' : ->
			Array.from(@_state['contacts'].values())
		/**
		 * @return {!Uint8Array[]}
		 */
		'get_contacts_with_pending_messages' : ->
			@_local_state.contacts_with_pending_messages
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {string}		nickname
		 */
		'add_contact' : (friend_id, nickname) !->
			# TODO: Secrets support
			if @_state['contacts'].has(friend_id)
				return
			if !nickname
				nickname = base58_encode(friend_id)
			new_contact	= Contact([friend_id, nickname, 0, 0])
			@_state['contacts'].set(new_contact['id'], new_contact)
			@'fire'('contact_added', new_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'has_contact' : (friend_id) ->
			@_state['contacts'].has(friend_id)
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {string}		nickname
		 */
		'set_contact_nickname' : (friend_id, nickname) !->
			old_contact	= @_state['contacts'].get(friend_id)
			if !old_contact
				return
			if !nickname
				nickname = base58_encode(friend_id)
			new_contact				= old_contact['clone']()
			new_contact['nickname']	= nickname
			@_state['contacts'].set(friend_id, new_contact)
			@'fire'('contact_updated', new_contact, old_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'del_contact' : (friend_id) !->
			old_contact	= @_state['contacts'].get(friend_id)
			if !old_contact
				return
			@_state['contacts'].delete(friend_id)
			@'fire'('contact_deleted', contact)
			@'fire'('contacts_changed')
		/**
		 * @return {!Uint8Array[]}
		 */
		'get_online_contacts' : ->
			Array.from(@_local_state.online_contacts)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'add_online_contact' : (friend_id) !->
			@_local_state.online_contacts.add(friend_id)
			@'fire'('contact_online', friend_id)
			@'fire'('online_contacts_changed')
			@_contact_update_last_active(friend_id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'has_online_contact' : (friend_id) ->
			@_local_state.online_contacts.has(friend_id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		'del_online_contact' : (friend_id) !->
			@_local_state.online_contacts.delete(friend_id)
			@'fire'('contact_offline', friend_id)
			@'fire'('online_contacts_changed')
			@_contact_update_last_active(friend_id)
			@_update_contact_with_pending_messages(friend_id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		_update_contact_with_pending_messages : (friend_id) !->
			for message in @'get_contact_messages'(friend_id)
				if !message.from && !message.date_sent
					@_local_state.contacts_with_pending_messages.add(friend_id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		_contact_update_last_active : (friend_id) !->
			old_contact						= @_state['contacts'].get(friend_id)
			new_contact						= old_contact['clone']()
			new_contact['last_time_active']	= +(new Date)
			@_state['contacts'].set(friend_id, new_contact)
			@'fire'('contact_updated', new_contact, old_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array} friend_id
		 *
		 * @return {!Message[]}
		 */
		'get_contact_messages' : (friend_id) ->
			@_local_state.messages.get(friend_id) || []
		/**
		 * @param {!Uint8Array} friend_id
		 *
		 * @return {!Message[]}
		 */
		'get_contact_messages_to_be_sent' : (friend_id) ->
			(@_local_state.messages.get(friend_id) || []).filter (message) ->
				!message.sent
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {boolean}		from			`true` if message was received and `false` if sent to a friend
		 * @param {number}		date_written	When message was written
		 * @param {number}		date_sent		When message was sent
		 * @param {string} 		text
		 *
		 * @return {number} Message ID
		 */
		'add_contact_message' : (friend_id, from, date_written, date_sent, text) !->
			if !@_local_state.messages.has(friend_id)
				@_local_state.messages.set(friend_id, [])
			messages	= @_local_state.messages.get(friend_id)
			id			= if messages.length then messages[messages.length - 1]['id'] + 1 else 0
			message		= Message([id, from, date_written, date_sent, text])
			messages.push(message)
			@'fire'('contact_message_added', friend_id, message)
			@'fire'('contact_messages_changed', friend_id)
			if from
				@_contact_update_last_active(friend_id)
			else
				if !@'has_online_contact'(friend_id)
					@_local_state.contacts_with_pending_messages.add(friend_id)
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {number}		id			Message ID
		 * @param {number}		date		Date when message was sent
		 */
		'set_contact_message_sent' : (friend_id, id, date) !->
			messages	= @_local_state.messages.get(friend_id)
			for message in messages by -1 # Should be faster to start from the end
				if message['id'] == id
					message['date_sent']	= date
					@_update_contact_with_pending_messages(friend_id)
					break
		# TODO: Many more methods here

	State:: = Object.assign(Object.create(async-eventer::), State::)
	Object.defineProperty(State::, 'constructor', {value: State})

	Contact	= create_array_object(['id', 'nickname', 'last_time_active', 'last_read_message'])

	Message	= create_array_object(['id', 'from', 'date_sent', 'date_received', 'text'])

	{
		'Contact'		: Contact
		'Message'		: Message
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
