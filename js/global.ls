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
		.catch (e) !->
			console.error('Error during service worker registration:', e)
/**
 * Requesting persistent storage, so that data will not be lost unexpectedly under storage pressure
 */
if navigator.storage?.persist?
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
 * @param {string}	status
 * @param {string}	title
 * @param {string=}	details
 * @param {string=}	timeout
 */
!function page_notification (status, title, details, timeout)
	body	= document.createElement('div')
	if details
		body.innerHTML						= '<b></b><br>'
		body.querySelector('b').textContent	= title
		body.insertAdjacentText('beforeend', details)
	else
		body.insertAdjacentText('beforeend', title)
	csw.functions.notify(body, status, 'right', timeout)
/**
 * @param {string}	title
 * @param {string=}	details
 * @param {string=}	timeout
 */
!function desktop_notification (title, details, timeout)
	notification	= new Notification(title, {
		body	: details
	})
	if timeout
		setTimeout (!->
			notification.close()
		), 1000 * timeout
/**
 * @param {string}	status
 * @param {string}	title
 * @param {string=}	details
 * @param {string=}	timeout
 */
!function notify (status, title, details, timeout)
	if typeof details == 'number'
		timeout	= details
		details	= ''
	if !document.hidden || !Notification || Notification.permission == 'denied'
		page_notification(status, title, details, timeout)
	else if Notification.permission == 'default'
		if !desktop_notification_permission_requested
			desktop_notification_permission_requested	= true
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
					{once: true}
				)
		page_notification(status, title, details, timeout)
	else
		desktop_notification(title, details, timeout)

window.{}detox_chat_app
	..notify_error		= !->
		notify('error', ...&)
	..notify			= !->
		notify('', ...&)
	..notify_success	= !->
		notify('success', ...&)
	..notify_warning	= !->
		notify('warning', ...&)
