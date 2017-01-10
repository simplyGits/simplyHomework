import Future from 'fibers/future'

export default class WaitGroup {
	constructor() {
		this._futs = []
	}

	_getFuture() {
		const fut = new Future()
		this._futs.push(fut)
		return fut
	}

	add(fn) {
		const fut = this._getFuture()
		fn(fut.resolver())
	}

	defer(fn) {
		const fut = this._getFuture()
		Meteor.defer(function () {
			fut.return(fn())
		})
	}

	wait() {
		for (const fut of this._futs) {
			fut.wait()
		}
	}

	static forEach(arr, fn) {
		const wg = new WaitGroup()
		arr.forEach(function (x, i) {
			wg.defer(function () {
				fn(x, i, arr)
			})
		})
		wg.wait()
	}

	static map(arr, fn) {
		const res = new Array(arr.length)
		WaitGroup.forEach(arr, function (x, i) {
			res[i] = fn()
		})
		return res
	}
}
