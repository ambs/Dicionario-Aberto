
angular.module('DA', [])
	.controller('NewsController', function($scope, $http) {
		$http.get("/ajax/news").then(function(response) {
			$scope.news = response.data;
		});
	});
