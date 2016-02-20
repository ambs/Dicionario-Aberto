'use strict';

var $mod = angular.module('DA');

$mod.controller('DailyWord', function($scope, $http, $sce) {
		$http.get("http://api.dicionario-aberto.net/wotd").then(function(response) {
			var xml = response.data['xml'];
			
			var div   = function(c) { return el("div", c); }
			var empty = function()  { return "" }
			var id    = function(c) { return c }
			$scope.def = $sce.trustAsHtml(dt(xml, {
				"orth"      : empty,
				
				"#document" : id,

				"entry"     : div,
				"form"      : div,
				"sense"     : div,
				"def"       : div,
				"etym"      : div,

				"gramGrp"   : function(c) { return el("div", el("i", c)) },
				
				"#default"  : function(c,q,v) { return el("b",q) + ": " + c },
				"#text"     : function(c) { return c.replace(/_([^ ][^_]+)_/g, el("i", "$1")) }
			}));
			
			var title = xml.replace(/<\/orth>(.|\n)*$/,"");
			title = title.replace(/^(.|\n)*<orth>/,"");
			$scope.word = title;
		});
	});

