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
									csw.functions.notify('Application was updated in background and new version ready to be used, restart to enjoy it', 'success', 'right', 10)
								else
									csw.functions.notify('Website was updated in background and new version ready to be used, refresh page to enjoy it', 'success', 'right', 10)
							else
								if IN_APP
									csw.functions.notify('Application is ready to work offline', 'success', 'right', 10)
								else
									csw.functions.notify('Website is ready to work offline', 'success', 'right', 10)
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
