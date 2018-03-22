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
		settings_announce		:
			observer	: '_settings_announce_changed'
			type		: String
		bootstrap_nodes			:
			observer	: '_settings_bootstrap_nodes_changed'
			type		: Object
		bootstrap_nodes_string	: String
	ready : !->
		<~! @_state_instance_ready.then
		state				= @_state_instance
		@settings_announce	= @_bool_to_string(state.get_settings_announce())
		@bootstrap_nodes	= state.get_settings_bootstrap_nodes()
		state
			.on('settings_announce_changed', (new_settings_announce) !~>
				new_settings_announce	= @_bool_to_string(new_settings_announce)
				if @settings_announce != new_settings_announce
					@settings_announce	= new_settings_announce
			)
			.on('settings_bootstrap_nodes_changed', (new_settings_announce) !~>
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
			<p>It is possible to use Detox Chat without announcing itself to the network.<br>
			In this case incoming connections from contacts will not be possible, but it will be possible to initiate connection to other contacts if needed.</p>
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
			<p>Bootstrap nodes are used on start in order to get information about other nodes in the network.<br>
			These nodes are crucial for operation and should be selected carefully, as they can return misleading information.<br>
			Bad bootstrap nodes may result in anything from drastic reduction in anonymity to being unable to communicate with other nodes in the network.<br>
			Do not change this setting unless you know what you're doing.</p>
		"""
		csw.functions.simple_modal(content)
)
