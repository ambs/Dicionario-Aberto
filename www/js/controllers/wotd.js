'use strict';

var $mod = angular.module('DA');

$mod.controller('DailyWord', function($scope, $http, $sce) {
		$http.get("http://api.dicionario-aberto.net/wotd").then(function(response) {
			var xml = response.data['xml'];
			
			$scope.def = $sce.trustAsHtml(format_entry(xml));
			$scope.word = get_title(xml);
		});
	});

