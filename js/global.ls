/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const IN_APP = location.search == '?home'
/**
 * Force passive listeners on in Polymer
 */
Polymer.setPassiveTouchGestures(true)
/**
 * Register service worker
 */
if ('serviceWorker' of navigator) && window.detox_sw_path
	([detox-chat]) <-! require(['@detox/chat']).then
	# Make sure WebAssembly stuff are loaded
	<~! detox-chat.ready
	navigator.serviceWorker.register(detox_sw_path)
		.then (registration) !->
			registration.onupdatefound = !->
				installingWorker = registration.installing

				installingWorker.onstatechange = !->
					switch installingWorker.state
						case 'installed'
							if navigator.serviceWorker.controller
								if IN_APP
									detox_chat_app.notify_success('Application was updated in background and new version ready to be used, restart to enjoy it', 10)
								else
									detox_chat_app.notify_success('Website was updated in background and new version ready to be used, refresh page to enjoy it', 10)
							else
								if IN_APP
									detox_chat_app.notify_success('Application is ready to work offline', 10)
								else
									detox_chat_app.notify_success('Website is ready to work offline', 10)
						case 'redundant'
							console.error('The installing service worker became redundant')
			window.detox_service_worker_registration = registration
		.catch (e) !->
			console.error('Error during service worker registration:', e)
/**
 * Requesting persistent storage, so that data will not be lost unexpectedly under storage pressure
 */
if navigator.storage?.persist
	navigator.storage.persisted().then (persistent) !->
		if !persistent
			console.info 'Persistent storage is not yet granted, requesting...'
			navigator.storage.persist().then (granted) !->
				if granted
					console.info 'Persistent storage granted'
				else
					console.warn 'Persistent storage denied, data may be lost under storage pressure'
else
	console.warn 'Persistent storage not supported, data may be lost under storage pressure'

desktop_notification_permission_requested	= false
/**
 * @param {string}		status
 * @param {string}		title
 * @param {string=}		details
 * @param {number=}		timeout
 * @param {!Function}	onclick
 */
!function page_notification (status, title, details, timeout, onclick)
	body	= document.createElement('div')
	if details
		body.innerHTML						= '<b></b><br>'
		body.querySelector('b').textContent	= title
		body.insertAdjacentText('beforeend', details)
	else
		body.insertAdjacentText('beforeend', title)
	notification	= csw.functions.notify(body, status, 'right', timeout)
	if onclick
		notification.addEventListener('click', onclick)
/**
 * @param {string}		title
 * @param {string=}		details
 * @param {number=}		timeout
 * @param {!Function}	onclick
 */
!function desktop_notification (title, details, timeout, onclick)
	notification	= new Notification(title, {
		body	: details
	})
	if onclick
		notification.addEventListener('click', onclick)
	if timeout
		setTimeout (!->
			notification.close()
		), 1000 * timeout
/**
 * @param {string}	status
 * @param {string}	title
 * @param {string=}	details
 * @param {string=}	timeout
 *
 * @return {!Promise}
 */
function notify (status, title, details, timeout)
	new Promise (resolve) !->
		if typeof details == 'number'
			timeout	:= details
			details	:= ''
		if document.hasFocus() || !Notification || Notification.permission == 'denied'
			page_notification(status, title, details, timeout, resolve)
		else if Notification.permission == 'default'
			if !desktop_notification_permission_requested
				desktop_notification_permission_requested	:= true
				if IN_APP
					message	= "Application tried to show you a system notification while was inactive, but you have to grant permission for that first, do that after clicking on this notification"
				else
					message	= "Website tried to show you a desktop notification while was inactive, but you have to grant permission for that first, do that after clicking on this notification"
				csw.functions.notify(message, 'warning', 'right')
					..addEventListener(
						'click'
						!->
							Notification.requestPermission().then (permission) !->
								switch permission
									case 'granted'
										csw.functions.notify('You will no longer miss important notifications 😉', 'success', 'right', 3)
									case 'denied'
										csw.functions.notify('In case you change your mind, desktop notifications can be re-enabled in browser settings 😉', 'success', 'right', 5)
					)
			page_notification(status, title, details, timeout, resolve)
		else
			desktop_notification(title, details, timeout, resolve)

window.{}detox_chat_app
	..notify_error		= ->
		notify('error', ...&)
	..notify			= ->
		notify('', ...&)
	..notify_success	= ->
		notify('success', ...&)
	..notify_warning	= ->
		notify('warning', ...&)
	..play_sound		= (file) !->
		# Song will not play until user interacts, but we may try to play it, so let's not throw an error
		try
			new Audio(file)
				..play()
	..simple_modal		= (content) ->
		current_time	= +(new Date)
		modal			= csw.functions.simple_modal(content)
			..addEventListener('close', !->
				if history.state == current_time
					history.back()
			)
		if IN_APP
			history.pushState(current_time, '', '#modal')
			window.addEventListener(
				'popstate'
				!->
					modal.close()
				{once: true}
			)
		modal
	..installation_prompt = ->
		if IN_APP
			return
		if localStorage.installation_prompt_timeout
			if +localStorage.installation_prompt_timeout > +(new Date)
				# Do not annoy user with this prompt
				return
			# Do not show prompt for one month when called subsequent times
			localStorage.installation_prompt_timeout	= +(new Date) + 60 * 60 * 24 * 30
		else
			# Do not show prompt for one week when called first time
			localStorage.installation_prompt_timeout	= +(new Date) + 60 * 60 * 24 * 7
		installation_prompt_event.then (event) !->
			csw.functions.notify("""
				If you use this application often, consider to install it for easy access:<br><br>
				<csw-group><csw-button primary><button>Install</button></csw-button><csw-button><button>Ignore</button></csw-button></csw-group>
			""", 'right')
				.querySelector('csw-button[primary]>button')
					.addEventListener('click', !->
						event.prompt()
					)
# Handle back hardware button in application mode, allow 2 seconds to press back button or leave application open
if IN_APP
	history.pushState({loaded: true}, '')
	addEventListener('popstate', !->
		if !history.state?.loaded
			csw.functions.notify('Press one more time to exit', 'bottom', 2)
			setTimeout (!->
				history.pushState({loaded: true}, '')
			), 2000
	)
else
	installation_prompt_event	= new Promise (resolve) !->
		window.addEventListener('beforeinstallprompt', (event) !->
			# Prevent Chromium <= 67 from automatically showing the prompt
			event.preventDefault()
			# Resolve promise with event so that it can be used later if needed
			resolve(event)
		)
