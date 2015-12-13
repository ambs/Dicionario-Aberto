
$(function() {
    $('#em').ready(function(){
        $('#em').attr('size', $('#em').val().length * 1.1); // 10% more
    });
    $('#em').keypress(function(e){if(e.which == 13){$('#em').trigger('blur');}});
    $('#em').click(function(){$('#em').attr('readonly', false);});
    $('#em').blur(
        function() {
            $('#em').attr('readonly', true);
            $('#em').attr('size', $('#em').val().length * 1.1); // 10% more

            var email = $('#em').val();
            $.ajax({
                url: "/ajax/update_email", dataType: 'json', cache: false,
                data: { value: email },
                success: function(data) { 
                        // ... do nothing for now.
                },
                error: function(req, status, erro) { alert("Error:" + erro); },
            });
        }
    );




    $('#un').ready(function(){
        $('#un').attr('size', $('#un').val().length * 1.1); // 10% more
    });
    $('#un').keypress(function(e){if(e.which == 13){$('#un').trigger('blur');}});

    $('#un').click(function(){$('#un').attr('readonly', false);});

    $('#un').blur(
        function() {
            $('#un').attr('readonly', true);
            $('#un').attr('size', $('#un').val().length * 1.1); // 10% more

            var name = $('#un').val();
            $.ajax({
                url: "/ajax/update_name", dataType: 'json', cache: false,
                data: { value: name },
                success: function(data) { 
                        // ... do nothing for now.
                },
                error: function(req, status, erro) { alert("Error:" + erro); },
            });
        }
    );

    $('#pn').click(
        function() {

            var value = ($('#pn').attr('checked') && 1) || 0;

            $.ajax({
                url: "/ajax/public_name", dataType: 'json', cache: false,
                data: { "value": value, },
                success: function(data) { 
                    if (data.ok == '1') {
                        alert("O seu nome será apresentado junto a qualquer alteração ao dicionário por si efectuada.");
                    } else {
                        alert("Em vez do seu nome, apresentaremos o nome de utilizador junto a qualquer alteração ao dicionário por si efectuada.");
                    }
                },
                error: function(req, status, erro) { alert("Error:" + erro); },
            });
        }
    );
    
});
