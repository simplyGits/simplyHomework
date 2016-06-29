/* global MagisterBinding */

import { ExternalServicesConnector } from 'meteor/simply:external-services-connector';

/**
 * simplyHomework binding to Magister.
 * @author simply
 * @module magister-binding
 */

/**
 * A simplyHomework binding to Magister.
 * @class MagisterBinding
 * @static
 */
MagisterBinding = {
	name: 'magister',
	friendlyName: 'Magister',
	loginNeeded: true,
};

ExternalServicesConnector.pushExternalService(MagisterBinding);
