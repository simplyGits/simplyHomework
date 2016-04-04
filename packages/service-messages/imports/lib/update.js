/**
 * @class Update
 * @constructor
 * @param {String} header
 * @param {String} body
 * @param {String} userId
 */
export default class Update {
	constructor(header, body, userId) {
		/**
		 * @property header
		 * @type String
		 */
		this.header = header

		/**
		 * @property body
		 * @type String
		 */
		this.body = body

		/**
		 * @property userId
		 * @type String
		 */
		this.userId = userId

		/**
		 * @property creationDate
		 * @type Date
		 * @default new Date()
		 */
		this.creationDate = new Date()

		/**
		 * @property hidden
		 * @type Boolean
		 * @default false
		 */
		this.hidden = false
	}
}
