'use strict';

var $mod = angular.module('DA');

$mod.controller('Random', function($scope, $http, $sce, API) {
		$http.get(API + "/random").then(function(response) {
			var xml = response.data['xml'];
			
			$scope.def = $sce.trustAsHtml(format_entry(xml));
			$scope.word = $sce.trustAsHtml(get_title(xml));
		});
	});

