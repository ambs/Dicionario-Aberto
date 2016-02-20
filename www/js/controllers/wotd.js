'use strict';

var $mod = angular.module('DA');

$mod.controller('DailyWord', function($scope, $http, $sce) {
		$http.get("http://api.dicionario-aberto.net/wotd").then(function(response) {
			var xml = response.data['xml'];
			
			$scope.def = $sce.trustAsHtml(dt(xml, {
				"orth"      : function() { return "" },
				"gramGrp"   : function(c) { return el(el(c,"i"),"div") },

				"#document" : function(c,q,v) { return c },
				"#default"  : function(c,q,v) { return "<b>"+q+"</b>: " + c }
			}));
			
			var title = xml.replace(/<\/orth>(.|\n)*$/,"");
			title = title.replace(/^(.|\n)*<orth>/,"");
			$scope.word = title;
		});
	});

