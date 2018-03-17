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
				# TODO: Sort contacts
				@contacts	= state.get_contacts()
			)
	_set_active_contact : (e) !->
		@_state_instance.set_ui_active_contact(e.model.item.id)
	_add_contact : !->
		modal	= csw.functions.confirm("""
			<csw-form>
				<form>
					<label>
						<csw-textarea>
							<textarea id="id" placeholder="ID"></textarea>
						</csw-textarea>
					</label>
					<label>
						<csw-textarea>
							<textarea id="name" placeholder="Name (optional)"></textarea>
						</csw-textarea>
					</label>
				</form>
			</csw-form>
		""", !~>
			id_base58		= modal.querySelector('#id').value
			name			= modal.querySelector('#name').value
			([detox-chat, detox-utils])	<~! require(['@detox/chat', '@detox/utils']).then
			try
				# TODO: Secret is currently unused
				[public_key, secret]	= detox-chat.id_decode(id_base58)
				if !name
					name	= detox-utils.base58_encode(public_key)
				@_state_instance.add_contact(public_key, name)
		)
)
