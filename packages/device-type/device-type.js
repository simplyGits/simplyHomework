import './template-helpers.js'

// TODO: expand this regex or also add an matchMedia for tablets.
const tabletRegex = /ipad/i
const phoneRegex = /android|iphone|ipod|blackberry|windows phone/i
function updateDeviceType () {
	let val = 'desktop'
	if (tabletRegex.test(navigator.userAgent)) {
		val = 'tablet'
	} else if (
		phoneRegex.test(navigator.userAgent) || (
			typeof window.matchMedia === 'function' &&
			window.matchMedia('only screen and (max-width: 800px)').matches
		)
	) {
		val = 'phone'
	}
	Session.set('deviceType', val)
}

updateDeviceType()
window.addEventListener('resize', updateDeviceType)

export default function type () {
	return Session.get('deviceType')
}

export function isPhone () {
	return Session.equals('deviceType', 'phone')
}
export function isTablet () {
	return Session.equals('deviceType', 'tablet')
}
export function isDesktop () {
	return Session.equals('deviceType', 'desktop')
}
