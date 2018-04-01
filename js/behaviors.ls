/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper
	state =
		properties	:
			chat-id	:
				type	: String
				value	: 'detox-chat-app'
		created : !->
			@_state_instance_ready	= require(['@detox/chat', 'js/state'])
				.then ([detox-chat, state]) !~>
					@_state_instance	= state.get_instance(@chat-id)
					if !@_state_instance.ready()
						csw.functions.notify("Previous state was not found, new identity generated", 'warning', 'right', 60)
						@_state_instance.set_seed(detox-chat.generate_seed())
						@_state_instance.add_secret(detox-chat.generate_secret().slice(0, 4), 'Default secret')
	experience_level = [
		state
		advanced_user	:
			type	: Boolean
			value	: false
		developer		:
			type	: Boolean
			value	: false
		ready : !->
			<~! @_state_instance_ready.then
			state			= @_state_instance
			@advanced_user	= state.get_settings_experience() >= 1
			@developer		= state.get_settings_experience() == 2
			state
				.on('settings_experience_changed', (experience) !~>
					@advanced_user	= experience >= 1
					@developer		= experience == 2
				)
	]
	# TODO: Instead of behavior and separate elements with callbacks, it would be nice to have a custom element for help buttons
	help = [
		state
		properties	:
			help	: Boolean
		ready : !->
			@_state_instance_ready.then !~>
				@help	= @_state_instance.get_settings_help()
				@_state_instance.on('settings_help_changed', (@help) !~>)
	]
	{state, experience_level, help}

define(Wrapper)
