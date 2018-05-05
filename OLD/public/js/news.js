
$( function() {
    jQuery.validator.addMethod("date", function(value, element) {
        return this.optional(element) || /^\d{4}-\d+-\d+ \d+:\d+:\d+$/i.test(value);
    }, "Caracteres inválidos!"); 
    $("#addNew").validate(
        {
            rules: {
                data: {
                    required: true,
                    date: true,
                },
                titulo: {
                    required: true,
                },
                texto: {
                    required: true,
                }
            },
            messages: {
                data: {
                    required: "Obrigatória!",
                    date: "<br/>Formato inválido. Use<br/><i>aaaa-mm-dd hh:mm:ss</i>",
                },
                titulo: {
                    required: "Obrigatório!",
                },
                texto: {
                    required: "Obrigatório!",
                },
            },
        }
    );
});

