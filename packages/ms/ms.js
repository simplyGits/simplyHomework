/* global ms:true */
'use strict'

const seconds = 1000
const minutes = seconds * 60
const hours = minutes * 60
const days = hours * 24
const weeks = days * 7
const years = days * 365
const map = { seconds, minutes, hours, days, weeks, years }

ms = {
	milliseconds(ms) {
		return ms
	},
}
for (const key in map) {
	ms[key] = (x) => map[key] * x
}
