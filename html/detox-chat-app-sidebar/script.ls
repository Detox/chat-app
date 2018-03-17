/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		settings_announce	:
			observer	: '_settings_announce_changed'
			type		: Number
	ready : !->
		<~! @_state_instance_ready.then
		state				= @_state_instance
		@settings_announce	= @_bool_to_int(state.get_settings_announce())
		state
			.on('settings_announce_changed', (new_settings_announce) !~>
				if @settings_announce !~= new_settings_announce
					@settings_announce	= @_bool_to_int(new_settings_announce)
			)
	_bool_to_int : (value) ->
		if value then 1 else 0
	_settings_announce_changed : !->
		if @settings_announce !~= @_state_instance.get_settings_announce()
			@_state_instance.set_settings_announce(@settings_announce ~= 1)
)
