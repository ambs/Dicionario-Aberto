'use strict';

var $mod = angular.module('DA');

$mod.controller('Search', function($scope, $http, $sce, $state, API) {

	$scope.click = function() {

		var word = document.getElementById("mysearch").value;

		$http.get(API + "/word/" + word).then(function(response) {

			if (response.data.length > 0) {
				$scope.entries = __map(response.data, function(x) {

					return { "def" : $sce.trustAsHtml(format_entry(x.xml)),
				  		"title" : get_title(x.xml) };

				});
			}

			$state.go("search");

		});

	}
});