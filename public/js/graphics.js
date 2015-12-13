

$(document).ready(function() {

    $.post('/ajax/wordsByLetter', function(data) { 
        var chart = new Highcharts.Chart({
            chart: {
                renderTo: 'container-1',
                defaultSeriesType: 'column',
                margin: [30, 0, 30, 50]
            },
            title:    { text: 'Número de Palavras por Letra' },
            xAxis: {
                categories: data['axis'],
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
            series: [{
                name: '',
                data: data['values'],
            }]
        });
    });

    $.post('/ajax/wordsBySize', function(data) { 
        var chart2 = new Highcharts.Chart({
            chart: {
                renderTo: 'container-2',
                defaultSeriesType: 'column',
                margin: [30, 0, 30, 50]
            },
            title: { text: 'Número de Palavras por Tamanho' },
            xAxis: {
                categories: data['axis'],
                title: { text: null }
            },
            yAxis: {
                min: 0,
                max: 20000,
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
            legend:  { enabled: false },
            credits: { enabled: false },
            plotOptions: {
                series: {
                    borderWidth: 0,
                    shadow: false,
                    stacking: 'normal',
                }
            },
            series: [{
                name: '',
                data: data['values'],
            }]
        });
    });


    $.post('/ajax/wordModStatus', function(data) {
        var chart3 = new Highcharts.Chart({
            chart: {
                renderTo: 'container-3',
                defaultSeriesType: 'bar',
                margin: [70, 15, 50, 50]
            },
            title: { text: 'Estado do processo de Modernização' },
            xAxis: {
                categories: data['letters'],
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
            },
            series: data['data'],
        });
    });


    // $.post('/ajax/top10', function(data) { 
    //     chart3 = new Highcharts.Chart({
    //         chart: {
    //             renderTo: 'container-3',
    //             defaultSeriesType: 'bar',
    //             margin: [30, 13, 30, 90]
    //         },
    //         title:    { text: null },
    //         subtitle: { text: 'Palavras Mais Procuradas' },
    //         xAxis: {
    //             categories: data['axis'],
    //             title: { text: null }
    //         },
    //         yAxis: {
    //             min: 0,
    //             title: {
    //                 text: null,
    //                 align: 'middle'
    //             }
    //         },
    //         tooltip: {
    //             formatter: function() {
    //                 return '<b>'+ this.x +'</b> &mdash; '+ this.y + ' pesquisas';
    //             }
    //         },
    //         legend:  { enabled: false },
    //         credits: { enabled: false },
    //         series: [{
    //             name: '',
    //             data: data['values'],
    //         }]
    //     });
    // });


});
