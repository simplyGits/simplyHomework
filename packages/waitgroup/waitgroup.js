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

	/**
	 * Loops over the given `arr` calling `fn` concurrently, waiting on every running call after looping over `groupSize` items.
	 * `forEach` expects `arr` not to be changed during the loop.
	 * @param {Array} arr
	 * @param {Function} fn Will be called with the current element, the current index, and a reference to the array being looped over.
	 * @param {Number} [groupSize=Infinity]
	 */
	static forEach(arr, fn, groupSize = Infinity) {
		for (let g = 0; g < arr.length; g += groupSize) {
			const wg = new WaitGroup()
			for (let i = g; i-g<groupSize && i<arr.length; i++) {
				const x = arr[i]
				wg.defer(function () {
					fn(x, i, arr)
				})
			}
			wg.wait()
		}
	}

	/**
	 * Creates a new array with the return values of `fn` concurrently, waiting on every running call after looping over `groupSize` items.
	 * `map` expects `arr` not to be changed during the loop.
	 * @param {Array} arr
	 * @param {Function} fn Will be called with the current element, the current index, and a reference to the array being looped over. The return value will be used to represent the current item in the newly created array
	 * @param {Number} [groupSize=Infinity]
	 * @return {Array}
	 */
	static map(arr, fn, groupSize = Infinity) {
		const res = new Array(arr.length)
		WaitGroup.forEach(arr, function (x, i, arr) {
			res[i] = fn(x, i, arr)
		}, groupSize)
		return res
	}
}
