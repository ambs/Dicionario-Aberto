'use strict';

var $mod = angular.module('DA');

$mod.controller('Search', function($scope, $http, $sce, $stateParams, API) {

	var word = $stateParams.word;

	$scope.entries = [];
	$scope.near = [];

	$http.get(API + "/word/" + word).then(function(response) {

		if (response.data.length > 0) {
			$scope.entries = __map(response.data, function(x) {
				return { "def" : $sce.trustAsHtml(format_entry(x.xml)),
				  		     "word" : $sce.trustAsHtml(get_title(x.xml)) };
			});
		}
	});

	$http.get(API + "/near/" + word).then(function(response) {
		if (response.data.length > 0) {
			$scope.near = response.data;
		}
	});

});