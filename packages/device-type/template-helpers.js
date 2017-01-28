import { isPhone, isTablet, isDesktop } from './device-type.js'

Meteor.startup(function () {
	Template.registerHelper('isPhone', isPhone)
	Template.registerHelper('isTablet', isTablet)
	Template.registerHelper('isDesktop', isDesktop)
})
