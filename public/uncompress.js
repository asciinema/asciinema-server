/**
 *	this is a port of pyflate
 *	@url http://www.paul.sladen.org/projects/pyflate/
 *	@author kirilloid
 * @license CC-SA 3.0
 * @usage ArchUtils.bz2.decode(str)
 * @example ArchUtils.bz2.decode(
 * 		"BZh91AY&SYN\xEC\xE86\0\0\2Q\x80\0\x10@\0\6D\x90\x80 " +
 * 		"\x001\6LA\1\xA7\xA9\xA5\x80\xBB\x941\xF8\xBB\x92)\xC2\x84\x82wgA\xB0"
 * ) == "hello world\n";
*/

var ArchUtils = (function(){
  'use strict';

  // python functions
  function ord(c) { return String(c).charCodeAt(); }
  function chr(n) { return String.fromCharCode(n); }
  function sum(l) { return l.reduce(function(a,b){return a+b}, 0); }
  // NOTE: for in loop works another way in js and iterates over keys
  // therefore you can't use for (x in range(...)) the same way as in python
  function range(start, stop, step) {
    switch(arguments.length) {
      case 0: return [];
      case 1: stop = start; start = 0; step = 1; break;
      case 2: step = 1;
    }
    if ((stop - start) * step < 0) return [];
      var a = [];
    if (start < stop) {
      for (var i = start; i < stop; i += step) { a.push(i); }
    } else {
      for (var i = start; i > stop; i += step) { a.push(i); }
    }
    return a;
  }

  /**
   * bwt_reverse code from wikipedia (slightly modified)
   * @url http://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform
   * @license: CC-SA 3.0
*/
  function bwt_reverse(src, primary) {
    var len = src.length;
    if (primary >= len) throw RangeError("Out of bound");
      if (primary < 0) throw RangeError("Out of bound");

        if (typeof src == 'string') {
          var A = src.split('');
        } else {
          var A = src;
          src = src.join('');
        }
        A.sort();

        var start = {};
        for (var i = len-1; i >= 0; i--) start[A[i]] = i;

          var links = [];
          for (i = 0; i < len; i++) links.push(start[src[i]]++);

            var i, first = A[i = primary], ret = [];
            //while (i != primary) {
            for (var j = 1; j < len; j++) {
              ret.push(A[i = links[i]]);
            }
            return first + ret.reverse().join('');
  }

  function move_to_front(a, c) {
    var v = a[c];
    for (var i = c; i > 0; a[i] = a[--i]);
      a[0] = v;
  }

  /**
   * @class BitfieldBase
   * base class for bit-precision reading from stream
*/
  var BitfieldBase = function() {
    // init
    this.init = function(x) {
      this._masks = [];
      for (var i = 0; i < 31; i++) this._masks[i] = (1 << i) - 1;
        this._masks[31] = -0x80000000;
      if (x instanceof BitfieldBase) {
        this.f = x.f;
        this.bits = x.bits;
        this.bitfield = x.bitfield;
        this.count = x.count;
      } else {
        this.f = x;
        this.bits = 0;
        this.bitfield = 0x0;
        this.count = 0;
      }
    }
    // FIXME: this will throw an Exception when one tries to read zero-length string
    this._read = function(n) {
      var s = this.f.substr(this.count, n);
      if (!s) throw RangeError("Length Error");
        this.count += s.length;
      return s;
    }
    this._readByte = function _readByte() {
      return this.f.charCodeAt(this.count++);
    }
    this.needbits = function(n) {
      do { this._more() } while (this.bits < n);
    }
  this.toskip = function() {
    return this.bits & 0x7;
  }
  this.align = function() {
    this.readbits(this.toskip());
  }
  this.dropbits = function(n) {
    if (typeof n == 'undefined') n = 8;
      while (n >= this.bits && n > 7) {
        n -= this.bits;
        this.bits = 0;
        n -= (this.f._read(n >> 3)).length << 3;
      }
      if (n) this.readbits(n);
  }
this.dropbytes = function(n) {
  if (typeof n == 'undefined') n = 1;
    this.dropbits(n << 3);
}
// some function for debugging
this.tell = function() {
  return [this.count - ((this.bits+7) >> 3), 7 - ((this.bits-1) & 0x7)];
}
  }

  //	not used after all
  /*	ìar Bitfield = function() {
  this._more = function() {
  this.bitfield += this._readByte() << this.bits;
  this.bits += 8;
  }
  this.readbits = function(n) {
  if (typeof n == 'undefined') n = 8;
  if (n >= 32) {
  var n2 = n >> 1;
  return this.readbits(n2) * (1 << n2) + this.readbits(n - n2);
  }
  if (n > this.bits)
  this.needbits(n);
  var r = this.bitfield & this._masks[n];
  this.bits -= n;
  this.bitfield >>= n;
  return r;
  }
  }
  Bitfield.prototype = new BitfieldBase();*/

  /**
   * @class BitfieldBase
   * right-sided bitfield for reading bits in byte from right to left
*/
  var RBitfield = function() {
    this._more = function() {
      this.bitfield = (this.bitfield << 8) + this._readByte();
      this.bits += 8;
    }
    // since js truncate args to int32 with bit operators
    // we need to specific processing for n >= 32 bits reading
    // separate function is created for optimization purposes
    this.readbits2 = function readbits2(n) {
      if (n >= 32) {
        var n2 = n >> 1;
        return this.readbits(n2) * (1 << n2) + this.readbits(n - n2);
      } else {
        return this.readbits(n);
      }
    }
    this.readbits = function readbits(n) {
      //if (n > this.bits) this.needbits(n);
      // INLINED: needbits
      while (this.bits < n) {
        this.bitfield = (this.bitfield << 8) + this._readByte();
        this.bits += 8;
      }
      var m = this._masks[n];
      var r = (this.bitfield >> (this.bits - n)) & m;
      this.bits -= n;
      this.bitfield &= ~(m << this.bits);
      return r;
    }
  }
  RBitfield.prototype = new BitfieldBase();

  /**
   * @class HuffmanLength
   * utility class, used for comparison of huffman codes
*/
  var HuffmanLength = function(code, bits) {
    if (typeof bits == "undefined") bits = 0;
      this.code = code;
    this.bits = bits;
    this.symbol = undefined;

    this.toString = function() {
      return [this.code, this.bits, this.symbol/*, this.reverse_symbol*/];
    }
    this.valueOf = function() {
      return this.bits * 1000 + this.code;
    }
  }

  /**
   * @class HuffmanLength
   * utility class for working with huffman table
*/
  var HuffmanTable = function() {
    this.init = function initHuffmanTable(bootstrap) {
      var l = [];
      var b = bootstrap[0];
      var start = b[0], bits = b[1];
      for (var p = 1; p < bootstrap.length; p++) {
        var finish = bootstrap[p][0], endbits = bootstrap[p][1];
        if (bits)
          for (var code = start; code < finish; code++)
            l.push(new HuffmanLength(code, bits));
        start = finish;
        bits = endbits;
        if (endbits == -1) break;
      }
    l.sort(function cmpHuffmanTable(a, b){
      return (a.bits - b.bits) || (a.code - b.code);
    });
    this.table = l;
    }

    this.populate_huffman_symbols = function() {
      var bits = 0;
      var symbol = -1;
      // faht = Fast Access Huffman Table
      this.faht = [];
      var cb = null;
      for (var i = 0; i < this.table.length; i++) {
        var x = this.table[i];
        symbol += 1;
        if (x.bits != bits) {
          symbol <<= x.bits - bits;
          cb = this.faht[bits = x.bits] = {};
        }
        cb[x.symbol = symbol] = x;
      }
    }

    this.min_max_bits = function() {
      this.min_bits = 16;
      this.max_bits = -1;
      this.table.forEach(function(x){
        if (x.bits < this.min_bits) this.min_bits = x.bits;
          if (x.bits > this.max_bits) this.max_bits = x.bits;
      }, this);
    }

  }

  var OrderedHuffmanTable = function() {
    this.init = function(lengths) {
      var l = lengths.length;
      var z = [];
      for (var i = 0; i < l; i++) {
        z.push([i, lengths[i]]);
      }
      z.push([l, -1]);
      OrderedHuffmanTable.prototype.init.call(this, z);
    }
  }
  OrderedHuffmanTable.prototype = new HuffmanTable();

  // unpackedSize is ignored here but added for uniformity
  // this param simplifies Java (applet) implementation of bzip decoder
  return ({ bz2: { decode: function(input, unpackedSize) {
    var b = new RBitfield();
    b.init(input);
    b.readbits(16);
    var method = b.readbits(8);
    if (method != ord('h')) {
      throw "Unknown (not type 'h'uffman Bzip2) compression method";
    }

    var blocksize = b.readbits(8);
    if (ord('1') <= blocksize
        && blocksize <= ord('9')) {
          blocksize -= ord('0');
        } else {
          throw "Unknown (not size '0'-'9') Bzip2 blocksize";
        }

        function getUsedCharTable(b) {
          var a = [];
          var used_groups = b.readbits(16);
          for (var m1 = 1 << 15; m1 > 0; m1 >>= 1) {
            if (!(used_groups & m1)) {
              for (var i = 0; i < 16; i++) a.push(false);
                continue;
            }
            var used_chars = b.readbits(16);
            for (var m2 = 1 << 15; m2 > 0; m2 >>= 1) {
              a.push( Boolean(used_chars & m2) );
            }
          }
          return a;
        }

        var out = [];
        // TODO: I hope exection may me splitted into chunks
        // and run with them in background
        function main_loop() { while (true) {
          var blocktype = b.readbits2(48);
          var crc = b.readbits2(32);
          if (blocktype == 0x314159265359) { // (pi)
            if (b.readbits(1)) throw "Bzip2 randomised support not implemented";
              var pointer = b.readbits(24);
            var used = getUsedCharTable(b);

            var huffman_groups = b.readbits(3);
            if (2 > huffman_groups || huffman_groups > 6)
              throw RangeError("Bzip2: Number of Huffman groups not in range 2..6");
            var mtf = range(huffman_groups);
            var selectors_list = [];
            for (var i = 0, selectors_used = b.readbits(15); i < selectors_used; i++) {
              // zero-terminated bit runs (0..62) of MTF'ed huffman table
              var c = 0;
              while (b.readbits(1)) {
                if (c++ >= huffman_groups)
                  throw RangeError("More than max ("+huffman_groups+") groups");
              }
              move_to_front(mtf, c);
              selectors_list.push(mtf[0]);
            }
            var groups_lengths = [];
            var symbols_in_use = sum(used) + 2  // remember RUN[AB] RLE symbols
            for (var j = 0; j < huffman_groups; j++) {
              var length = b.readbits(5);
              var lengths = [];
              for (var i = 0; i < symbols_in_use; i++) {
                if (length < 0 || length > 20)
                  throw RangeError("Bzip2 Huffman length code outside range 0..20");
                while (b.readbits(1)) length -= (b.readbits(1) * 2) - 1;
                  lengths.push(length);
              }
              groups_lengths.push(lengths);
            }
            var tables = [];
            for (var g = 0; g < groups_lengths.length; g++) {
              var codes = new OrderedHuffmanTable();
              codes.init(groups_lengths[g]);
              codes.populate_huffman_symbols();
              codes.min_max_bits();
              tables.push(codes);
            }
            var favourites = [];
            for (var c = used.length - 1; c >= 0; c--) {
              if (used[c]) favourites.push(chr(c));
            }
          favourites.reverse();
          var selector_pointer = 0;
          var decoded = 0;
          var t;

          // Main Huffman loop
          var repeat = 0;
          var repeat_power = 0;
          var buffer = [], r;

          while (true) {
            if (--decoded <= 0) {
              decoded = 50;
              if (selector_pointer <= selectors_list.length)
                t = tables[selectors_list[selector_pointer++]];
            }

            // INLINED: find_next_symbol
            for (var bb in t.faht) {
              if (b.bits < bb) {
                b.bitfield = (b.bitfield << 8) + b.f.charCodeAt(b.count++);
                b.bits += 8;
              }
              if (r = t.faht[bb][ b.bitfield >> (b.bits - bb) ]) {
                b.bitfield &= b._masks[b.bits -= bb];
                r = r.code;
                break;
              }
            }

            if (0 <= r && r <= 1) {
              if (repeat == 0)  repeat_power = 1;
                repeat += repeat_power << r;
              repeat_power <<= 1;
              continue;
            } else {
              var v = favourites[0];
              for ( ; repeat > 0; repeat--) buffer.push(v);
            }
          if (r == symbols_in_use - 1) { // eof symbol
            break;
          } else {
            // INLINED: move_to_front
            var v = favourites[r-1];
            for (var i = r-1; i > 0; favourites[i] = favourites[--i]);
              buffer.push(favourites[0] = v);
          }
          }
          var nt = bwt_reverse(buffer, pointer);
          var done = [];
          var i = 0;
          var len = nt.length;
          // RLE decoding
          while (i < len) {
            var c = nt.charCodeAt(i);
            if ((i < len - 4)
                && nt.charCodeAt(i+1) == c
              && nt.charCodeAt(i+2) == c
              && nt.charCodeAt(i+3) == c) {
                var c = nt.charAt(i);
                var rep = nt.charCodeAt(i+4)+4;
                for (; rep > 0; rep--) done.push(c);
                  i += 5;
              } else {
                done.push(nt[i++]);
              }
          }
          out.push(done.join(''));
          } else if (blocktype == 0x177245385090) { // sqrt(pi)
            b.align();
            break;
          } else {
            throw "Illegal Bzip2 blocktype = 0x" + blocktype.toString(16);
          }
        } }
        main_loop();
        return out.join('');
  } } });
})();

// WEBWORKER TASK
this.onmessage = function(e) {
  var data = e.data;

  data = ArchUtils.bz2.decode(data);

  postMessage(data);
};
