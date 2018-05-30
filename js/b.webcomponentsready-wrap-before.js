(callback => {
	document.head.querySelector('[media=async]').removeAttribute('media');
	if (window.WebComponents && window.WebComponents.ready) {
		callback();
	} else {
		document.addEventListener('WebComponentsReady', callback, {once: true});
	}
})(() => {
