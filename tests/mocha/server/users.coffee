MochaWeb?.testOnly ->
	expect = chai.expect

	describe "Users", ->
		it "should not contain users", ->
			expect(Meteor.users.find({}).count()).to.equal 0
