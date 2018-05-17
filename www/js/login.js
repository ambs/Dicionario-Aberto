
function register_user() {
    var data = {
	username: $('#reg-username').val(),
	email: $('#reg-email').val(),
	name: $('#reg-nome').val()
    };

    shade_forms();

    $.ajax({
	url: 'https://api.dicionario-aberto.net/register',
	method: 'POST',
	data: JSON.stringify(data),
    }).done(function(ans){
	if ('status' in ans && ans.status == "OK") {
	    show_info_alert("Verifique o seu e-mail e siga as instruções indicadas.");
	} else {
	    show_warning_alert(ans.error);
	}
    }).fail(function(ans){
	show_danger_alert("Não foi possível ligar ao servidor. Por favor tente mais tarde.");	
    });
    
    return false;
}

function login_user() {
    var data = {
	username: $('#login-username').val(),
	password: $('#login-senha').val()
    };

    shade_forms();

    $.ajax({
	url: 'https://api.dicionario-aberto.net/login',
	method: 'POST',
	data: JSON.stringify(data),
    }).done( (ans) => {
	if ('status' in ans && ans.status == "OK") {
//	    GO('/');
	} else {
	    show_warning_alert(ans.error);
	}
    }).fail(
	() => { show_danger_alert("Não foi possível ligar ao servidor. Por favor tente mais tarde."); }
    ).always(
	(r, msg) => {
	    if (msg == "success") { GO('/'); }
	}
    );
    
    return false;
}


function recover_pass() {
    var token = $('#recover').val();

    shade_forms();
    
    $.ajax({
	url: 'https://api.dicionario-aberto.net/recover',
	method: 'POST',
	data: JSON.stringify({ recover: token })
    }).done(function(data){
	if ('status' in data && data.status == "OK") {
	    show_info_alert("Verifique o seu e-mail e siga as instruções indicadas.");
	} else {
	    show_warning_alert("Endereço ou nome do utilizador não existente.");
	}
    }).fail(function(data) {
	show_danger_alert("Não foi possível ligar ao servidor. Por favor tente mais tarde.");
    });
    

    return false;
}
