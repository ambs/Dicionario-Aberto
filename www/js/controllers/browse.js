'use strict';

var $mod = angular.module('DA');

$mod.controller('BrowseController', function($scope, $http, $stateParams, $sce, API) {
  $scope.loading_words = true;
  $scope.curr = { letter: $stateParams.letter, word: '' };
  $scope.entries = [];

  $scope.range = function(start,stop) {
    var result=[];
    for (var idx=start.charCodeAt(0),end=stop.charCodeAt(0); idx <=end; ++idx){
      result.push(String.fromCharCode(idx));
    }
    return result;
  };

  $scope.select = function(word) {
    $scope.curr.word = word;
    $http
      .get(API + "/word/" + word).then(function(response) {
        if (response.data.length > 0) {
          $scope.entries = __map(response.data, function(x) {
            return { "def" : $sce.trustAsHtml(format_entry(x.xml)),
              "word" : $sce.trustAsHtml(get_title(x.xml)) };
            });
        }
      });
  };

  $http
    .get(API + '/browse/' + $scope.curr.letter)
    .then( function(response) {
      if (response.status === 200) {
        $scope.words = response.data;
        $scope.select($scope.words[0].word);
        $scope.loading_words = false;
      }
      else {
        // FIXME handle error
      }
    });

});
