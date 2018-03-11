/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
window.{}detox-chat-app.{}behaviors
	..'state' =
		properties	:
			chat-id	:
				type	: String
				value	: 'detox-chat-app'
		ready : !->
			@'_state_ready'	= require(['@detox/chat', 'state'])
				.then ([detox-chat, state]) !~>
					@_state_instance	= state['get_instance'](@chat-id)
					if !@_state_instance['ready']()
						csw['functions']['notify']("Previous state was not found, new identity generated", 'warning')
						@_state_instance['set_seed'](detox-chat['generate_seed']())
