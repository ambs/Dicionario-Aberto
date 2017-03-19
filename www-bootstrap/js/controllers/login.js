'use strict';

var $mod = angular.module('DA');

$mod.controller('SignIn',
	function($scope, $http, $window, $state, API) {

		$scope.auth = { username: '', password: '' };

		$scope.login = function() {
    		if ($scope.auth.username && $scope.auth.password) {
        		$http
          			.post(API + '/auth', $scope.auth)
	            	.then( function(response) {
      		 	   		if (response.data.success) {
							$window.sessionStorage.token    = response.data.token;
							$window.sessionStorage.username = $scope.auth.username;
              
							$state.go('index');
            			}
            			else {
              				alert(response.data.error);
            			}
          			});
      			}
      		else {
        		alert('O nome do utilizador e a senha são obrigatórios.');
      	}
    };

});


