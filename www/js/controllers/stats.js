'use strict';

var $mod = angular.module('DA');

$mod.controller('StatsController',
  function($scope, $http, $stateParams, $sce, API) {

  $http
    .get(API + '/stats/letter')
    .then( function(response) {
      if (response.status === 200) {
        $scope.chart1Config = {
          series: [{ data: response.data.values }],
          options: {
            chart: {
                type: 'column',
                margin: [30, 0, 30, 50]
            },
            title: { text: 'Número de Palavras por Letra' },
            xAxis: {
                categories: response.data.axis,
                title: { text: null }
            },
            yAxis: {
                min: 0,
                title: {
                    text: null,
                    align: 'middle'
                }
            },
            tooltip: {
                formatter: function() {
                    return '<b>'+ this.x +':</b> '+ this.y + ' entradas.';
                }
            },
            plotOptions: {
                series: {
                    borderWidth: 0,
                    shadow: false,
                    stacking: 'normal',
                }
            },
            legend:  { enabled: false },
            credits: { enabled: false },
          }
        };
      }  
      else {
        // FIXME handle error
      }
    });

  $http
    .get(API + '/stats/size')
    .then( function(response) {
      if (response.status === 200) {
        $scope.chart2Config = {
          series: [{ data: response.data.values }],
          options: {
            chart: {
                type: 'column',
                margin: [30, 0, 30, 50]
            },
            title: { text: 'Número de Palavras por Tamanho' },
            xAxis: {
                categories: response.data.axis,
                title: { text: null }
            },
            yAxis: {
                min: 0,
                title: {
                    text: null,
                    align: 'middle'
                }
            },
            tooltip: {
                formatter: function() {
                    return '<b>'+ this.x +':</b> '+ this.y + ' entradas.';
                }
            },
            plotOptions: {
                series: {
                    borderWidth: 0,
                    shadow: false,
                    stacking: 'normal',
                }
            },
            legend:  { enabled: false },
            credits: { enabled: false },
          }
        };
      }  
      else {
        // FIXME handle error
      }
    });

  $http
    .get(API + '/stats/moderation')
    .then( function(response) {
      if (response.status === 200) {
        $scope.chart3Config = {
          series: response.data.data,
          options: {
            chart: {
                type: 'bar',
                margin: [70, 15, 50, 50]
            },
            title: { text: 'Estado do processo de Modernização' },
            xAxis: {
                categories: response.data.letters,
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'Nr de palavras'
                },
                stackLabels: {
                    enabled: true,
                    style: {
                        fontWeight: 'bold',
                        color: '#000099'
                    }
                }
            },
            legend: {
                align: 'center',
                verticalAlign: 'top',
                y: 20,
                backgroundColor: 'white',
                borderColor: '#CCC',
                borderWidth: 1,
                shadow: false
            },
            tooltip: {
                shared: true,
                borderColor: '#4572A7',
                formatter: function() {
                    var s = '<b>'+ this.x +'</b>';
                    $.each(this.points, function(i, point) {
                        s += '<br/>'+ point.series.name +': '+ point.y;
                    });
                    return s;
                }
            },
            credits: { enabled: false },
            plotOptions: {
                bar: {
                    borderWidth: 0,
                    shadow: false,
                    stacking: 'normal',
                }
            }
          }
        };
      }  
      else {
        // FIXME handle error
      }
    });

});
