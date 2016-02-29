'use strict';

var $mod = angular.module('DA');

$mod.controller('BrowseController', function($scope, $http, API) {

  $scope.range = function(start,stop) {
    var result=[];
    for (var idx=start.charCodeAt(0),end=stop.charCodeAt(0); idx <=end; ++idx){
      result.push(String.fromCharCode(idx));
    }
    return result;
  };

});
