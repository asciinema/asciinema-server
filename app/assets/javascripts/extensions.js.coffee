String.prototype.times = (n) ->
  Array.prototype.join.call { length: n + 1 }, this
