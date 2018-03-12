/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-dialogs'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		active_contact	:
			type	: Boolean
			value	: false
		messages		: Array
	ready : !->
		<~! @_state_instance_ready.then
		state	= @_state_instance
		state
			.on('ui_active_contact_changed', !~>
				@active_contact	= true
				@messages		= state.get_contact_messages(state.get_ui_active_contact())
			)
			.on('contact_messages_changed', !~>
				@messages		= state.get_contact_messages(state.get_ui_active_contact())
			)
)
