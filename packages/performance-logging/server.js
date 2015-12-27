PerformanceData = new Mongo.Collection('performanceData');

Meteor.methods({
	performance_report: function (data) {
		// TODO: Add user-agent.
		check(data, Object);
		PerformanceData.insert(data);
	}
})
