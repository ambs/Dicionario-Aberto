
angular.module('DA', [])
	.controller('NewsController', function($scope, $http) {
		$http.get("http://api.dicionario-aberto.net/news").then(function(response) {
			$scope.news = response;
		});
	});
