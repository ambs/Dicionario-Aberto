'use strict';

var $mod = angular.module('DA');

$mod.controller('NewsController',
	function($scope, $http, $sce, API) {
	  $scope.loading = true;
	  $http.get(API + "/news?limit=4").then(
	  	function(response) {
		  $scope.news = $.map(response.data, function (x) {
		    x['text'] = $sce.trustAsHtml(x['text']);
		    return x;
		  });
	  	  $scope.loading = false;
	  });
});

$mod.filter('myDate', function() {
	return function (date) {
		return date.replace(/\s.+/,"");
	}
});
