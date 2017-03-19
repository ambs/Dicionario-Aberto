'use strict';

app.controller('Scroller', function($scope, $location, $anchorScroll) {
   $scope.scrollTo = function(id) {
      $location.hash(id);
      $anchorScroll();
   }
});