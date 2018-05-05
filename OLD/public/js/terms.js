
$(document).ready(
    function() {
        $("#same_prefix div.def").toggle(400);
        
        $(".term h3").click(function() { $(this).next('.def').toggle(400); });
        
/*        $("#accordion").accordion({ header: 'div.header', autoHeight: false }); */
    });


$(document).ready(
    function() {
        $('#search').focus();
    }
);


