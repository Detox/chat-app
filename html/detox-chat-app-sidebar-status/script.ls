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
		online		:
			type	: Boolean
			value	: false
		announced	:
			type	: Boolean
			value	: false
	ready : !->
		<~! @_state_instance_ready.then
		state	= @_state_instance
		state
			.on('online_changed', (new_online) !~>
				@online	= new_online
			)
			.on('announced_changed', (new_announced) !~>
				@announced	= new_announced
			)
	_online : (online) ->
		if online
			'Online'
		else
			'Offline'
	_announced : (announced) ->
		if announced
			'Yes'
		else
			'No'
)
