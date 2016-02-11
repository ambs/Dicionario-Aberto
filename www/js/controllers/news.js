'use strict';

angular.module('DA').controller('NewsController', function($scope, $http, $sce) {
		$http.get("http://api.dicionario-aberto.net/news").then(function(response) {
			$scope.news = 
				$.map(response.data,
					function (x) { x['text'] = $sce.trustAsHtml(x['text']); return x});
		});
	});
