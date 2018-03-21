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
		nickname			:
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
			@nickname	= state.get_nickname()
			update_secrets()
			state
				.on('nickname_changed', (new_nickname) !~>
					if @nickname != new_nickname
						@nickname	= new_nickname
				)
				.on('secrets_changed', update_secrets)
	_nickname_changed : !->
		if @nickname != @_state_instance.get_nickname()
			@_state_instance.set_nickname(@nickname)
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
					<label>Secret length (1..32):</label>
					<label>
						<csw-input-text>
							<input type="number" id="length" min="1" max="32" value="4">
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
	_help : !->
		content	= """
			<p>Secrets are used as anti-spam system. You can create different secrets for different purposes.<br>
			Each time you have incoming contact request, you'll see which secret was used.<br>
			For instance, you can create a secret for conference and know who is connecting to you before you accept contact request.</p>

			<p>For contact requests you need to share ID with secret.<br>
			Plain ID without secret will not result in visible contact request, but if you and your interlocutor add each other to contacts list explicitly, you'll be connected and able to communicate.</p>
		"""
		csw.functions.simple_modal(content)
)
