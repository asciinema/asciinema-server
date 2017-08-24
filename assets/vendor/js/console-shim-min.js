/*
 console-shim 1.0.0
 https://github.com/kayahr/console-shim
 Copyright (C) 2011 Klaus Reimer <k@ailis.de>
 Licensed under the MIT license
 (See http://www.opensource.org/licenses/mit-license)
*/
(function(){function c(a,b){return function(){a.apply(b,arguments)}}if(!window.console)window.console={};var a=window.console;if(!a.log)if(window.log4javascript){var b=log4javascript.getDefaultLogger();a.log=c(b.info,b);a.debug=c(b.debug,b);a.info=c(b.info,b);a.warn=c(b.warn,b);a.error=c(b.error,b)}else a.log=function(){};if(!a.debug)a.debug=a.log;if(!a.info)a.info=a.log;if(!a.warn)a.warn=a.log;if(!a.error)a.error=a.log})();