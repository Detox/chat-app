/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-status'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		network_connected	:
			type	: Boolean
			value	: false
		network_state		:
			computed	: '_network_state(network_connected)'
			type		: String
		announced			:
			type	: Boolean
			value	: false
		announced_string	:
			computed	: '_announced_string(announced)'
			type		: String
	ready : !->
		Promise.all([
			require(['state'])
			@_state_instance_ready
		]).then ([[detox-state]]) !~>
			state	= @_state_instance
			state
				.on('network_state_updated', !~>
					@network_connected	= state.get_network_state() == detox-state.State.NETWORK_STATE_ONLINE
				)
				.on('announcement_state_updated', !~>
					@announced	= state.get_announcement_state() == detox-state.State.ANNOUNCEMENT_STATE_ANNOUNCED
				)
	_network_state : (network_connected) ->
		if network_connected
			'Online'
		else
			'Offline'
	_announced_string : (announced) ->
		if announced
			'Yes'
		else
			'No'
)
