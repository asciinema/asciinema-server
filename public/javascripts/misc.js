Function.prototype.bind = function(object) {
  var func = this;
  return function() {
    return func.apply(object, arguments);
  };
};

String.prototype.times = function(n) {
  return Array.prototype.join.call({length:n+1}, this);
};
