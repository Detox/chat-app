/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
/**
 * Force passive listeners on in Polymer
 */
Polymer.setPassiveTouchGestures(true)
/**
 * Register service worker
 */
if ('serviceWorker' of navigator) && window.detox_sw_path
	# Wait for icons font to load, since it is one of the last things loading and we don't want to get it from the network twice
	# TODO: Edge doesn't support this yet, remove check when it does
	if document.fonts
		document.fonts.load('bold 0 "Font Awesome 5 Free"').then(register_sw)
	else
		register_sw()
!function register_sw
	([detox-chat]) <-! require(['@detox/chat']).then
	# Make sure WebAssembly stuff are loaded too
	<~! detox-chat.ready
	navigator.serviceWorker.register(detox_sw_path)
		.then (registration) !->
			registration.onupdatefound = !->
				installingWorker = registration.installing

				installingWorker.onstatechange = !->
					switch installingWorker.state
						case 'installed'
							if navigator.serviceWorker.controller
								csw.functions.notify('New application version available, refresh page or restart app to see updated version', 'success', 'right', 10)
							else
								csw.functions.notify('Application is ready to work offline', 'success', 'right', 10)
						case 'redundant'
							console.error('The installing service worker became redundant.')
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
