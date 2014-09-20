Styling
===
* Try to limit the access to the collections by the classes, example of a bad practice:

  ```coffeescript
  shareWithClass: -> Schedules.update @_id, { $set: { _isPublic: yes }}
  ```

  Correct would be:

  ```coffeescript
  shareWithClass: -> @isPublic yes
  ```

  The changes will 'flow up' to the factory, which will update the document in the collection.

  _The only access to the collections are:_
    * _All read operations_
    * _Remove_
    

* Variables should be getter-setter methods which will automatically depend on the class' dependency and update it if needed, this can be provided with the global getset(varName, pattern = Match.Any, allowChanges = yes) (helpers.coffee) function.

* Don't do duck-typing or use the prototype, use class extending instead. If using the prototype / duck-typing is needed then only ADD functions don't change existing functions