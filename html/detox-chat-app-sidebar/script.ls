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
		id_base58	: String
		name		:
			observer	: '_name_changed'
			type		: String
	ready : !->
		Promise.all([
			require(['@detox/crypto', '@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-crypto, detox-utils]]) !~>
			<~! detox-crypto.ready
			state		= @_state_instance
			@id_base58	= detox-utils['base58_encode'](
				detox-crypto.create_keypair(state.get_seed()).ed25519.public
			)
			@name		= state.get_name()
			state.on('name_changed', !~>
				new_name	= state.get_name()
				if @name != new_name
					@name	= new_name
			)
	_name_changed : !->
		if @name != @_state_instance.get_name()
			@_state_instance.set_name(@name)
)
