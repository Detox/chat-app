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
		contacts			: Array
		contacts_requests	:
			type	: Array
			value	: []
	ready : !->
		<~! @_state_instance_ready.then
		state				= @_state_instance
		@contacts			= state.get_contacts()
		@contacts_requests	= state.get_contacts_requests()
		state
			.on('contacts_changed', !~>
				# TODO: Sort contacts
				@contacts	= state.get_contacts()
			)
			.on('contacts_requests_changed', !~>
				# TODO: Sort contacts
				contacts_requests	= state.get_contacts_requests()
				@contacts_requests	= contacts_requests
			)
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
			([detox-chat])	<~! require(['@detox/chat']).then
			try
				[public_key, remote_secret]	= detox-chat.id_decode(id_base58)
				@_state_instance.add_contact(public_key, name, remote_secret)
		)
	_set_active_contact : (e) !->
		@_state_instance.set_ui_active_contact(e.model.item.id)
	_accept_contact_request : (e) !->
		item	= e.model.item
		modal	= csw.functions.simple_modal("""
			<h3>What do you want to do with contact request from <i>#{item.name}</i> that used secret <i>#{item.secret_name}</i>?</h3>
			<csw-button primary><button id="accept">Accept</button></csw-button>
			<csw-button><button id="reject">Reject</button></csw-button>
			<csw-button><button id="cancel">Cancel</button></csw-button>
		""")
		modal.querySelector('#accept').addEventListener('click', !->
			state.add_contact(item.id, '', new Uint8Array(0))
			state.del_contact_request(item.id)
			modal.close()
		)
		modal.querySelector('#reject').addEventListener('click', !->
			state.del_contact_request(item.id)
			modal.close()
		)
		modal.querySelector('#cancel').addEventListener('click', !->
			modal.close()
		)
)
