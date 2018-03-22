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
		settings_announce	:
			observer	: '_settings_announce_changed'
			type		: String
	ready : !->
		<~! @_state_instance_ready.then
		state				= @_state_instance
		@settings_announce	= @_bool_to_string(state.get_settings_announce())
		state
			.on('settings_announce_changed', (new_settings_announce) !~>
				new_settings_announce	= @_bool_to_string(new_settings_announce)
				if @settings_announce != new_settings_announce
					@settings_announce	= new_settings_announce
			)
	_bool_to_string : (value) ->
		if value then '1' else '0'
	_settings_announce_changed : !->
		if @settings_announce != @_bool_to_string(@_state_instance.get_settings_announce())
			@_state_instance.set_settings_announce(@settings_announce == '1')
	_help_settings_announce : !->
		content	= """
			<p>It is possible to use Detox Chat without announcing itself to the network.<br>
			In this case incoming connections from contacts will not be possible, but it will be possible to initiate connection to other contacts if needed.</p>
		"""
		csw.functions.simple_modal(content)
)
