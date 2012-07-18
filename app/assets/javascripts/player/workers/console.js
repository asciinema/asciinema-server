console = {
  log: function(t) {
    postMessage({ message: 'log', text: t });
  }
};
