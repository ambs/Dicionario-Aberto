
// ...

$(function() {


    var timer = null;

    $('#word').keyup(
        function(e) {
            if (e.which == 13) {
                $('#pesquisa').submit();
            } else {
                if (e.which >= 40) {
                    clearTimeout(timer);
                    timer = setTimeout(send, 2000);
                }
            }
        }
    );

    function send() {
        var ss = $('#word').val();
        if (ss.length >= 2) {
            $.ajax({
                type: "POST",
                url: "/ajax/ss",
                data: {
                    type: $('input:radio[name=advanced_type]:checked').val(),
                    word: ss
                },
                success: function(answer) {
                    if (answer.ans) {
                        $('#ans_preview').html(answer.ans);
                        $('#download_floater').hide();
                    }
                }
            });
        } else {
            $('#ans_preview').html("<div>Pesquisa demasiado curta</div>");
        }
    }

});
