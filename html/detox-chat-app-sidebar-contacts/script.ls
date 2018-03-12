/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-contacts'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		contacts	: Array
	ready : !->
		<~! @_state_instance_ready.then
		state		= @_state_instance
		@contacts	= state.get_contacts()
		state
			.on('contacts_changed', !~>
				@contacts	= state.get_contacts()
			)
	_set_active_contact : (e) !->
		@_state_instance.set_ui_active_contact(e.model.item[0])
)
