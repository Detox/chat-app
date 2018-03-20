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
		add_contact			:
			type	: Boolean
			value	: false
		contacts			:
			type	: Array
			value	: []
		contacts_requests	:
			type	: Array
			value	: []
		new_contact_id		: String
		new_contact_name	: String
		online_contacts		:
			type	: Object
		ui_active_contact	:
			type	: Object
	ready : !->
		Promise.all([
			require(['@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-utils]]) !~>
			ArraySet			= detox-utils.ArraySet

			state				= @_state_instance
			@contacts			= state.get_contacts()
			@online_contacts	= ArraySet(state.get_online_contacts())
			@contacts_requests	= state.get_contacts_requests()
			@ui_active_contact	= ArraySet([state.get_ui_active_contact() || new Uint8Array(0)])
			state
				.on('contacts_changed', !~>
					# TODO: Sort contacts
					@contacts	= state.get_contacts()
				)
				.on('online_contacts_changed', !~>
					@online_contacts	= ArraySet(state.get_online_contacts())
				)
				.on('contacts_requests_changed', !~>
					# TODO: Sort contacts
					contacts_requests	= state.get_contacts_requests()
					@contacts_requests	= contacts_requests
				)
				.on('ui_active_contact_changed', !~>
					@ui_active_contact	= ArraySet([state.get_ui_active_contact() || new Uint8Array(0)])
				)
	_hide_header : (list, add_contact) ->
		!list.length || add_contact
	_add_contact : !->
		@add_contact	= true
	_add_contact_confirm : !->
		([detox-chat, detox-crypto, detox-utils])	<~! require(['@detox/chat', '@detox/crypto', '@detox/utils']).then
		try
			[public_key, remote_secret]	= detox-chat.id_decode(@new_contact_id)
			own_public_key				= detox-crypto.create_keypair(@_state_instance.get_seed()).ed25519.public
			if detox-utils.are_arrays_equal(public_key, own_public_key)
				csw.functions.notify('Adding yourself to contacts is not supported', 'error', 'right', 3)
				return
			existing_contact	= @_state_instance.get_contact(public_key)
			if existing_contact
				csw.functions.notify("Not added: this contact is already in contacts list under nickname <i>#{existing_contact.nickname}</i>", 'warning', 'right', 3)
				return
			@_state_instance.add_contact(public_key, @new_contact_name, remote_secret)
			csw.functions.notify('Contact added', 'success', 'right', 3)
			@add_contact		= false
			@new_contact_id		= ''
			@new_contact_name	= ''
		catch
			csw.functions.notify('Incorrect ID, check for typos and try again', 'error', 'right', 3)
	_add_contact_cancel : !->
		@add_contact	= false
	_set_active_contact : (e) !->
		@_state_instance.set_ui_active_contact(e.model.item.id)
	_del_contact : (e) !->
		csw.functions.confirm("<h3>Are you sure you want to delete contact <i>#{e.model.item.nickname}</i>?</h3>", !~>
			@_state_instance.del_contact(e.model.item.id)
		)
		e.stopPropagation()
	_accept_contact_request : (e) !->
		state	= @_state_instance

		item	= e.model.item
		content	= """
			<h3>What do you want to do with contact request from <i>#{item.name}</i> that used secret <i>#{item.secret_name}</i>?</h3>
			<csw-button primary><button id="accept">Accept</button></csw-button>
			<csw-button><button id="reject">Reject</button></csw-button>
			<csw-button><button id="cancel">Cancel</button></csw-button>
		"""
		modal	= csw.functions.simple_modal(content)
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
	_online : (contact_id, online_contacts) ->
		online_contacts.has(contact_id)
	_selected : (contact_id, ui_active_contact) ->
		ui_active_contact.has(contact_id)
)
