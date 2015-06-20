Tinytest.add('expose an object', function (test) {
	test.instanceOf(MagisterBinding, Object);
});

Tinytest.add('have the required functions', function (test) {
	test.isNotNull(MagisterBinding.createData);
	test.isNotNull(MagisterBinding.getCalendarItems);
	test.isNotNull(MagisterBinding.getClasses);
	test.isNotNull(MagisterBinding.getGrades);
	test.isNotNull(MagisterBinding.getPersons);
	test.isNotNull(MagisterBinding.getStudyUtils);
});
