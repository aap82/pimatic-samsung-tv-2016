type = (obj) ->
  if obj == undefined or obj == null
    return String obj
  classToType = {
    '[object Boolean]': 'boolean',
    '[object Number]': 'number',
    '[object String]': 'string',
    '[object Function]': 'function',
    '[object Array]': 'array',
    '[object Date]': 'date',
    '[object RegExp]': 'regexp',
    '[object Object]': 'object'
  }
  return classToType[Object.prototype.toString.call(obj)]

keys = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj
  return Object.keys(obj)

extend = (obj, mixin) ->
  if not obj? or typeof obj isnt 'object'
    return obj
  obj[key] = value for key, value of mixin
  obj

objectWithProperties = (obj) ->
  if obj.properties
    Object.defineProperties obj, obj.properties
    delete obj.properties
  obj

clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance

module.exports = {
  type
  keys
  extend
  objectWithProperties
  clone
}