package DA::API;

use DA::Database;

use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Emailesque;
use Dancer2::Plugin::JWT;
use Regexp::Common qw[Email::Address];
use Email::Address;

our $VERSION = '0.1';
our $host = "http://novo.dicionario-aberto.net";
our $DIC = DA::Database->new(sub { database });

set serializer => 'JSON'; # Dancer2::Serializer::JSON

hook after => sub {
#    response->push_header('Access-Control-Expose-Headers', 'Authorization');
    response->push_header('Access-Control-Allow-Origin', "*");
};

hook 'plugin.jwt.jwt_exception' => sub {
    my $msg = shift;
    debug $msg;
    redirect "/index.html";
};

get '/' => sub {
    redirect "/index.html";
};

# 185.130.5.247
# 
post '/xmlrpc.php' => sub {
	error ("FUCK THIS GUY, PLEASE! ", request->address);
	"FUCK YOU";
};

get '/news' => sub {
    if (param('limit')) {
	return($DIC->retrieve_news(limit => param('limit')));
    } else {
	return($DIC->retrieve_news);			
    }
};

get '/word/**' => sub {
	my ($x) = splat;
	my $word = $x->[0];
	my $sense = $x->[1];

	return $DIC->retrieve_entry($word, $sense);
};

get '/near/*' => sub {
	my ($word) = splat;
	return $DIC->near_misses($word);
};

get qr'/browse/(\d+)' => sub {
	my ($idx) = splat;
    return $DIC->get_browse_range($idx);
};

get '/browse/:letter' => sub {
  my ($letter) = param('letter');

  my $idx = $DIC->get_browse_letter_position($letter);

  return $DIC->get_browse_range($idx);
};

get '/random' => sub {
    my ($wid, $word, $sense) = $DIC->random();
    return { word => $word, wid => $wid , sense => $sense};
};

get '/wotd' => sub {
	return { xml => $DIC->wotd };
};

get '/new/*' => sub {
	my ($id) = splat;
	if ($id !~ /^\d+$/) {
		return my_error('invalid new identifier');
	}
	else {
		return $DIC->retrieve_news( id => $id );
	}
};

get '/stats/size' => sub {
	return $DIC->words_by_size();
};

get '/stats/moderation' => sub {
	return $DIC->moderation_stats();
};

get '/stats/letter' => sub {
	return $DIC->words_by_letter();
};

get '/metadata/*' => sub {
	my ($key) = splat;
	push_response_header 'Cache-control' => 'public, max-age=31536000';
	return { $key => $DIC->metadata($key) };
};

post '/recover' => sub {
    my $data = param "recover";

    if ($data) {
	my $recover_data = $DIC->recover_password($data);
	if ($recover_data) {
	    email { to => $recover_data->{email},
		    from => 'hashashin@gmail.com',
		    subject => "[Dicionário Aberto] Recuperação de senha",
		    message => _msg_change_pass($recover_data->{'username'},
						$recover_data->{'md5'}) };
	    return OK();
	}
	else {
	    return my_error("not found");
	}
    }
    else {
	return my_error("no info");
    }    
};

post '/register' => sub {
    my $data = _params(qw.username email name.);

    if (_is_email($data->{email}) && length($data->{username}) >= 2) {
	my $ans = $DIC->register_user($data);
	if ($ans) {
	    email { to => $ans->{email},
		    from => 'hashashin@gmail.com',
		    subject => "[Dicionário Aberto] Confirmação de Registo",
		    message => _msg_change_pass($ans->{'username'},
						$ans->{'md5'}) };
	    
	    return OK();
	};
	return my_error("E-mail ou utilizador já registado!");
    }
    else {
	return my_error("Utilizador demasiado curto ou e-mail inválido!");
    }
};

post '/login' => sub {
    my $data = _params(qw.username password.);

    if (length($data->{username}) && length($data->{password})) {
	my $info;
	if ($info = $DIC->authenticate($data->{username}, $data->{password})) {

	    jwt $info;
	    return OK();
	}
	debug "error";
	return my_error("Nome do utilizador ou palavra chave inválidos.");
    }
    return my_error("Por favor preencha ambos os campos.");
};


sub _is_email {
    my $email = shift;
    return $email =~ /^$RE{Email}{Address}$/;
}

sub _params {
    return { map { ( $_ => param($_)) } @_ };
}

#post '/auth' => sub {
	#my ($password, $username) = (param ("password"), param ("username"));
#
	#if ($DIC->authenticate($username, $password)) {
		#jwt { username => $username };
		#return { success => "User $username authenticated"};
	#} else {
		#jwt {};
		#return { error => "Invalid user/password"};
	##}
#};

sub OK {
    return { status => 'OK' };
}

sub _msg_change_pass {
    my ($user, $md5) = @_;
    <<"--";
Bom Dia,

Para confirmar/alterar a senha do seu utilizador ($user) aceda ao seguinte endereço:
  $host/confirm/$md5

Obrigado,

A equipa do Dicionário Aberto.
--
};

sub my_error {
    my $error = shift;
    return { error => $error };
};

true;
