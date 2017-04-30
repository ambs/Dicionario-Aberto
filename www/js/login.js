
function recover_pass() {
    var token = $('#recover').val();

    $.ajax({
	url: 'http://api.dicionario-aberto.net/recover',
	method: 'POST',
	data: { recover: token }
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
