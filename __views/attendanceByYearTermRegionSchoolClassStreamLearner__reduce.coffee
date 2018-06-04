(keys, values, rereduce) ->
  if (!rereduce)
      length = values.length
      return [sum(values) / length, length]
  else
    length = sum(values.map( (v) -> v[1] ))
    avg = sum(values.map( (v) ->
      v[0] * (v[1] / length)
    ))
    [avg, length]
