/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
([behaviors]) <-! require(['js/behaviors']).then
Polymer(
	is			: 'detox-chat-app-sidebar-settings'
	behaviors	: [
		behaviors.experience_level
		behaviors.help
		behaviors.state_instance
	]
	properties	:
		desired_anonymity					:
			observer	: '_desired_anonymity_changed'
			type		: Number
		desired_anonymity_custom			:
			computed	: '_desired_anonymity_custom(desired_anonymity)'
			type		: Boolean
		settings_additional_options			:
			observer	: '_settings_additional_options_changed'
			type		: Object
		settings_additional_options_string	: String
		settings_announce						:
			observer	: '_settings_announce_changed'
			type		: String
		settings_audio_notifications						:
			observer	: '_settings_audio_notifications_changed'
			type		: String
		settings_block_contact_requests_for		:
			observer	: '_settings_block_contact_requests_for_changed'
			type		: Number
		settings_bootstrap_nodes				:
			observer	: '_settings_bootstrap_nodes_changed'
			type		: Object
		settings_bootstrap_nodes_string			: String
		settings_bucket_size					:
			observer	: '_settings_bucket_size_changed'
			type		: Number
		settings_direct_connections				:
			observer	: '_settings_direct_connections_changed'
			type		: Number
		settings_experience						:
			observer	: '_settings_experience_changed'
			type		: Number
		settings_help							:
			observer	: '_settings_help_changed'
			type		: String
		settings_ice_servers					:
			observer	: '_settings_ice_servers_changed'
			type		: Object
		settings_ice_servers_string				: String
		settings_max_pending_segments			:
			observer	: '_settings_max_pending_segments_changed'
			type		: Number
		settings_number_of_intermediate_nodes	:
			observer	: '_settings_number_of_intermediate_nodes_changed'
			type		: Number
		settings_number_of_introduction_nodes	:
			observer	: '_settings_number_of_introduction_nodes_changed'
			type		: Number
		settings_online							:
			observer	: '_settings_online_changed'
			type		: String
		settings_packets_per_second				:
			observer	: '_settings_packets_per_second_changed'
			type		: Number
		settings_reconnects_intervals			:
			observer	: '_settings_reconnects_intervals_changed'
			type		: Object
		settings_reconnects_intervals_string	: String
		settings_send_ctrl_enter				:
			observer	: '_settings_send_ctrl_enter_changed'
			type		: String
	ready : !->
		state									= @state
		@settings_additional_options			= state.get_settings_additional_options()
		@settings_announce						= @_bool_to_string(state.get_settings_announce())
		@settings_audio_notifications			= @_bool_to_string(state.get_settings_audio_notifications())
		@settings_block_contact_requests_for	= state.get_settings_block_contact_requests_for() / 60 / 60 / 24 # In days
		@settings_bootstrap_nodes				= state.get_settings_bootstrap_nodes()
		@settings_bucket_size					= state.get_settings_bucket_size()
		@settings_direct_connections			= state.get_settings_direct_connections()
		@settings_experience					= state.get_settings_experience()
		@settings_help							= @_bool_to_string(state.get_settings_help())
		@settings_ice_servers					= state.get_settings_ice_servers()
		@settings_max_pending_segments			= state.get_settings_max_pending_segments()
		@settings_number_of_intermediate_nodes	= state.get_settings_number_of_intermediate_nodes()
		@settings_number_of_introduction_nodes	= state.get_settings_number_of_introduction_nodes()
		@settings_online						= @_bool_to_string(state.get_settings_online())
		@settings_packets_per_second			= state.get_settings_packets_per_second()
		@settings_reconnects_intervals			= state.get_settings_reconnects_intervals()
		@settings_send_ctrl_enter				= @_bool_to_string(state.get_settings_send_ctrl_enter())
		@_update_desired_anonymity()
		state
			.on('settings_additional_options_changed', (@settings_additional_options) !~>)
			.on('settings_announce_changed', (new_settings_announce) !~>
				new_settings_announce	= @_bool_to_string(new_settings_announce)
			)
			.on('settings_audio_notifications_changed', (new_settings_audio_notifications) !~>
				new_settings_audio_notifications	= @_bool_to_string(new_settings_audio_notifications)
			)
			.on('settings_block_contact_requests_for_changed', (block_contact_requests_for) !~>
				@block_contact_requests_for	= block_contact_requests_for / 60 / 60 / 24 # In days
			)
			.on('settings_bootstrap_nodes_changed', (@settings_bootstrap_nodes) !~>)
			.on('settings_bucket_size_changed', (@settings_bucket_size) !~>)
			.on('settings_direct_connections_changed', (@settings_direct_connections) !~>
				@_update_desired_anonymity()
			)
			.on('settings_experience_changed', (@settings_experience) !~>)
			.on('settings_help_changed', (new_settings_help) !~>
				new_settings_help	= @_bool_to_string(new_settings_help)
				@settings_help		= new_settings_help
			)
			.on('settings_ice_servers_changed', (@settings_ice_servers) !~>)
			.on('settings_max_pending_segments_changed', (@settings_max_pending_segments) !~>)
			.on('settings_number_of_intermediate_nodes_changed', (@settings_number_of_intermediate_nodes) !~>
				@_update_desired_anonymity()
			)
			.on('settings_number_of_introduction_nodes_changed', (@settings_number_of_introduction_nodes) !~>)
			.on('settings_online_changed', (new_settings_online) !~>
				new_settings_online	= @_bool_to_string(new_settings_online)
				@settings_online	= new_settings_online
			)
			.on('settings_packets_per_second_changed', (@settings_packets_per_second) !~>)
			.on('settings_reconnects_intervals_changed', (@settings_reconnects_intervals) !~>)
			.on('settings_send_ctrl_enter_changed', (new_settings_send_ctrl_enter) !~>
				new_settings_send_ctrl_enter	= @_bool_to_string(new_settings_send_ctrl_enter)
				@settings_send_ctrl_enter		= new_settings_send_ctrl_enter
			)
	_bool_to_string : (value) ->
		if value then '1' else '0'
	_update_desired_anonymity : !->
		if @settings_number_of_intermediate_nodes == undefined
			return
		settings_direct_connections				= parseInt(@settings_direct_connections)
		settings_number_of_intermediate_nodes	= parseInt(@settings_number_of_intermediate_nodes)
		if (
			settings_direct_connections == @state['DIRECT_CONNECTIONS_REJECT'] &&
			settings_number_of_intermediate_nodes == @state['DEFAULT_SETTINGS']['number_of_intermediate_nodes']
		)
			@desired_anonymity = 0 # Strict
		else if (
			settings_direct_connections == @state['DEFAULT_SETTINGS']['direct_connections'] &&
			settings_number_of_intermediate_nodes == @state['DEFAULT_SETTINGS']['number_of_intermediate_nodes']
		)
			@desired_anonymity = 1 # High
		else if settings_number_of_intermediate_nodes == 0 && settings_direct_connections == @state['DIRECT_CONNECTIONS_ACCEPT']
			@desired_anonymity = 2 # Low
		else
			@desired_anonymity = 3 # Custom
	_desired_anonymity_changed : (desired_anonymity) !->
		changed_no_restart	= false
		changed_restart		= false
		switch parseInt(desired_anonymity)
			case 0
				if @state.get_settings_direct_connections() != @state['DIRECT_CONNECTIONS_REJECT']
					@state.set_settings_direct_connections(@state['DIRECT_CONNECTIONS_REJECT'])
					changed_no_restart	= true
				if @state.get_settings_number_of_intermediate_nodes() != @state['DEFAULT_SETTINGS']['number_of_intermediate_nodes']
					@state.set_settings_number_of_intermediate_nodes(@state['DEFAULT_SETTINGS']['number_of_intermediate_nodes'])
					changed_restart	= true
			case 1
				if @state.get_settings_direct_connections() != @state['DEFAULT_SETTINGS']['direct_connections']
					@state.set_settings_direct_connections(@state['DEFAULT_SETTINGS']['direct_connections'])
					changed_no_restart	= true
				if @state.get_settings_number_of_intermediate_nodes() != @state['DEFAULT_SETTINGS']['number_of_intermediate_nodes']
					@state.set_settings_number_of_intermediate_nodes(@state['DEFAULT_SETTINGS']['number_of_intermediate_nodes'])
					changed_restart	= true
			case 2
				if @state.get_settings_direct_connections() != @state['DIRECT_CONNECTIONS_ACCEPT']
					@state.set_settings_direct_connections(@state['DIRECT_CONNECTIONS_ACCEPT'])
					changed_no_restart	= true
				if @state.get_settings_number_of_intermediate_nodes() != 0
					@state.set_settings_number_of_intermediate_nodes(0)
					changed_restart	= true
		if changed_restart
			detox_chat_app.notify_success('Saved changes to desired anonymity setting, but restart is needed for changes to take effect', 3)
		else if changed_no_restart
			detox_chat_app.notify_success('Saved changes to desired anonymity setting', 3)
	_help_desired_anonymity : !->
		content	= """
			<p>This option allows easy configuration of Detox network parameters that impact anonymity.</p>
			<p>High is the default option, it uses recommended parameters that should result in high anonymity, while still supporting direct connections (which are not anonymous) for audio and video calls as well as file transfers.</p>
			<p>Strict is the same as High, but disables any non-anonymous communications and removes relevant elements from application UI.</p>
			<p>Low will try to make as little work as possible while still following Detox protocol, this drastically reduces anonymity, but makes connections and data transfers faster, also direct connections (which are not anonymous) for audio and video calls as well as file transfers will no longer require explicit confirmation before establishing.</p>
			<p>Custom would only be be present if any of advanced settings that impact anonymity were changed manually.</p>
		"""
		detox_chat_app.simple_modal(content)
	_desired_anonymity_custom : (desired_anonymity) ->
		desired_anonymity == 3
	_settings_additional_options_changed : (settings_additional_options) !->
		@settings_additional_options_string	= JSON.stringify(settings_additional_options, null, '  ')
	_settings_additional_options_blur : !->
		try
			settings_additional_options	= JSON.parse(@settings_additional_options_string)
			if JSON.stringify(@settings_additional_options) == JSON.stringify(settings_additional_options)
				return
			# TODO: Check if object structure is valid
			@state.set_settings_additional_options(settings_additional_options)
			detox_chat_app.notify_success('Saved changes to additional options setting', 3)
		catch
			detox_chat_app.notify_error('Additional options syntax error, changes were not saved', 3)
	_help_settings_additional_options : !->
		content	= """
			<p>This option allows to control the most detailed settings of Detox network and corresponds to the last argument of Core library's constructor.</p>
			<p>Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_announce_changed : !->
		if @settings_announce != @_bool_to_string(@state.get_settings_announce())
			@state.set_settings_announce(@settings_announce == '1')
			detox_chat_app.notify_success('Saved changes to announcement setting, but restart is needed for changes to take effect', 3)
	_help_settings_announce : !->
		content	= """
			<p>Announcement is a process of publishing own contact information to the network, so that contacts can find and connect to you.</p>
			<p>When turned off, you'll be in stealth mode, meaning that no one will be able to see if you're online, send messages or interact in any other way unless you initiate such interaction first.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_audio_notifications_changed : !->
		if @settings_audio_notifications != @_bool_to_string(@state.get_settings_audio_notifications())
			@state.set_settings_audio_notifications(@settings_audio_notifications == '1')
			detox_chat_app.notify_success('Saved changes to audio notifications setting', 3)
	_help_settings_audio_notifications : !->
		content	= """
			<p>Notifications like sending and receiving messages might be accompanied with short sound. Turn of if you don't like it.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_block_contact_requests_for_changed : !->
		settings_block_contact_requests_for	= @settings_block_contact_requests_for * 60 * 60 * 24 # In days
		if settings_block_contact_requests_for != @state.get_settings_block_contact_requests_for()
			@state.set_settings_block_contact_requests_for(settings_block_contact_requests_for)
			detox_chat_app.notify_success('Saved changes to block contacts request for setting', 3)
	_help_settings_block_contact_requests_for : !->
		content	= """
			<p>When you reject contact request, nothing is sent back to that contact.<br>
			This results in subsequent contacts requests being received even after rejection.</p>
			<p>This option makes your life better by blocking subsequent contacts requests after first rejection for some time, so that you're not annoyed by the same contact request all the time.<br>
			Changing this option will not affect already blocked contacts requests.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_bootstrap_nodes_changed : (settings_bootstrap_nodes) !->
		@settings_bootstrap_nodes_string	= JSON.stringify(settings_bootstrap_nodes, null, '  ')
	_settings_bootstrap_nodes_blur : !->
		try
			settings_bootstrap_nodes	= JSON.parse(@settings_bootstrap_nodes_string)
			if JSON.stringify(@settings_bootstrap_nodes) == JSON.stringify(settings_bootstrap_nodes)
				return
			# TODO: Check if object structure is valid
			@state.set_settings_bootstrap_nodes(settings_bootstrap_nodes)
			detox_chat_app.notify_success('Saved changes to bootstrap nodes setting, but restart is needed for changes to take effect', 3)
		catch
			detox_chat_app.notify_error('Bootstrap nodes syntax error, changes were not saved', 3)
	_help_settings_bootstrap_nodes : !->
		content	= """
			<p>Bootstrap nodes are special kind of nodes used during application startup in order to get information about other nodes in the network and establish initial connections with them.<br>
			These nodes are crucial for operation and should be selected carefully.<br>
			Bootstrap nodes that return misleading information cause anything from drastic reduction of anonymity to being unable to communicate with other nodes in the network.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_bucket_size_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_bucket_size()
			@state.set_settings_bucket_size(value)
			detox_chat_app.notify_success('Saved changes to bucket size setting, but restart is needed for changes to take effect', 3)
	_help_settings_bucket_size : !->
		content	= """
			<p>Bucket size is a data structure used in underlying Distributed Hash Table (DHT) implementation used in Detox network.</p>
			<p>Bigger number means more nodes will be stored, but this will also increase communication overhead.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_direct_connections_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_direct_connections()
			@state.set_settings_direct_connections(value)
			detox_chat_app.notify_success('Saved changes to direct connections setting', 3)
	_help_settings_direct_connections : !->
		content	= """
			<p>Direct connections (which are not anonymous) are used for audio and video calls as well as file transfers.<br>
			You can be prompted to accept direct connections before establishing or accept them unconditionally (dangerous for anonymity!), but in case you have no plans to use them, you can disable direct connections entirely, which will also hide relevant UI elements.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_experience_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_experience()
			@state.set_settings_experience(value)
			detox_chat_app.notify_success('Saved changes to user experience level setting', 3)
	_help_settings_experience : !->
		content	= """
			<p>Regular makes UI as simple as possible. Advanced enables more features and settings. Developer mode gives most control.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_help_changed : !->
		if @settings_help != @_bool_to_string(@state.get_settings_help())
			@state.set_settings_help(@settings_help == '1')
			detox_chat_app.notify_success('Saved changes to help setting', 3)
	_help_settings_help : !->
		content	= """
			<p>Help buttons, one of which you've just clicked, are useful when you just started using Detox Chat, but may annoy later.<br>
			Use this option to hide them if needed.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_ice_servers_changed : (settings_ice_servers) !->
		@settings_ice_servers_string	= JSON.stringify(settings_ice_servers, null, '  ')
	_settings_ice_servers_blur : !->
		try
			settings_ice_servers	= JSON.parse(@settings_ice_servers_string)
			if JSON.stringify(@settings_ice_servers) == JSON.stringify(settings_ice_servers)
				return
			# TODO: Check if object structure is valid
			@state.set_settings_ice_servers(settings_ice_servers)
			detox_chat_app.notify_success('Saved changes to ICE servers setting, but restart is needed for changes to take effect', 3)
		catch
			detox_chat_app.notify_error('ICE servers syntax error, changes were not saved', 3)
	_help_settings_ice_servers : !->
		content	= """
			<p>ICE servers are used during connections to other nodes in the network.</p>
			<p>There are two kinds of ICE servers: STUN and TURN.<br>
			STUN helps to figure out how to connect to this node from the outside if it is behind Network Address Translation (NAT) or firewall.<br>
			If connection is not possible, TURN server can act as relay to enable communication even behind restricted NAT or firewall.</p>
			<p>Most of the time ICE servers are crucial for operation and should be selected carefully.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_max_pending_segments_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_max_pending_segments()
			@state.set_settings_max_pending_segments(value)
			detox_chat_app.notify_success('Saved changes to max pending segments setting, but restart is needed for changes to take effect', 3)
	_help_settings_max_pending_segments : !->
		content	= """
			<p>Pending segments is a low-level state of segments from transport layer of Detox network implementation that appear during routing paths construction.</p>
			<p>Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_number_of_intermediate_nodes_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_number_of_intermediate_nodes()
			@state.set_settings_number_of_intermediate_nodes(value)
			detox_chat_app.notify_success('Saved changes to number of intermediate nodes setting, but restart is needed for changes to take effect', 3)
	_help_settings_number_of_intermediate_nodes : !->
		content	= """
			<p>Intermediate nodes are nodes between this node and interested target node, used for routing paths creation in transport layer of Detox network implementation.</p>
			<p>More intermediate nodes means longer routing path and slower its creation. Lower numbers decrease anonymity, numbers higher than 3 are generally considered to be redundant.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_number_of_introduction_nodes_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_number_of_introduction_nodes()
			@state.set_settings_number_of_introduction_nodes(value)
			detox_chat_app.notify_success('Saved changes to number of introduction nodes setting, but restart is needed for changes to take effect', 3)
	_help_settings_number_of_introduction_nodes : !->
		content	= """
			<p>Introduction nodes are nodes to which announcement is made.</p>
			<p>More than one node is recommended to ensure good reliability of incoming connections, but very high numbers are redundant.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_online_changed : !->
		if @settings_online != @_bool_to_string(@state.get_settings_online())
			@state.set_settings_online(@settings_online == '1')
			detox_chat_app.notify_success('Saved changes to online setting, but restart is needed for changes to take effect', 3)
	_help_settings_online : !->
		content	= """
			<p>If not online then on next start application will not try to connect to Detox network and related functionality will not work properly.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_packets_per_second_changed : (value) !->
		value	= parseInt(value)
		if value != @state.get_settings_packets_per_second()
			@state.set_settings_packets_per_second(value)
			detox_chat_app.notify_success('Saved changes to packets per second setting, but restart is needed for changes to take effect', 3)
	_help_settings_packets_per_second : !->
		content	= """
			<p>Detox network sends data at fixed rate on each opened connection regardless of how much bandwidth is actually utilized, this option specifies how may packets of 512 bytes will be sent on each link during one second.</p>
			<p>Bigger number means higher peak throughput and lower latencies (to some degree, as these can be bottlenecked by other nodes in particular routing path), but significantly increases requirements to Internet connection.<br>
			You may increase or decrease this option slightly, but don't go too far unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_reconnects_intervals_changed : (settings_reconnects_intervals) !->
		@settings_reconnects_intervals_string	= JSON.stringify(settings_reconnects_intervals, null, '  ')
	_settings_reconnects_intervals_blur : !->
		try
			settings_reconnects_intervals	= JSON.parse(@settings_reconnects_intervals_string)
			if JSON.stringify(@settings_reconnects_intervals) == JSON.stringify(settings_reconnects_intervals)
				return
			# TODO: Check if object structure is valid
			@state.set_settings_reconnects_intervals(settings_reconnects_intervals)
			detox_chat_app.notify_success('Saved changes to reconnects intervals setting', 3)
		catch
			detox_chat_app.notify_error('Reconnects intervals syntax error, changes were not saved', 3)
	_help_settings_reconnects_intervals : !->
		content	= """
			<p>When you need to connect to one of your contacts, connection will not always succeed.</p>
			<p>This option controls time intervals (in seconds) between connection attempts.</p>
			<p>First number is max number of attempts and second is number is delay for it. More attempts is made, larger delays become.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		detox_chat_app.simple_modal(content)
	_settings_send_ctrl_enter_changed : !->
		if @settings_send_ctrl_enter != @_bool_to_string(@state.get_settings_send_ctrl_enter())
			@state.set_settings_send_ctrl_enter(@settings_send_ctrl_enter == '1')
			detox_chat_app.notify_success('Saved changes to send message with setting', 3)
	_help_settings_send_ctrl_enter : !->
		content	= """
			<p>Either send message with Ctrl+Enter and use Enter for new line or use Enter to send message and Shift+Enter for new line.</p>
		"""
		detox_chat_app.simple_modal(content)
	_backup : !->
		# TODO: Probably restart into offline mode and then do backup
		@state.get_as_blob().then (blob) !->
			date		= new Date
			date		= [date.getFullYear(), date.getMonth() + 1, date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds()].join('-')
			url			= URL.createObjectURL(blob)
			file_name	= "detox-chat-backup-#date.bin"
			content		= """
				<p>Your backup is ready: <a href="#url" download="#file_name">Download</a></p>
			"""
			detox_chat_app.simple_modal(content)
	_restore : !->
		# TODO: Probably restart into offline mode and then do restoration
		document.createElement('input')
			..type		= 'file'
			..accept	= '.bin'
			..addEventListener('change', (e) !~>
				@state.set_from_blob(e.target.files[0])
			)
			..click()
	_help_backup_restore_data : !->
		content	= """
			<p>This will backup your contacts, settings and messages history.</p>
			<p>If you're migrating from one browser to another or one machine to another, this will allow you to backup your data here and restore them somewhere else.</p>
			<p>NOTE: You can't have the same account on 2 machines/browsers yet (this will not work properly or at all, don't try or you'll be very disappointed with consequences).</p>
			<p>Always have only one instance and always use fresh backup or you're risking not being able to connect with some of your contacts.</p>
		"""
		detox_chat_app.simple_modal(content)
	_remove_all_of_the_data : !->
		content	= """
			<p>Are really, REALLY sure you want to proceed with deletion?</p>
			<p>WARNING: This operation can't be undone!</p>
		"""
		csw.functions.confirm(content, !~>
			@state.delete_data()
			if window.detox_service_worker_registration
				caches.keys()
					.then (keys) ->
						Promise.all(
							for key in keys
								caches.delete(key)
						)
					.then ->
						detox_service_worker_registration.unregister()
					.then !->
						detox_chat_app.notify_success('All of the data removed successfully, you can exit now')
			else
				detox_chat_app.notify_success('All of the data removed successfully, you can exit now')
		)
	_help_remove_all_of_the_data : !->
		content	= """
			<p>WARNING: This operation can't be undone!</p>
			<p>This will remove all of the contacts, messages history, settings and any other data stored by this application (including unregistering Service Worker and cleaning its caches), after which application will close itself.</p>
			<p>Make sure to backup any useful data stored in this application before you proceed with deletion!</p>
		"""
		detox_chat_app.simple_modal(content)
)
