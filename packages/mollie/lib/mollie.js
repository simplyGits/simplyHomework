/**
 * Global Mollie object.
 * @property Mollie
 **/
Mollie = {
	/**
	 * Makes a payement.
	 * If done, `callback` will called, if `callback` is null the function will run synchronously
	 *
	 * @method makePayement
	 * @param options {Object} An object containing Mollie options.
	 * @param [callback] {Function} Callback function.
	 * @param callback.payement {Payement} The Mollie payement.
	 * @return {Null|Payement} Null if callback is given, otherwise the payement.
	 **/
	makePayement: function (options, callback) {
		if (callback != null)
			Meteor.call("_mollieMakePayement", options, callback);

		else if (Meteor.isServer)
			return Meteor.call("_mollieMakePayement", options);

		else
			throw new Error("Callback required on client.");
	},

	/**
	 * Gets a payement.
	 * If done, `callback` will called, if `callback` is null the function will run synchronously
	 *
	 * @method getPayement
	 * @param options {Object} An object containing Mollie options.
	 * @param [callback] {Function} Callback function.
	 * @param callback.payement {Payement} The Mollie payement.
	 * @return {Null|Payement} Null if callback is given, otherwise the payement.
	 **/
	getPayement: function (id, callback) {
		if (callback != null)
			Meteor.call("_mollieGetPayement", id, callback);

		else if (Meteor.isServer)
			return Meteor.call("_mollieGetPayement", id);

		else
			throw new Error("Callback required on client.");
	}
};
