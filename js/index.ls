/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
ready = new Promise (resolve) !->
	if window.WebComponents
		resolve()
	else
		window.addEventListener('WebComponentsReady', resolve)
<-! ready.then

#TODO
