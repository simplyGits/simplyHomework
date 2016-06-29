/* global GravatarBinding */

import { ExternalServicesConnector } from 'meteor/simply:external-services-connector';

/**
 * simplyHomework binding to Gravatar.
 * @author simply
 * @module gravatar-binding
 */

GravatarBinding = {
	name: 'gravatar',
	friendlyName: 'Gravatar',
	loginNeeded: false,
};

ExternalServicesConnector.pushExternalService(GravatarBinding);
