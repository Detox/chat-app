/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-profile'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		id_base58			: String
		name				:
			observer	: '_nickname_changed'
			type		: String
	ready : !->
		Promise.all([
			require(['@detox/chat', '@detox/crypto'])
			@_state_instance_ready
		]).then ([[detox-chat, detox-crypto]]) !~>
			<~! detox-crypto.ready
			<~! detox-chat.ready
			id_encode	= detox-chat.id_encode

			state		= @_state_instance

			!~function update_secrets
				@secrets	= for secret in state.get_secrets()
					{
						id		: id_encode(public_key, secret.secret)
						name	: secret.name
					}

			public_key	= detox-crypto.create_keypair(state.get_seed()).ed25519.public
			@id_base58	= id_encode(public_key, new Uint8Array(0))
			@name		= state.get_nickname()
			update_secrets()
			state
				.on('nickname_changed', (new_name) !~>
					if @name != new_name
						@name	= new_name
				)
				.on('secrets_changed', update_secrets)
	_nickname_changed : !->
		if @name != @_state_instance.get_nickname()
			@_state_instance.set_nickname(@name)
	_id_click : (e) !->
		e.target.select()
	_add_secret : !->
		content	= """
			<csw-form>
				<form>
					<label>Secret name:</label>
					<label>
						<csw-input-text>
							<input id="name">
						</csw-input-text>
					</label>
					<label>Secret length:</label>
					<label>
						<csw-input-text>
							<input id="length" min="1" max="32" value="4">
						</csw-input-text>
					</label>
				</form>
			</csw-form>
		"""
		modal	= csw.functions.confirm(content, !~>
			name	= modal.querySelector('#name').value
			if !name
				return
			length	= modal.querySelector('#length').value
			([detox-chat])	<~! require(['@detox/chat']).then
			secret	= detox-chat.generate_secret().slice(0, length)
			@_state_instance.add_secret(secret, name)
		)
)
