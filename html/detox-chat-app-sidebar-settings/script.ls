/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-settings'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		settings_announce					:
			observer	: '_settings_announce_changed'
			type		: String
		settings_block_contact_requests_for	:
			observer	: '_settings_block_contact_requests_for_changed'
			type		: Number
		bootstrap_nodes						:
			observer	: '_settings_bootstrap_nodes_changed'
			type		: Object
		bootstrap_nodes_string	: String
	ready : !->
		<~! @_state_instance_ready.then
		state									= @_state_instance
		@settings_announce						= @_bool_to_string(state.get_settings_announce())
		@settings_block_contact_requests_for	= state.get_settings_block_contact_requests_for() / 60 / 60 / 24 # In days
		@bootstrap_nodes						= state.get_settings_bootstrap_nodes()
		state
			.on('settings_announce_changed', (new_settings_announce) !~>
				new_settings_announce	= @_bool_to_string(new_settings_announce)
			)
			.on('settings_block_contact_requests_for_changed', !~>
				@block_contact_requests_for	= state.get_settings_block_contact_requests_for() / 60 / 60 / 24 # In days
			)
			.on('settings_bootstrap_nodes_changed', !~>
				@bootstrap_nodes	= state.get_settings_bootstrap_nodes()
			)
	_bool_to_string : (value) ->
		if value then '1' else '0'
	_settings_announce_changed : !->
		if @settings_announce != @_bool_to_string(@_state_instance.get_settings_announce())
			@_state_instance.set_settings_announce(@settings_announce == '1')
			csw.functions.notify('Saved changes to announcement setting', 'success', 'right', 3)
	_help_settings_announce : !->
		content	= """
			<p>Announcement is a process of publishing own contact information to the network, so that contacts can find and connect to this node.</p>
			<p>It is possible to use Detox Chat without announcing itself to the network.<br>
			In this case incoming connections from contacts will not be possible, but it will be possible to initiate connection to other contacts if needed.</p>
		"""
		csw.functions.simple_modal(content)
	_settings_block_contact_requests_for_changed : !->
		if @settings_block_contact_requests_for != @_state_instance.get_settings_block_contact_requests_for()
			@_state_instance.set_settings_block_contact_requests_for(@settings_block_contact_requests_for) * 60 * 60 * 24 # In days
			csw.functions.notify('Saved changes to block contacts request for setting', 'success', 'right', 3)
	_help_settings_block_contact_requests_for : !->
		content	= """
			<p>When you reject contact request, nothing is sent back to that contact.<br>
			This results in subsequent contacts requests being received even after rejection.</p>
			<p>This option makes your life better by blocking subsequent contacts requests after first rejection for some time, so that you're not annoyed by the same contact request all the time.</p>
		"""
		csw.functions.simple_modal(content)
	_settings_bootstrap_nodes_changed : (bootstrap_nodes) !->
		@bootstrap_nodes_string	= JSON.stringify(bootstrap_nodes, null, "\t")
	_bootstrap_node_blur : !->
		try
			bootstrap_nodes	= JSON.parse(@bootstrap_nodes_string)
			if JSON.stringify(@bootstrap_nodes) == JSON.stringify(bootstrap_nodes)
				return
			# TODO: Check if object structure is valid
			@_state_instance.set_settings_bootstrap_nodes(bootstrap_nodes)
			csw.functions.notify('Saved changes to bootstrap nodes setting', 'success', 'right', 3)
		catch
			csw.functions.notify('Bootstrap nodes syntax error, changes were not saved', 'error', 'right', 3)
	_help_settings_bootstrap_nodes : !->
		content	= """
			<p>Bootstrap nodes are special kind of nodes used during application startup in order to get information about other nodes in the network and establish initial connections with them.<br>
			These nodes are crucial for operation and should be selected carefully.<br>
			Bootstrap nodes that return misleading information cause anything from drastic reduction of anonymity to being unable to communicate with other nodes in the network.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		csw.functions.simple_modal(content)
)
