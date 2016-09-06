import { Meteor } from 'meteor/meteor';
import locks from 'locks';

export default class Mutex extends locks.Mutex {
	constructor() {
		super();
		this.lock = Meteor.wrapAsync(this.lock, this);
	}
}
