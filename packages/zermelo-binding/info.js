/* global ZermeloBinding:true */

import { ExternalServicesConnector } from 'meteor/simply:external-services-connector'

/**
 * simplyHomework binding to Zermelo.
 * @author simply
 * @module zermelo-binding
 */

/**
 * A simplyHomework binding to Zermelo.
 * @class ZermeloBinding
 * @static
 */
ZermeloBinding = {
	name: 'zermelo',
	friendlyName: 'Zermelo',
	loginNeeded: true,
}

ExternalServicesConnector.pushExternalService(ZermeloBinding)
