'use strict';

angular.module('DA')
  .config( function($stateProvider, $urlRouterProvider) {

    $urlRouterProvider.otherwise('/');

    $stateProvider
      .state('main', {
        url: '/',
        templateUrl: 'views/main.html',   
      });
      /*.state('queues', {
        url: '/queues',
        templateUrl: 'views/queues.html'
      })
      .state('tasks', {
        url: '/tasks/:id',
        templateUrl: 'views/tasks.html'
      })
     .state('dashboard', {
        url: '/dashboard',
        templateUrl: 'views/dashboard.html'
      })*/

  });
