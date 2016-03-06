'use strict';

var $mod = angular.module('DA');

$mod.controller('BrowseController',
  function($scope, $http, $stateParams, $sce, API) {

    var update = function (word) {
      $http
        .get(API + '/browse/' + word)
        .then( function(response) {
          if (response.status === 200) {
            $scope.words = response.data.words;
            $scope.curr.word = response.data.cword;
            $scope.curr.letter = String.toLowerCase($scope.curr.word[0]);
            $scope.curr.id  = response.data.cid;
            $scope.select($scope.curr.word);

            $scope.loading_words = false;
          }
          else {
            // FIXME handle error
          }});
    };

    $scope.update_list = update;
    $scope.loading_words = true;
    $scope.curr = { letter: $stateParams.letter, word: '' };
    $scope.entries = [];

    update($scope.curr.letter);

    $scope.range = function(start,stop) {
      var result=[];
      for (var idx=start.charCodeAt(0),end=stop.charCodeAt(0); idx <=end; ++idx){
        result.push(String.fromCharCode(idx));
      }
      return result;
    };

    $scope.browseIdx = function(idx) {
      $http
        .get(API + '/browse/' + idx)
        .then( function(response) {
          if (response.status === 200) {
            $scope.words = response.data.words;
            $scope.curr.word = response.data.cword;
            $scope.curr.letter = String.toLowerCase($scope.curr.word[0]);
            $scope.curr.id  = response.data.cid;
            $scope.select($scope.curr.word);

            $scope.loading_words = false;
          }
          else {
            // FIXME handle error
          }});
      };

    $scope.select = function(word) {  
      if ($scope.curr.word != word) {
         $scope.update_list(word);
      }
      else {
      $http
        .get(API + "/word/" + word).then(function(response) {
          if (response.data.length > 0) {
            $scope.entries = __map(response.data,
              function(x) {
               return { "def" : $sce.trustAsHtml(format_entry(x.xml)),
                  "word" : $sce.trustAsHtml(get_title(x.xml)) };
              }); 
          } 
        }); 
      }
  };
  
});