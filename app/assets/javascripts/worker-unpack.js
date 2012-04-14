//= include vendor/bzip2

this.onmessage = function(e) {
  var data = e.data;
  data = ArchUtils.bz2.decode(data);
  postMessage(data);
};
