/**
 * @class Update
 * @constructor
 * @param {String} header
 * @param {String} body
 * @param {String} userId
 */
class Update {
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

		/**
		 * Query to match the person which this update is sent to.
		 * Stored as an EJSON stringified object.
		 * @property matchQuery
		 * @type String
		 * @default '{}'
		 */
		this.matchQuery = '{}'
	}

	setMatchQuery(val) {
		this.matchQuery = EJSON.stringify(val)
	}
}

Update.publishedFields = [
	'header',
	'body',
	'creationDate',
]

export default Update
