Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output


Array::merge ?= (other) -> Array::push.apply @, other

Array::toDict ?= (key) ->
  dict = {}
  dict[obj[key]] = obj for obj in this when obj[key]?
  dict

Array::where ?= (query) ->
  return [] if typeof query isnt "object"
  hit = Object.keys(query).length
  @filter (item) ->
    match = 0
    for key, val of query
      match += 1 if item[key] is val
    if match is hit then true else false

Array::remove ?= (val) ->
  idx = @indexOf val
  return @splice(idx, 1) if idx isnt -1
  return false
