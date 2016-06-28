// Import Tinytest from the tinytest Meteor package.
import { Tinytest } from "meteor/tinytest";

// Import and rename a variable exported by waitgroup.js.
import { name as packageName } from "meteor/waitgroup";

// Write your tests here!
// Here is an example.
Tinytest.add('waitgroup - example', function (test) {
  test.equal(packageName, "waitgroup");
});
