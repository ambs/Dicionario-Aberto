'use strict';

angular.module('DA')
  .config( function($stateProvider, $urlRouterProvider) {

    $urlRouterProvider.otherwise('/');

    $stateProvider
      .state('main', {
        url: '/',
        templateUrl: 'views/main.html',   
      })
      .state('random', {
        url: '/random',
        templateUrl: 'views/random.html'
      })
      .state('search', {
        url: '/search',
        templateUrl: 'views/search.html'
      })/*
     .state('dashboard', {
        url: '/dashboard',
        templateUrl: 'views/dashboard.html'
      })*/;

  });
