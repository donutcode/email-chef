# Peek at the end of a given string to see if it matches a sequence
exports.ends = (string, literal, back) ->
  len = literal.length
  literal is string.substr string.length - len - (back or 0), len

# Extend a source object with the properties of another object (shallow copy)
exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object
