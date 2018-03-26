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

	ArrayObject::clone	= ->
		ArrayObject(@'array'slice())

	for let property, array_index in properties_list
		Object.defineProperty(ArrayObject::, property,
			get	: ->
				@'array'[array_index]
			set	: (value) !->
				@'array'[array_index]	= value
		)
	ArrayObject

function Wrapper (detox-chat, detox-utils, async-eventer)
	id_encode			= detox-chat['id_encode']
	are_arrays_equal	= detox-utils['are_arrays_equal']
	ArrayMap			= detox-utils['ArrayMap']
	ArraySet			= detox-utils['ArraySet']

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
			connected_nodes_count			: 0
			aware_of_nodes_count			: 0
			routing_paths_count				: 0
			application_connections_count	: 0
			messages						: ArrayMap()
			ui								:
				active_contact	: null
			online_contacts					: ArraySet()
			contacts_with_pending_messages	: ArraySet()
			contacts_with_unread_messages	: ArraySet()

		# v0 of the state structure
		if !('version' of @_state)
			@_state
				..'version'						= 0
				..'nickname'					= ''
				..'seed'						= null
				..'settings'					=
					'announce'						: true
					# Block request from contact we've already rejected for 30 days
					'block_contact_requests_for'	: 30 * 24 * 60 * 60
					'bootstrap_nodes'				: [
						# TODO: This is just for demo purposes, in future must change to real bootstrap node(s)
						{
							'node_id'	: '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29'
							'host'		: '127.0.0.1'
							'port'		: 16882
						}
					]
					'bucket_size'					: 5
					'help'							: true
					'ice_servers'					: [
						{urls: 'stun:stun.l.google.com:19302'}
						{urls: 'stun:global.stun.twilio.com:3478?transport=udp'}
					]
					'max_pending_segments'			: 10
					'number_of_intermediate_nodes'	: 3
					'number_of_introduction_nodes'	: 3
					'online'						: true
					'packets_per_second'			: 5
					# [reconnection_trial, time_before_next_attempt]
					'reconnects_intervals'			: [
						[5, 30]
						[10, 60]
						[15, 150]
						[100, 300]
						[Number.MAX_SAFE_INTEGER, 600]
					]
				..'contacts'					= [
					# TODO: This is just for demo purposes
					[
						[6, 148, 79, 1, 76, 156, 177, 211, 195, 184, 108, 220, 189, 121, 140, 15, 134, 174, 141, 222, 146, 77, 20, 115, 211, 253, 148, 149, 128, 147, 190, 125]
						'Fake contact #1'
						0
						0
						null
						null
						null
					]
					[
						[6, 148, 79, 1, 76, 156, 177, 211, 195, 184, 108, 220, 189, 121, 140, 15, 134, 174, 141, 222, 146, 77, 20, 115, 211, 253, 148, 149, 128, 147, 190, 126]
						'Fake contact #2'
						0
						0
						null
						null
						null
					]
				]
				..'contacts_requests'			= []
				..'contacts_requests_blocked'	= []
				..'secrets'						= []

		# Denormalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])

		@_state['contacts']						= ArrayMap(
			for contact in @_state['contacts']
				contact[0]	= Uint8Array.from(contact[0])
				contact 	= Contact(contact)
				[contact['id'], contact]
		)
		@_state['contacts_requests']			= ArrayMap(
			for contact in @_state['contacts_requests']
				contact[0]	= Uint8Array.from(contact[0])
				contact 	= ContactRequest(contact)
				[contact['id'], contact]
		)
		current_date							= +(new Date)
		@_state['contacts_requests_blocked']	= ArrayMap(
			for contact in @_state['contacts_requests_blocked']
				if contact.blocked_until > current_date
					contact[0]	= Uint8Array.from(contact[0])
					contact 	= ContactRequestBlocked(contact)
					[contact['id'], contact]
		)
		@_state['secrets']						= ArrayMap(
			for secret in @_state['secrets']
				secret[0]	= Uint8Array.from(secret[0])
				secret	 	= Secret(secret)
				[secret['secret'], secret]
		)

		# TODO: This is just for demo purposes
		@_local_state.messages.set(
			Array.from(@_state['contacts'].keys())[0],
			[
				Message([1, true, +(new Date), +(new Date), 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'])
				Message([2, false, +(new Date), +(new Date), 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'])
			]
		)

		for contact_id in Array.from(@_state['contacts'].keys())
			@_update_contact_with_pending_messages(contact_id)
			@_update_contact_with_unread_messages(contact_id)

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
		 * @return {number}
		 */
		'get_connected_nodes_count' : ->
			@_local_state.connected_nodes_count
		/**
		 * @param {number} count
		 */
		'set_connected_nodes_count' : (count) !->
			@_local_state.connected_nodes_count	= count
			@'fire'('connected_nodes_count_changed', count)
		/**
		 * @return {number}
		 */
		'get_aware_of_nodes_count' : ->
			@_local_state.aware_of_nodes_count
		/**
		 * @param {number} count
		 */
		'set_aware_of_nodes_count' : (count) !->
			@_local_state.aware_of_nodes_count	= count
			@'fire'('aware_of_nodes_count_changed', count)
		/**
		 * @return {number}
		 */
		'get_routing_paths_count' : ->
			@_local_state.routing_paths_count
		/**
		 * @param {number} count
		 */
		'set_routing_paths_count' : (count) !->
			@_local_state.routing_paths_count	= count
			@'fire'('routing_paths_count_changed', count)
		/**
		 * @return {number}
		 */
		'get_application_connections_count' : ->
			@_local_state.application_connections_count
		/**
		 * @param {number} count
		 */
		'set_application_connections_count' : (count) !->
			@_local_state.application_connections_count	= count
			@'fire'('application_connections_count_changed', count)
		/**
		 * @return {Uint8Array}
		 */
		'get_ui_active_contact' : ->
			@_local_state.ui.active_contact
		/**
		 * @param {Uint8Array} contact_id
		 */
		'set_ui_active_contact' : (new_active_contact) !->
			old_active_contact				= @_local_state.ui.active_contact
			@_local_state.ui.active_contact = new_active_contact
			@'fire'('ui_active_contact_changed', new_active_contact, old_active_contact)
			if new_active_contact
				@_update_contact_with_unread_messages(new_active_contact)
			if old_active_contact
				@_update_contact_last_read_message(old_active_contact)
				@_update_contact_with_unread_messages(old_active_contact)
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
			new_announce					= announce
			@_state['settings']['announce']	= new_announce
			@'fire'('settings_announce_changed', new_announce, old_announce)
		/**
		 * @return {number} In seconds
		 */
		'get_settings_block_contact_requests_for' : ->
			@_state['settings']['block_contact_requests_for']
		/**
		 * @return {number} In seconds
		 */
		'set_settings_block_contact_requests_for' : (block_contact_requests_for) ->
			old_block_contact_requests_for						= @_state['settings']['block_contact_requests_for']
			@_state['settings']['block_contact_requests_for']	= block_contact_requests_for
			@'fire'('settings_block_contact_requests_for_changed', block_contact_requests_for, old_block_contact_requests_for)
		/**
		 * @return {!Array<!Object>}
		 */
		'get_settings_bootstrap_nodes' : ->
			@_state['settings']['bootstrap_nodes']
		/**
		 * @param {!Array<!Object>} bootstrap_nodes
		 */
		'set_settings_bootstrap_nodes' : (bootstrap_nodes) !->
			old_bootstrap_nodes						= @_state['settings']['bootstrap_nodes']
			@_state['settings']['bootstrap_nodes']	= bootstrap_nodes
			@'fire'('settings_bootstrap_nodes_changed', bootstrap_nodes, old_bootstrap_nodes)
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
		 * @return {boolean}
		 */
		'get_settings_help' : ->
			@_state['settings']['help']
		/**
		 * @param {boolean} help
		 */
		'set_settings_help' : (help) !->
			old_help					= @_state['settings']['help']
			new_help					= help
			@_state['settings']['help']	= new_help
			@'fire'('settings_help_changed', new_help, old_help)
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
			@'fire'('settings_ice_servers_changed', ice_servers, old_ice_servers)
		/**
		 * @return {number}
		 */
		'get_settings_max_pending_segments' : ->
			@_state['settings']['max_pending_segments']
		/**
		 * @param {number} max_pending_segments
		 */
		'set_settings_max_pending_segments' : (max_pending_segments) !->
			old_max_pending_segments					= @_state['max_pending_segments']
			@_state['settings']['max_pending_segments']	= max_pending_segments
			@'fire'('settings_max_pending_segments_changed', max_pending_segments, old_max_pending_segments)
		/**
		 * @return {number}
		 */
		'get_settings_number_of_intermediate_nodes' : ->
			@_state['settings']['number_of_intermediate_nodes']
		/**
		 * @param {number} number_of_intermediate_nodes
		 */
		'set_settings_number_of_intermediate_nodes' : (number_of_intermediate_nodes) !->
			old_number_of_intermediate_nodes					= @_state['number_of_intermediate_nodes']
			@_state['settings']['number_of_intermediate_nodes']	= number_of_intermediate_nodes
			@'fire'('settings_number_of_intermediate_nodes_changed', number_of_intermediate_nodes, old_number_of_intermediate_nodes)
		/**
		 * @return {number}
		 */
		'get_settings_number_of_introduction_nodes' : ->
			@_state['settings']['number_of_introduction_nodes']
		/**
		 * @param {number} number_of_introduction_nodes
		 */
		'set_settings_number_of_introduction_nodes' : (number_of_introduction_nodes) !->
			old_number_of_introduction_nodes					= @_state['number_of_introduction_nodes']
			@_state['settings']['number_of_introduction_nodes']	= number_of_introduction_nodes
			@'fire'('settings_number_of_introduction_nodes_changed', number_of_introduction_nodes, old_number_of_introduction_nodes)
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
		 * @return {!Array<!Array<number>>}
		 */
		'get_settings_reconnects_intervals' : ->
			@_state['settings']['reconnects_intervals']
		/**
		 * @param {!Array<!Array<number>>} reconnects_intervals
		 */
		'set_settings_reconnects_intervals' : (reconnects_intervals) !->
			old_reconnects_intervals					= @_state['reconnects_intervals']
			@_state['settings']['reconnects_intervals']	= reconnects_intervals
			@'fire'('settings_reconnects_intervals_changed', reconnects_intervals, old_reconnects_intervals)
		/**
		 * @return {!Array<!Contact>}
		 */
		'get_contacts' : ->
			Array.from(@_state['contacts'].values())
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_contacts_with_pending_messages' : ->
			Array.from(@_local_state.contacts_with_pending_messages.values())
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_contacts_with_unread_messages' : ->
			Array.from(@_local_state.contacts_with_unread_messages.values())
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'get_contact' : (contact_id) ->
			@_state['contacts'].get(contact_id)
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {string}		nickname
		 * @param {Uint8Array}	remote_secret
		 */
		'add_contact' : (contact_id, nickname, remote_secret) !->
			if @'has_contact'(contact_id)
				return
			nickname	= nickname.trim()
			if !nickname
				nickname = id_encode(contact_id, new Uint8Array(0))
			new_contact	= Contact([contact_id, nickname, 0, 0, remote_secret, null, null])
			@_state['contacts'].set(contact_id, new_contact)
			@'fire'('contact_added', new_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'has_contact' : (contact_id) ->
			@_state['contacts'].has(contact_id)
		/**
		 * @param {!Uint8Array}			contact_id
		 * @param {!Object<string, *>}	properties
		 */
		_set_contact : (contact_id, properties) !->
			old_contact	= @'get_contact'(contact_id)
			if !old_contact
				return
			new_contact	= old_contact.clone()
			for property, value of properties
				new_contact[property]	= value
			@_state['contacts'].set(contact_id, new_contact)
			@'fire'('contact_changed', new_contact, old_contact)
			@'fire'('contacts_changed')
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {string}		nickname
		 */
		'set_contact_nickname' : (contact_id, nickname) !->
			if !nickname
				nickname = id_encode(contact_id, new Uint8Array(0))
			@_set_contact(contact_id, {
				'nickname'	: nickname
			})
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {!Uint8Array}	remote_secret
		 */
		'set_contact_remote_secret' : (contact_id, remote_secret) !->
			@_set_contact(contact_id, {
				'remote_secret'	: remote_secret
			})
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {!Uint8Array}	local_secret
		 */
		'set_contact_local_secret' : (contact_id, local_secret) !->
			old_contact	= @'get_contact'(contact_id)
			if !old_contact
				return
			old_local_secret	= old_contact['old_local_secret'] || old_contact['local_secret']
			@_set_contact(contact_id, {
				'old_local_secret'	: old_local_secret
				'local_secret'		: local_secret
			})
		/**
		 * @param {!Uint8Array} contact_id
		 */
		_update_contact_last_active : (contact_id) !->
			@_set_contact(contact_id, {
				'last_time_active'	: +(new Date)
			})
		/**
		 * @param {!Uint8Array}	contact_id
		 */
		_update_contact_last_read_message : (contact_id) !->
			@_set_contact(contact_id, {
				'last_read_message'	: +(new Date)
			})
		/**
		 * @param {!Uint8Array}	contact_id
		 */
		'del_contact_old_local_secret' : (contact_id) !->
			@_set_contact(contact_id, {
				'old_local_secret'	: null
			})
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'del_contact' : (contact_id) !->
			old_contact	= @'get_contact'(contact_id)
			if !old_contact
				return
			if are_arrays_equal(@'get_ui_active_contact'() || new Uint8Array(0), contact_id)
				@'set_ui_active_contact'(null)
			@_local_state.messages.delete(contact_id)
			@'fire'('contact_messages_changed', contact_id)
			@_state['contacts'].delete(contact_id)
			@'fire'('contact_deleted', old_contact)
			@'fire'('contacts_changed')
		/**
		 * @return {!Array<!ContactRequest>}
		 */
		'get_contacts_requests' : ->
			Array.from(@_state['contacts_requests'].values())
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {string}		secret_name
		 */
		'add_contact_request' : (contact_id, secret_name) !->
			if @'has_contact_request'(contact_id)
				return
			new_contact_request	= ContactRequest([contact_id, id_encode(contact_id, new Uint8Array(0)), secret_name])
			@_state['contacts_requests'].set(contact_id, new_contact_request)
			@'fire'('contact_request_added', new_contact_request)
			@'fire'('contacts_requests_changed')
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {boolean}
		 */
		'has_contact_request' : (contact_id) ->
			@_state['contacts_requests'].has(contact_id)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'del_contact_request' : (contact_id) !->
			old_contact_request	= @_state['contacts_requests'].get(contact_id)
			if !old_contact_request
				return
			@_state['contacts_requests'].delete(contact_id)
			blocked_until	= (new Date) + @'get_settings_block_contact_requests_for'()
			@_state['contacts_requests_blocked'].set(contact_id, ContactRequestBlocked([contact_id, blocked_until]))
			@'fire'('contact_request_deleted', old_contact_request)
			@'fire'('contacts_requests_changed')
		/**
		 * @return {!Array<!ContactRequestBlocked>}
		 */
		'get_contacts_requests_blocked' : ->
			Array.from(@_state['contacts_requests_blocked'].values())
		/**
		 * @param {!Uint8Array}	contact_id
		 */
		'has_contact_request_blocked' : (contact_id) ->
			contact_request_blocked	= @_state['contacts_requests_blocked'].get(contact_id)
			if contact_request_blocked && contact_request_blocked.blocked_until > +(new Date)
				true
			else
				@_state['contacts_requests_blocked'].delete(contact_id)
		/**
		 * @return {!Array<!Uint8Array>}
		 */
		'get_online_contacts' : ->
			Array.from(@_local_state.online_contacts)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'add_online_contact' : (contact_id) !->
			@_local_state.online_contacts.add(contact_id)
			@'fire'('contact_online', contact_id)
			@'fire'('online_contacts_changed')
			@_update_contact_last_active(contact_id)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'has_online_contact' : (contact_id) ->
			@_local_state.online_contacts.has(contact_id)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		'del_online_contact' : (contact_id) !->
			@_local_state.online_contacts.delete(contact_id)
			@'fire'('contact_offline', contact_id)
			@'fire'('online_contacts_changed')
			@_update_contact_last_active(contact_id)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		_update_contact_with_pending_messages : (contact_id) !->
			for message in @'get_contact_messages'(contact_id) by -1
				if !message['from'] && !message['date_sent']
					if !@_local_state.contacts_with_pending_messages.has(contact_id)
						@_local_state.contacts_with_pending_messages.add(contact_id)
						@'fire'('contacts_with_pending_messages_changed')
					return
			@_local_state.contacts_with_pending_messages.delete(contact_id)
			@'fire'('contacts_with_pending_messages_changed')
		/**
		 * @param {!Uint8Array} contact_id
		 */
		_update_contact_with_unread_messages : (contact_id) !->
			last_read_message	= @'get_contact'(contact_id)['last_read_message']
			for message in @'get_contact_messages'(contact_id)
				if message['from'] && message['date_sent'] > last_read_message
					if !@_local_state.contacts_with_unread_messages.has(contact_id)
						@_local_state.contacts_with_unread_messages.add(contact_id)
						@'fire'('contacts_with_unread_messages_changed')
					return
			@_local_state.contacts_with_unread_messages.delete(contact_id)
			@'fire'('contacts_with_unread_messages_changed')
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {!Array<!Message>}
		 */
		'get_contact_messages' : (contact_id) ->
			@_local_state.messages.get(contact_id) || []
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {!Array<!Message>}
		 */
		'get_contact_messages_to_be_sent' : (contact_id) ->
			@'get_contact_messages'(contact_id).filter (message) ->
				!message['from'] && !message['date_sent']
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {boolean}		from			`true` if message was received and `false` if sent to a friend
		 * @param {number}		date_written	When message was written
		 * @param {number}		date_sent		When message was sent
		 * @param {string} 		text
		 *
		 * @return {number} Message ID
		 */
		'add_contact_message' : (contact_id, from, date_written, date_sent, text) !->
			if !@_local_state.messages.has(contact_id)
				@_local_state.messages.set(contact_id, [])
			messages	= @_local_state.messages.get(contact_id)
			id			= if messages.length then messages[* - 1]['id'] + 1 else 1
			message		= Message([id, from, date_written, date_sent, text])
			messages.push(message)
			if from
				@_update_contact_last_active(contact_id)
				if !are_arrays_equal(@'get_ui_active_contact'() || new Uint8Array(0), contact_id)
					@_update_contact_with_unread_messages(contact_id)
			else
				@_update_contact_with_pending_messages(contact_id)
			@'fire'('contact_message_added', contact_id, message)
			@'fire'('contact_messages_changed', contact_id)
			id
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {number}		message_id	Message ID
		 * @param {number}		date		Date when message was sent
		 */
		'set_contact_message_sent' : (contact_id, message_id, date) !->
			messages	= @_local_state.messages.get(contact_id)
			for message in messages by -1 # Should be faster to start from the end
				if message['id'] == message_id
					message['date_sent']	= date
					@_update_contact_with_pending_messages(contact_id)
					@'fire'('contact_messages_changed', contact_id)
					break
		/**
		 * @return {!Array<!Object>}
		 */
		'get_secrets' : ->
			Array.from(@_state['secrets'].values())
		/**
		 * @param {!Uint8Array}	secret
		 * @param {string}		name
		 */
		'add_secret' : (secret, name) !->
			new_secret	= Secret([secret, name])
			@_state['secrets'].set(new_secret['secret'], new_secret)
			@'fire'('secret_added', new_secret)
			@'fire'('secrets_changed')
		/**
		 * @param {!Uint8Array}	secret
		 * @param {string}		name
		 */
		'set_secret_name' : (secret, name) !->
			old_secret			= @_state['secrets'].get(secret)
			new_secret			= old_secret.clone()
			new_secret['name']	= name
			@_state['secrets'].set(secret, new_secret)
			@'fire'('secrets_changed')
		/**
		 * @param {!Array<!Secret>} secrets
		 */
		'set_secrets' : (secrets) !->
			@_state['secrets']	= secrets
			@'fire'('secrets_changed')
		/**
		 * @param {!Uint8Array}	secret
		 */
		'del_secret' : (secret) !->
			old_secret	= @_state['secrets'].get(secret)
			if !old_secret
				return
			@_state['secrets'].delete(secret)
			@'fire'('secret_deleted', old_secret)
			@'fire'('secrets_changed')

	State:: = Object.assign(Object.create(async-eventer::), State::)
	Object.defineProperty(State::, 'constructor', {value: State})

	/**
	 * Remote secret is used by us to connect to remote friend.
	 * Local secret is used by remote friend to connect to us.
	 * Old local secret is kept in addition to local secret until it is proven that remote friend updated its remote secret.
	 */
	Contact					= create_array_object(['id', 'nickname', 'last_time_active', 'last_read_message', 'remote_secret', 'local_secret', 'old_local_secret'])
	ContactRequest			= create_array_object(['id', 'name', 'secret_name'])
	ContactRequestBlocked	= create_array_object(['id', 'blocked_until'])
	Message					= create_array_object(['id', 'from', 'date_written', 'date_sent', 'text'])
	Secret					= create_array_object(['secret', 'name'])

	{
		'Contact'				: Contact
		'ContactRequest'		: ContactRequest
		'ContactRequestBlocked'	: ContactRequestBlocked
		'Message'				: Message
		'Secret'				: Secret
		'State'					: State
		/**
		 * @param {string}	name
		 * @param {!Object}	initial_state
		 *
		 * @return {!detoxState}
		 */
		'get_instance'			: (name, initial_state) ->
			if !(name of global_state)
				global_state[name]	= State(initial_state)
			global_state[name]
	}

define(['@detox/chat', '@detox/utils', 'async-eventer'], Wrapper)
