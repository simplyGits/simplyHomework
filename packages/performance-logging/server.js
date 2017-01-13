export const PerformanceData = new Mongo.Collection('performanceData');

Meteor.methods({
	performance_report(data) {
		check(data, Object);
		const userAgent = this.connection.httpHeaders['user-agent'];
		PerformanceData.insert({
			when: new Date(),
			userAgent,
			...data,
		});
	},
});
