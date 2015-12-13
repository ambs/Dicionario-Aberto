    /*
                 txtConfirmPassword: {
                     required: true,
                     equalTo: "#txtPassword",
                     minlength: 4,
                     maxlength: 32
                 },
    */


$( function() {
    jQuery.validator.addMethod("alphanumeric", function(value, element) {
        return this.optional(element) || /^[-a-z0-9_.]+$/i.test(value);
    }, "Caracteres inválidos!"); 
    jQuery.validator.addMethod("lowercase", function(value, element) {
        return this.optional(element) || /^[-a-z0-9_.]+$/.test(value);
    }, "Não use maiúsculas!"); 

    $("#tokenpass").validate(
        {
            rules: {
                'pass1': { required: true },
                'pass2': { required: true,
                           equalTo: "#pass1" },
            },
            messages: {
                'pass1': { required: "" },
                'pass2': { required: "", 
                           equalTo: "<br/>As senhas introduzidas são diferentes." },
            },
        }
    );

    $("#recoverForm").validate(
        {
            rules: { recover: { required: true, remote: "/ajax/userOrEmailExists" }},
            messages: { recover: {
                required: "",
                remote: "<br/>Nenhum utilizador com esse nome de utilizador ou e-mail."
            }}
        }
    );
    $("#registerForm").validate(
        {
            rules: {
                username: {
                    required: true,
                    alphanumeric: true,
                    lowercase: true,
                    remote: "/ajax/userAvailable",
                },
                email: {
                    required: true,
                    email: true,
                },
            },
            messages: {
                username: {
                    required: "Obrigatório!",
                    remote: "Indisponível!",
                },
                email: {
                    required: "Obrigatório!",
                    email: "Inválido!",
                },
            },
        }
    );
});

