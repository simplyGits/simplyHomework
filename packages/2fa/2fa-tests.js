// Import Tinytest from the tinytest Meteor package.
import { Tinytest } from "meteor/tinytest";

// Import and rename a variable exported by 2fa.js.
import { name as packageName } from "meteor/2fa";

// Write your tests here!
// Here is an example.
Tinytest.add('2fa - example', function (test) {
  test.equal(packageName, "2fa");
});
