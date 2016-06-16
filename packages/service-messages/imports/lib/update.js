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
		 * @property subheader
		 * @type String|undefined
		 */
		this.subheader = undefined

		/**
		 * @property body
		 * @type String
		 */
		this.body = body

		/**
		 * @property priority
		 * @type Number
		 * @default 0
		 */
		this.priority = 0

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
	'subheader',
	'body',
	'priority',
	'creationDate',
]

export default Update
