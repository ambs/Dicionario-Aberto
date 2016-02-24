'use strict';

var $mod = angular.module('DA');

$mod.controller('DailyWord', function($scope, $http, $sce, API) {
		$http.get(API + "/wotd").then(function(response) {
			var xml = response.data['xml'];
			
			$scope.def = $sce.trustAsHtml(format_entry(xml));
			$scope.word = $sce.trustAsHtml(get_title(xml));
		});
	});

