Package.describe({
  name: 'magister-binding',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: 'Magister binding for simplyHomework.',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.1');

  api.use(["erasaur:meteor-lodash", "magisterjs", "ejson"], "server");
  //api.use(["erasaur:meteor-lodash", "simply:magisterjs@1.3.3"], "server");

  api.addFiles("magister-binding.js", "server");
  api.export("MagisterBinding", "server");
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('magister-binding');
  api.addFiles('magister-binding-tests.js', 'server');
});
