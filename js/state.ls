/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const STATE_VERSION = 1

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
/**
 * @param {!Blob}	blob
 * @param {number}	start
 * @param {number}	length
 * @param {string}	as		Either `string` or `buffer` (for `ArrayBuffer`)
 *
 * @return {!Promise} Will resolve with requested data
 *
 * @throws {Error}
 */
function read_blob_slice (blob, start, length, as)
	if blob.size < (start + length)
		throw new Error
	blob	= blob.slice(start, start + length)
	new Promise (resolve) !->
		reader			= new FileReader
		reader.onload	= !->
			resolve(reader.result)
		switch as
			case 'buffer'
				reader.readAsArrayBuffer(blob)
			case 'string'
				reader.readAsText(blob)

function Wrapper (detox-chat, detox-utils, async-eventer)
	id_encode			= detox-chat['id_encode']
	are_arrays_equal	= detox-utils['are_arrays_equal']
	ArrayMap			= detox-utils['ArrayMap']
	ArraySet			= detox-utils['ArraySet']

	global_state		= Object.create(null)
	/**
	 * @constructor
	 */
	!function State (chat_id)
		if !(@ instanceof State)
			return new State(chat_id)
		async-eventer.call(@)

		@_chat_id = chat_id
		# TODO: contacts secrets history archive in IndexedDB

		backup_chat_id	= chat_id + '-backup'
		backup_present	= false

		# State that is preserved across restarts
		@_state = do ->
			# Synchronous localStorage for contacts, settings and other data
			backup_state	= localStorage.getItem(backup_chat_id)
			if backup_state
				backup_present	:= true
				return JSON.parse(backup_state)
			initial_state	= localStorage.getItem(chat_id)
			if initial_state
				JSON.parse(initial_state)
			else
				Object.create(null)

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
				sidebar_shown	: false
			online_contacts					: ArraySet()
			contacts_with_pending_messages	: ArraySet()
			contacts_with_unread_messages	: ArraySet()

		if backup_present
			backup_db_ready	= new Promise (resolve) !~>
				indexedDB.open(backup_chat_id, STATE_VERSION)
					..onsuccess = (e) !~>
						@_backup_database	= e.target.result
						resolve()
					..onerror = (e) !->
						console.error('Opening backup messages database failed', e)
						detox_chat_app.notify_error('An error happened during opening backup messages database, restoring from backup canceled, please restart')
						localStorage.removeItem(backup_chat_id)
						indexedDB.deleteDatabase(backup_chat_id)
		else
			backup_db_ready	= Promise.resolve()

		@_database_ready = backup_db_ready
			.then ~>
				new Promise (resolve) !~>
					if backup_present
						# Remove existing database, we'll restore data from backup
						indexedDB.deleteDatabase(chat_id)
					indexedDB.open(chat_id, STATE_VERSION)
						..onsuccess = (e) !~>
							@_database	= e.target.result
							resolve()
						..onerror = (e) !->
							console.error('Opening messages database failed', e)
							detox_chat_app.notify_error('An error happened during opening messages database')
						..onupgradeneeded = (e) !~>
							@_database		= e.target.result
							messages_store	= @_database.createObjectStore('messages', {
								keyPath			: 'message_id'
								autoIncrement	: true
							})
							messages_store.createIndex('contact_id', 'contact_id')
			.then ~>
				if backup_present
					new Promise (resolve) !~>
						# Restore data from backup
						tx	= @_backup_database.transaction('messages', 'readwrite')
							..oncomplete	= !~>
								@_backup_database.close()
								resolve()
							..onerror		= (e) !->
								console.error('Messages transaction failed', e)
						tx.objectStore('messages').openCursor()
							.onsuccess	= (e) !~>
								cursor = e.target.result
								if cursor
									message	= cursor.value
									@_messages_transaction (messages_store) !->
										messages_store.put(message)
									cursor.continue()

		@_messages_transactions = @_database_ready

		# v1 of the state structure
		if !('version' of @_state)
			@_state
				..'version'						= STATE_VERSION
				..'nickname'					= ''
				..'seed'						= null
				..'settings'					= JSON.parse(JSON.stringify(State.DEFAULT_SETTINGS))
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
			# TODO: This is just for demo purposes
			setTimeout !~>
				@'add_contact_message'(@'get_contacts'()[0]['id'], State['MESSAGE_ORIGIN_RECEIVED'], +(new Date), +(new Date), 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')
				@'add_contact_message'(@'get_contacts'()[0]['id'], State['MESSAGE_ORIGIN_SENT'], +(new Date), +(new Date), 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')

		# Denormalize state after deserialization
		if @_state['seed']
			@_state['seed']	= Uint8Array.from(@_state['seed'])

		@_ready = Promise.all([
			@_database_ready
			new Promise (resolve) !~>
				# Seed is necessary for operation
				if @_state['seed']
					resolve()
				else
					@_ready_resolve	= resolve
		])

		if backup_present
			@_ready.then !->
				localStorage.removeItem(backup_chat_id)
				indexedDB.deleteDatabase(backup_chat_id)
				detox_chat_app.notify_success('Restoration from backup finished successfully!', 5)

		@_state['contacts']						= ArrayMap(
			for contact in @_state['contacts']
				contact[0]	= Uint8Array.from(contact[0])
				contact[4]	= contact[4] && Uint8Array.from(contact[4])
				contact[5]	= contact[5] && Uint8Array.from(contact[5])
				contact[6]	= contact[6] && Uint8Array.from(contact[6])
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

		for contact_id in Array.from(@_state['contacts'].keys())
			@_update_contact_with_pending_messages(contact_id)
			@_update_contact_with_unread_messages(contact_id)

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
		 * @return {!Promise} Resolves with {Blob}
		 */
		'get_as_blob' : ->
			Promise.all(
				for let contact in @'get_contacts'()
					@_messages_transaction((messages_store, payload_callback) !->
						messages_store.index('contact_id').getAll(IDBKeyRange.only(contact.id))
							..onsuccess	= (e) !->
								messages	= e.target.result
								messages	= messages.map (message) ->
									[message['message_id'], message['origin'], message['date_written'], message['date_sent'], message['text']]
								payload_callback(new Blob([JSON.stringify(messages)]))
					)
			)
				.then (messages_blobs) ~>
					serialized_state	= @_serialize_state()
					header				= JSON.stringify(
						[serialized_state.length].concat(messages_blobs.map (blob) ->
							blob.size
						)
					)
					header_length		= new ArrayBuffer(4)
					view				= new DataView(header_length)
					view.setUint32(0, header.length, false)
					# TODO: Probably compress with pako
					new Blob([header_length, header, serialized_state].concat(messages_blobs))
		/**
		 * @param {!Blob} blob
		 */
		'set_from_blob' : (blob) !->
			var backup_state
			backup_chat_id	= @_chat_id + '-backup'
			# Delete potential existing backup data first
			localStorage.removeItem(backup_chat_id)
			indexedDB.deleteDatabase(backup_chat_id)
			# TODO: Probably decompress with pako
			# Now read header length
			read_blob_slice(blob, 0, 4, 'buffer')
				.then (buffer) ->
					view			= new DataView(buffer)
					header_length	= view.getUint32(0, false)
					# Read header
					read_blob_slice(blob, 4, header_length, 'string')
				.then (header) ->
					header_length	= header.length
					header			= JSON.parse(header)
					data_length		= header.reduce (a, b) ->
						a + b
					# Check if Blob size corresponds to header contents
					if blob.size != (4 + header_length + data_length)
						throw Error
					/**
					 * Header is an array of numbers, each number is a length of corresponding part.
					 * First part if JSON-encoded state, each next part corresponds to JSON-encoded messages for once contact in the order of stored contacts.
					 */
					read_blob_slice(blob, 4 + header_length, header[0], 'string')
						.then (serialized_state) ->
							state	= JSON.parse(serialized_state)
							if state['version'] > STATE_VERSION
								detox_chat_app.notify_error('Restoration from backup created by newer version is not supported, upgrade first', 5)
								throw new Error
							localStorage.setItem(backup_chat_id, serialized_state)
						.then ->
							backup_state		:= State(backup_chat_id)
							start_offset		= 4 + header_length + header[0]
							contacts_messages	= backup_state['get_contacts']().map (contact, index) ->
								start			= start_offset
								length			= header[index + 1]
								start_offset	+= length
								[contact.id, start, length]
							function restore_contact_messages
								contact_messages	= contacts_messages.shift()
								if !contact_messages
									return
								[contact_id, start, length]	= contact_messages
								read_blob_slice(blob, start, length, 'string')
									.then (messages) ->
										backup_state._messages_transaction (messages_store) !->
											for message in JSON.parse(messages)
												messages_store.put({
													'contact_id'	: contact_id,
													'message_id'	: message[0],
													'origin'		: message[1],
													'date_written'	: message[2],
													'date_sent'		: message[3],
													'text'			: message[4]
												})
									.then ->
										# Recursively restore messages for all contacts
										restore_contact_messages()
							restore_contact_messages()
				.then !->
					detox_chat_app.notify_warning('Restoration from backup is almost done, restart is needed to finish the process')
				.catch !->
					console.error ...&
					localStorage.removeItem(backup_chat_id)
					if backup_state
						backup_state._database?.close()
					indexedDB.deleteDatabase(backup_chat_id)
					detox_chat_app.notify_error('Restoration from backup failed, make sure you have selected correct backup file and try again', 5)
		'delete_data' : !->
			if @_deleted
				return
			localStorage.removeItem(@_chat_id)
			@_database.close()
			indexedDB.deleteDatabase(@_chat_id)
			@_deleted = true
		/**
		 * @return {string} JSON string
		 */
		_serialize_state : ->
			prepared_state	= {}
			for key, value of @_state
				switch key
					case 'seed'
						prepared_state[key]	= Array.from(value)
					case 'contacts', 'contacts_requests', 'contacts_requests_blocked', 'secrets'
						prepared_state[key]	=
							for item in Array.from(value.values())
								contents	= item['array'].slice()
								for item, index in contents
									if item instanceof Uint8Array
										contents[index]	= Array.from(item)
								contents
					default
						prepared_state[key]	= value
			JSON.stringify(prepared_state)
		_save_state : !->
			if @_deleted
				return
			localStorage.setItem(@_chat_id, @_serialize_state())
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
			@_save_state()
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
			@_save_state()
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
			@_local_state.ui.active_contact	= new_active_contact
			@'fire'('ui_active_contact_changed', new_active_contact, old_active_contact)
			if new_active_contact
				@_update_contact_last_read_message(new_active_contact)
				@_update_contact_with_unread_messages(new_active_contact)
		/**
		 * @return {boolean}
		 */
		'get_ui_sidebar_shown' : ->
			@_local_state.ui.sidebar_shown
		/**
		 * @param {boolean} new_sidebar_shown
		 */
		'set_ui_sidebar_shown' : (new_sidebar_shown) !->
			old_sidebar_shown				= @_local_state.ui.sidebar_shown
			@_local_state.ui.sidebar_shown	= new_sidebar_shown
			@'fire'('ui_sidebar_shown_changed', new_sidebar_shown, old_sidebar_shown)
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
			@'fire'('settings_announce_changed', new_announce, old_announce)
			@_save_state()
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
			@_state['settings']['block_contact_requests_for']	= parseInt(block_contact_requests_for)
			@'fire'('settings_block_contact_requests_for_changed', block_contact_requests_for, old_block_contact_requests_for)
			@_save_state()
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
			@_save_state()
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
			@_state['settings']['bucket_size']	= parseInt(bucket_size)
			@'fire'('settings_bucket_size_changed', bucket_size, old_bucket_size)
			@_save_state()
		/**
		 * @return {number} One of State.EXPERIENCE_* constants
		 */
		'get_settings_experience' : ->
			@_state['settings']['experience']
		/**
		 * @param {number} experience One of State.EXPERIENCE_* constants
		 */
		'set_settings_experience' : (experience) !->
			old_experience						= @_state['experience']
			@_state['settings']['experience']	= parseInt(experience)
			@'fire'('settings_experience_changed', experience, old_experience)
			@_save_state()
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
			new_help					= !!help
			@_state['settings']['help']	= new_help
			@'fire'('settings_help_changed', new_help, old_help)
			@_save_state()
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
			@_save_state()
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
			@_state['settings']['max_pending_segments']	= parseInt(max_pending_segments)
			@'fire'('settings_max_pending_segments_changed', max_pending_segments, old_max_pending_segments)
			@_save_state()
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
			@_state['settings']['number_of_intermediate_nodes']	= parseInt(number_of_intermediate_nodes)
			@'fire'('settings_number_of_intermediate_nodes_changed', number_of_intermediate_nodes, old_number_of_intermediate_nodes)
			@_save_state()
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
			@_state['settings']['number_of_introduction_nodes']	= parseInt(number_of_introduction_nodes)
			@'fire'('settings_number_of_introduction_nodes_changed', number_of_introduction_nodes, old_number_of_introduction_nodes)
			@_save_state()
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
			new_online						= !!online
			@_state['settings']['online']	= new_online
			@'fire'('settings_online_changed', new_online, old_online)
			@_save_state()
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
			@_state['settings']['packets_per_second']	= parseInt(packets_per_second)
			@'fire'('settings_packets_per_second_changed', packets_per_second, old_packets_per_second)
			@_save_state()
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
			@_save_state()
		/**
		 * @return {boolean} `true` if message should be sent with Ctrl+Enter and `false` if with just Enter
		 */
		'get_settings_send_ctrl_enter' : ->
			@_state['settings']['send_ctrl_enter']
		/**
		 * @param {boolean} send_ctrl_enter
		 */
		'set_settings_send_ctrl_enter' : (send_ctrl_enter) !->
			old_send_ctrl_enter						= @_state['send_ctrl_enter']
			new_send_ctrl_enter						= !!send_ctrl_enter
			@_state['settings']['send_ctrl_enter']	= new_send_ctrl_enter
			@'fire'('settings_send_ctrl_enter_changed', new_send_ctrl_enter, old_send_ctrl_enter)
			@_save_state()
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
			@_save_state()
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
			@_save_state()
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
			<~! @'del_contact_messages'(contact_id).then
			@_state['contacts'].delete(contact_id)
			@'fire'('contact_deleted', old_contact)
			@_update_contact_with_pending_messages()
			@_update_contact_with_unread_messages()
			@'fire'('contacts_changed')
			@_save_state()
		/**
		 * @return {!Array<!ContactRequest>}
		 */
		'get_contacts_requests' : ->
			Array.from(@_state['contacts_requests'].values())
		/**
		 * @param {!Uint8Array} contact_id
		 * @param {!Uint8Array} secret
		 */
		'add_contact_request' : (contact_id, secret) !->
			if @'has_contact_request'(contact_id)
				return
			secret_name	= @_state['secrets'].get(secret).name
			if @'get_settings_experience' >= State.EXPERIENCE_ADVANCED
				name	= id_encode(contact_id, new Uint8Array(0))
			else
				name	= id_encode(contact_id, secret)
			new_contact_request	= ContactRequest([contact_id, name, secret_name])
			@_state['contacts_requests'].set(contact_id, new_contact_request)
			@'fire'('contact_request_added', new_contact_request)
			@'fire'('contacts_requests_changed')
			@_save_state()
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
			@_save_state()
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
			(messages) <~! @'get_contact_messages'(contact_id).then
			for message in messages by -1
				if message['origin'] == State['MESSAGE_ORIGIN_SENT'] && !message['date_sent']
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
			(messages)			<~! @'get_contact_messages'(contact_id).then
			for message in messages
				if message['origin'] == State['MESSAGE_ORIGIN_RECEIVED'] && message['date_sent'] > last_read_message
					if !@_local_state.contacts_with_unread_messages.has(contact_id)
						@_local_state.contacts_with_unread_messages.add(contact_id)
						@'fire'('contacts_with_unread_messages_changed')
					return
			@_local_state.contacts_with_unread_messages.delete(contact_id)
			@'fire'('contacts_with_unread_messages_changed')
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {!Promise} Resolves with `Array<Message>`
		 */
		'get_contact_messages' : (contact_id) ->
			@_messages_transactions.then ~>
				messages	= @_local_state.messages.get(contact_id)
				if messages
					messages
				else
					@_messages_transaction((messages_store, payload_callback) !~>
						messages_store.index('contact_id').getAll(IDBKeyRange.only(contact_id))
							..onsuccess	= (e) !~>
								payload_callback(e.target.result)
					)
						.then (messages) ~>
							messages	= messages.map (message) ->
								Message([
									message['message_id']
									message['origin']
									message['date_written']
									message['date_sent']
									message['text']
								])
							@_local_state.messages.set(contact_id, messages)
							messages
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {!Promise} Resolves with `Array<Message>`
		 */
		'get_contact_messages_to_be_sent' : (contact_id) ->
			@'get_contact_messages'(contact_id)
				.then (messages) ->
					messages.filter (message) ->
						message['origin'] == State['MESSAGE_ORIGIN_SENT'] && !message['date_sent']
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {number}		origin			One of State.MESSAGE_ORIGIN_* constants
		 * @param {number}		date_written	When message was written
		 * @param {number}		date_sent		When message was sent
		 * @param {string} 		text
		 *
		 * @return {!Promise} Resolves with `message_id`
		 */
		'add_contact_message' : (contact_id, origin, date_written, date_sent, text) ->
			@_messages_transaction((messages_store, payload_callback) !~>
				messages_store.add({
					'contact_id'	: contact_id,
					'origin'		: origin,
					'date_written'	: date_written,
					'date_sent'		: date_sent,
					'text'			: text
				})
					.onsuccess = (e) !->
						payload_callback(e.target.result)
			)
				.then (id) ~>
					message	= Message([id, origin, date_written, date_sent, text])
					# Delete messages from local state, they will be fetched next time from database
					@_local_state.messages.delete(contact_id)
					if origin == State['MESSAGE_ORIGIN_RECEIVED']
						@_update_contact_last_active(contact_id)
						if !are_arrays_equal(@'get_ui_active_contact'() || new Uint8Array(0), contact_id)
							@_update_contact_with_unread_messages(contact_id)
						else
							@_update_contact_last_read_message(contact_id)
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
			(messages) <~! @'get_contact_messages'(contact_id).then
			for message in messages by -1 # Should be faster to start from the end
				if message['id'] == message_id
					message['date_sent']	= date
					@_messages_transaction((messages_store) !->
						messages_store.put({
							'message_id'	: message_id
							'contact_id'	: contact_id,
							'origin'		: message['origin'],
							'date_written'	: message['date_written'],
							'date_sent'		: message['date_sent'],
							'text'			: message['text']
						})
					)
						.then ~>
							@_update_contact_with_pending_messages(contact_id)
							@'fire'('contact_messages_changed', contact_id)
					break
		/**
		 * @param {!Uint8Array} contact_id
		 *
		 * @return {!Promise}
		 */
		'del_contact_messages' : (contact_id) ->
			@_messages_transaction((messages_store) !~>
				messages_store.index('contact_id').openCursor(IDBKeyRange.only(contact_id))
					.onsuccess	= (e) !->
						cursor = e.target.result
						if cursor
							cursor.delete()
							cursor.continue()
			)
				.then !~>
					@_local_state.messages.delete(contact_id)
					@'fire'('contact_messages_changed', contact_id)
		/**
		 * @param {!Function}	callback
		 *
		 * @return {!Promise}
		 */
		_messages_transaction : (callback) ->
			# This way we make all transactions sequential, this is because we only sync data to database, but primarily work with messages in local state
			@_messages_transactions	= @_messages_transactions
				.then ~>
					new Promise (resolve, reject) !~>
						var value
						tx	= @_database.transaction('messages', 'readwrite')
							..oncomplete	= !->
								resolve(value)
							..onerror		= (e) !->
								console.error('Messages transaction failed', e)
								reject()
						# Call function from second argument if you want promise to resolve with some value in it
						callback(tx.objectStore('messages'), (result) !->
							value	:= result
						)
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
			@_save_state()
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
			@_save_state()
		/**
		 * @param {!Array<!Secret>} secrets
		 */
		'set_secrets' : (secrets) !->
			@_state['secrets']	= secrets
			@'fire'('secrets_changed')
			@_save_state()
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
			@_save_state()

	State:: = Object.assign(Object.create(async-eventer::), State::)
	Object.defineProperty(State::, 'constructor', {value: State})

	# Some constants
	constants	=
		'EXPERIENCE_REGULAR'		: 0
		'EXPERIENCE_ADVANCED'		: 1
		'EXPERIENCE_DEVELOPER'		: 2
		'MESSAGE_ORIGIN_SENT'		: 0
		'MESSAGE_ORIGIN_RECEIVED'	: 1
		'MESSAGE_ORIGIN_SERVICE'	: 2
	# For convenience, assign both on constructor and on instances
	Object.assign(State, constants)
	Object.assign(State::, constants)

	# Default settings, potentially can be relatively easily customized
	State.DEFAULT_SETTINGS	=
		'announce'						: true
		# Block request from contact we've already rejected for 30 days
		'block_contact_requests_for'	: 30 * 24 * 60 * 60
		'bootstrap_nodes'				: [
#			{
#				'node_id'	: '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29'
#				'host'		: '127.0.0.1'
#				'port'		: 16882
#			}
			# Testnet bootstrap nodes
			{
				'node_id'	: '50da72d1fe105c649a1c16c085627b368196e258667d2a2fc02d4b8af7182651',
				'host'		: '0-testnet-bootstrap.detox.technology',
				'port'		: 443
			}
			{
				'node_id'	: '252223a2ae1d325578d8cd2f0d65dada5d342927cfbbf8dbfd9edc3e247b5a0b',
				'host'		: '1-testnet-bootstrap.detox.technology',
				'port'		: 443
			}
			{
				'node_id'	: 'e9a374b6aa204a48c40a9679a636319b029fa4e68ee29dbd7da9326ea681b91d',
				'host'		: '2-testnet-bootstrap.detox.technology',
				'port'		: 443
			}

		]
		'bucket_size'					: 2
		'experience'					: State.EXPERIENCE_REGULAR
		'help'							: true
		'ice_servers'					: [
			{'urls': 'stun:stun.l.google.com:19302'}
#			{'urls': 'stun:global.stun.twilio.com:3478?transport=udp'}
			# Testnet turn server
			{
				'urls'			: 'turn:0-testnet-turn.detox.technology'
				'username'		: 'detox-user'
				'credential'	: 'pwd'
			}
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
		'send_ctrl_enter'				: true

	/**
	 * Remote secret is used by us to connect to remote friend.
	 * Local secret is used by remote friend to connect to us.
	 * Old local secret is kept in addition to local secret until it is proven that remote friend updated its remote secret.
	 */
	Contact					= create_array_object(['id', 'nickname', 'last_time_active', 'last_read_message', 'remote_secret', 'local_secret', 'old_local_secret'])
	ContactRequest			= create_array_object(['id', 'name', 'secret_name'])
	ContactRequestBlocked	= create_array_object(['id', 'blocked_until'])
	Message					= create_array_object(['id', 'origin', 'date_written', 'date_sent', 'text'])
	Secret					= create_array_object(['secret', 'name'])

	{
		'Contact'				: Contact
		'ContactRequest'		: ContactRequest
		'ContactRequestBlocked'	: ContactRequestBlocked
		'Message'				: Message
		'Secret'				: Secret
		'State'					: State
		/**
		 * @param {string}	chat_id
		 * @param {!Object}	initial_state
		 *
		 * @return {!detoxState}
		 */
		'get_instance'			: (chat_id) ->
			if !(chat_id of global_state)
				global_state[chat_id]	= State(chat_id)
			global_state[chat_id]
	}

define(['@detox/chat', '@detox/utils', 'async-eventer'], Wrapper)
