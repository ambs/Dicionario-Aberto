package DA;

use DateTime::Format::MySQL;

use DA::Database;
use DA::Users;

use Dancer2;
use Dancer2::Plugin::Feed;
use Dancer2::Plugin::Emailesque;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::Database;


DA::Database::set_database(database);
DA::Users::set_database(database);
DA::Users::set_email(\&_email);

sub _email {
    email $_[0];
}

our $VERSION = '0.1';

hook 'before_template' => sub {
    my $tokens = shift;

    $tokens->{count} = myformat(database->quick_select( metadata => { key => "count"  } )->{value});
    $tokens->{first_word} = database->quick_select( metadata => { key => "first_word" } )->{value};
    $tokens->{last_word}  = database->quick_select( metadata => { key => "last_word"  } )->{value};

    $tokens->{collapsed}  = ((cookie('collapsed') || 'no') eq 'yes');
    $tokens->{query}      = (request->{path} ne "/browse") ? '/search' : '/browse';
};

any ['get','post'], '/search' => sub {
    return redirect '/' unless param 'word';
    my $w = param 'word';
    redirect "/search/$w"
};

any ['get','post'], '/search/:word' => sub {

    return redirect '/' unless param 'word';

    my $word    = lc(param('word'));
    my $sense   = param("sense") || 0;

    $word =~ s/:(\d+)$// and $sense = $1;
    my @revision = param("revision") ? ( revision => param("revision")) : ();

    my $nmiss   = DA::Database->generateNearMisses($word);
    my $entries = DA::Database->htmlEntries($word,
                                            sense    => $sense,
                                            @revision,
                                            username => session('username'));
    my $sprefix = DA::Database->htmlEntries($word,
                                            sameprefix => 1,
                                            username => session('username'));
    my $userdata = DA::Users->record(session("username"));
    my $t = template search => {
                        word         => $word,
                        nearmisses   => $nmiss,
                        entries      => $entries,
                        sameprefixes => $sprefix,
                        user         => $userdata,
                       };
    return $t;
};

any ['get','post'], '/search-json/:word' => sub {
    my $word    = lc(param('word'));
    my $sense   = 0;
    $word =~ s/:(\d+)$// and $sense = $1;
    my @entries = DA::Database->xmlEntries($word, sense => $sense);

    if (@entries) {
        my $str = "<dic>\n";
        if (@entries > 1) {
            $str .= "<superEntry>\n" . join("\n" => @entries) . "</superEntry>\n";
        } else {
            $str .= $entries[0];
        }
        $str .= "</dic>\n";
        content_type('json');
        header "Access-Control-Allow-Origin" => '*';
        _prefixa(DA::Database->_to_json($str));
    } else {
        return _404();
    }
};

any ['get','post'], '/search-xml/:word' => sub {
    my $word    = lc(param('word'));
    my $sense   = 0;
    $word =~ s/:(\d+)$// and $sense = $1;
    my @entries = DA::Database->xmlEntries($word, sense => $sense);

    if (@entries) {
        my $str = "<dic>\n";
        if (@entries > 1) {
            $str .= "<superEntry>\n" . join("\n" => @entries) . "</superEntry>\n";
        } else {
            $str .= $entries[0];
        }
        $str .= "</dic>\n";
        content_type('xml');
        join ("\n", '<?xml version="1.0" encoding="UTF-8"?>', $str);
    } else {
        return _404();
    }
};

any ['get','post'], '/search-xml' => sub {
    my $words;
    if (param("prefix") || param("suffix")) {
        $words = DA::Database->getWords
          (
           param("prefix") ? (prefix => param("prefix")) : (),
           param("suffix") ? (suffix => param("suffix")) : ()
          );
    } elsif (param("like")) {
        $words = DA::Database->generateNearMisses( param("like"),
                                                   includeself => 1);
    } elsif (param("random")) {
        my $random = param("random");
        $random = 1 unless $random =~ /^\d+$/;
        $random = 20 if $random > 20;

        if ($random == 1) {
            my ($word, $sense) = database->selectrow_array("SELECT word, sense FROM word ORDER BY rand() LIMIT 1");
            my @entry = DA::Database->xmlEntries($word, sense => $sense);
            my $str = "<dic>\n";
            $str .= $entry[0];
            $str .= "</dic>\n";
            content_type('xml');
            return join ("\n", '<?xml version="1.0" encoding="UTF-8"?>', $str);
        } else {
            my $words = database->selectall_arrayref
              ("SELECT word FROM word ORDER BY rand() LIMIT $random", {Slice => {}});

            use Data::Dumper;
            content_type('xml');
            return join ("\n",
                  '<?xml version="1.0" encoding="UTF-8"?>',
                  '<list>',
                  map( { "<entry>$_->{word}</entry>" } @$words),
                  '</list>');
        }
    } else {
        return _404();
    }
    content_type('xml');
    my @w = grep defined, @{$words}[0..9];
    join ("\n",
          '<?xml version="1.0" encoding="UTF-8"?>',
          '<list>',
          map( { "<entry>$_</entry>" } @w),
          '</list>');
};

any ['get','post'], '/search-json' => sub {
    my $words;
    if (param("prefix") || param("suffix")) {
        $words = DA::Database->getWords
          (
           param("prefix") ? (prefix => param("prefix")) : (),
           param("suffix") ? (suffix => param("suffix")) : ()
          );
    } elsif (param("like")) {
        $words = DA::Database->generateNearMisses( param("like"),
                                                   includeself => 1);
    } elsif (param("random")) {
        my ($word, $sense) = database->selectrow_array("SELECT word, sense FROM word ORDER BY rand() LIMIT 1;");
        my @entry = DA::Database->xmlEntries($word, sense => $sense);
        my $str = "<dic>\n";
        $str .= $entry[0];
        $str .= "</dic>\n";
        content_type('json');
        return _prefixa(DA::Database->_to_json($str));
    } else {
        return _404();
    }
    content_type('json');
    my @w = grep defined, @{$words}[0..9];
    _prefixa(to_json( { list => \@w }));
};

any ['get','post'], '/advanced' => sub {
    return redirect '/' unless session('username');

    my $userdata = DA::Users->record(session("username"));

    if (param('advanced_type') && param("word") && length(param('word'))>=2) {
        my $query = param('word');
        my $type = param('advanced_type');
        my $results;

        if ($type eq "reverse") {
            my @words = split /\s+/, $query;
            $results = DA::Database->revsearch(\@words);
        } elsif ($type eq "ontology") {
            my @words = split /\s+/, $query;
            $results = DA::Database->ontsearch(\@words);
        } else {
            $results = DA::Database->affixes($type, $query);
        }
        $results = DA::Database::_format_adv_search($results);

        template advanced => {
                              user     => $userdata,
                              advanced => 1,
                              results  => $results,
                              type     => $type,
                              word     => $query,
                             }
    } else {
        template advanced => {
                              user     => $userdata,
                              type     => "prefix",
                              advanced => 1,
                             }
    }
};

get '/tei/:type/:affix' => sub {
    return redirect '/' unless session('username');
    my ($type, $affix) = (param("type"), param("affix"));
    return "" if length($affix) < 2;

    my $str = "<dic>\n";
    if ($type eq "reverse") {
        $str .= join("\n", map { $_->{xml} } @{DA::Database->revsearch_in_xml([split /\s+/, $affix])});
    } else {
        $str .= join("\n", map { $_->{xml} } @{DA::Database->affixes_in_xml($type, $affix)});
    }
    $str .= "</dic>\n";
    content_type('xml');
    join("\n", '<?xml version="1.0" encoding="UTF-8"?>', $str);
};

get '/txt/:type/:affix' => sub {
    return redirect '/' unless session('username');
    my ($type, $affix) = (param("type"), param("affix"));
    return "" if length($affix) < 2;

    my $str = "";
    if ($type eq "reverse") {
        $str .= join("\n\n", map { DA::Database->_xml2txt($_->{xml}) }
                     @{DA::Database->revsearch_in_xml([split /\s+/, $affix])});
    } else {
        $str .= join("\n\n", map { DA::Database->_xml2txt($_->{xml}) }
                     @{DA::Database->affixes_in_xml($type, $affix)});
    }
    content_type('text/plain');
    $str;
};

any ['get','post'], '/browse' => sub {

    my $total = DA::Database->idxSize;
    my ($position, $sth, $id, $word, @words, $sense);
    if (param("count")) {
        $position = _clamp(param("count"), 1, $total);
    } elsif(param("random")) {
        $position = rand($total) + 1;
    } else {
        $position = int($total/2);
    }

    if (param("word")) {
        $word = _norm(param("word"));
        $word =~ s/:(\d+)$// and $sense = $1;
        $sth = database->prepare(
             "SELECT word FROM word WHERE normalized >= ? ORDER BY normalized LIMIT 1");
        $sth->execute($word);
        ($word) = $sth->fetchrow_array;

        $sth = database->prepare("SELECT idx FROM browse_idx WHERE word = ?");
        $sth->execute($word);
        ($position) = $sth->fetchrow_array;
    }

    if (param("letter")) {
        my $l = lc(param("letter"));
        my $ll = "$l%";
        $sth = database->prepare(
            "SELECT idx FROM browse_idx WHERE word = ? OR word LIKE ? ORDER BY idx LIMIT 1");
        $sth->execute($l, $ll);
        ($position) = $sth->fetchrow_array;
    }

    my $margin = 15;
    my $lower  = $position - $margin;
    my $higher = $position + $margin;
    my $range  = ($margin - 1) * 2 + 1;

    $sth = database->prepare(
             "SELECT idx, word FROM browse_idx WHERE idx > ? AND idx < ? ORDER BY idx");
    $sth->execute($lower, $higher);

    push @words, [$id => $word] while ($id => $word) = $sth->fetchrow_array;
    if (@words < $range) {
        if ($words[0][0] == 1) {
            unshift @words, undef while @words < $range;
        } else {
            push @words, undef while @words < $range;
        }
    }
    my $cword   = $words[$margin-1][1];
    my $cletter = uc(substr(_norm(lc($cword)), 0, 1));
    my $userdata = DA::Users->record(session("username"));
    my @revision = param("revision") ? ( revision => param("revision")) : ();
    template browse => {
                        letters  => ['A'..'Z'],
                        cletter  => $cletter,
                        position => $position,
                        total    => $total,
                        words    => \@words,
                        user     => $userdata,
                        entries  => DA::Database->htmlEntries(
                                         $cword,
                                         @revision,
                                         username => session('username'),
                                         sense => $sense),
                        margin   => $margin,
                       };
};

any ['get','post'], '/browse/:word' => sub {
    forward '/browse'
};

any ['get','post'], '/random' => sub {
    my ($word) = database->selectrow_array("SELECT word FROM word ORDER BY rand() LIMIT 1;");
    return forward '/search' => { word => $word };
};

any ['get','post'], '/brandom' => sub {
    return forward '/browse' => { random => 1 };
};

post '/login' => sub {
    forward '/login', {}, { method => 'GET' } unless param('action');

    if (param('action') eq 'login') {
        my $username = param 'username';
        my $password = param 'password';

        if (DA::Users->autenticado($username, $password)) {
            session username => $username;
            deferred ok => "Boas-Vindas, $username!";
            return redirect '/';
        } else {
            deferred error => "Senha ou utilizador inválidos.";
            return forward '/login', {}, { method  => "get" };
        }
    }
    if (param('action') eq 'register') {
        my $username = param 'username';
        my $email    = param 'email';
        my $name     = param 'nome';

        DA::Users->registar($username, $email, $name);

        deferred ok => "Registo efectuado. Consulte o seu e-mail.";
        return redirect '/';
    }
    if (param('action') eq 'recover') {
        DA::Users->recuperar(param 'recover');

        deferred ok => "Receberá um e-mail para alterar a password em breve.";
        return redirect '/';
    }
    forward '/login', {}, { method => 'GET' };
};

get '/passwd' => sub {
    return forward '/' unless session('username');
    template token => { username => session('username') };
};

get  '/confirm/:token' => sub {
    if (DA::Users->tokenValido(param('token'))) {
        template 'token' => { token => param('token') }
    } else {
        deferred error => "Pedido de alteração de senha expirado. Faça novo pedido!";
        return redirect '/';
    }
};

post '/confirm' => sub {
    return forward '/', {}, { method => 'get' } unless (param('token') && param('pass1'))
                                                     || (param("user") && param('pass1'));
    if (param("token")) {
        DA::Users->alterarSenhaToken(param('token') => param('pass1'));
        deferred ok => "Senha alterada com sucesso!";
        return forward '/', { }, { method => 'get' };

    } elsif (param('user') eq session('username')) {
        DA::Users->alterarSenha(param('user') => param('pass1'));
        deferred ok => "Senha alterada com sucesso!";
        return forward '/profile', { }, { method => 'get' };

    } else {
        return forward '/', {}, { method => 'get' };
    }
};

get '/favourites' => sub {
    return forward '/' unless session('username');

    template favourites =>
      {
       favs => DA::Users->favoritos(session('username')),
      };
};

get '/profile' => sub {
    return forward '/' unless session('username');

    my $user = DA::Users->record(session('username'));

    my $gravatar = gravatar_url(email => $user->{email});

    template 'profile' => {
                           username    => session('username'),
                           user        => $user,
                           gravatar    => $gravatar,
                          };
};

get '/' => sub {
	template 'mainmenu' => { news => get_news(4) }
};

get '/news'   => sub { template 'news'     => { news => get_news() }  };

get '/stats'  => sub {
	template 'stats'
};

get '/login'  => sub { template 'login'                               };

get '/logout' => sub {
    session username => undef;
    deferred ok => "Até à próxima!";
    redirect '/'
};

get '/news.xml' => sub {
    my $entries = get_news(10);
    for (@$entries) {
        $_->{id}     = $_->{idnew};
        $_->{author} = $_->{user};
        $_->{issued} = DateTime::Format::MySQL->parse_datetime($_->{fulldate});
        $_->{content} = $_->{text};
        delete $_->{idnew};
        delete $_->{user};
        delete $_->{date};
        delete $_->{text};
    }
    my $feed = create_feed entries => $entries;
    use Encode;
    decode_utf8($feed, Encode::FB_CROAK),
};

get '/moderar_revisoes' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->moderaRevisoes(session('username'));
    template moderate_revisions => { words => DA::Database->revisions2moderate() };
};

get '/moderar_revisoes/next' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->moderaRevisoes(session('username'));
    my $word = DA::Database->revisions2moderate( "one" => 1)->[0];

    redirect "/moderar_revisao/$word->{word}:$word->{sense}?rev=$word->{revision_id}";
};

any ['get','post'], '/moderar_revisao/:word' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->moderaRevisoes(session('username'));
    return forward '/' unless param('rev');

    my $word = param 'word';
    $word =~ s/:(\d+)//;
    my $sense = $1 || 1;
    my $revision = param 'rev';

    my $wid = DA::Database->word_id($word, $sense);
    return forward '/' unless DA::Database->canBeModerated($wid, $revision);

    if (param('delete')) {
        DA::Database->delete_revision($word, $sense, $revision, session('username'));
        DA::Database->update_last_revision($wid);
        deferred ok => "<b>Apagada</b> a revisão $revision da palavra $word<sup>$sense</sup>!";
        redirect '/moderar_revisoes/next';

    } elsif (param('approve')) {
        return redirect '/' unless param('xml');
        DA::Database->moderate($wid, $revision, param('xml'), session('username'));
        deferred ok => "<b>Aprovada</b> a revisão $revision da palavra $word<sup>$sense</sup>!";
        redirect '/moderar_revisoes/next';

    } else {
        template 'moderate_revision' =>
          {
           word => $word,
           sense => $sense,
           revision => $revision,
           xml  => DA::Database->fetch_xml_revision($word, $sense, $revision),
           diff => DA::Database->diff(word  => $word,
                                                    sense => $sense,
                                                    to    => $revision)
          }
      }
};

post '/gerir_novidades' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->gereNoticias(session('username'));
    if (param('id') == 0) { # nova
        DA::News->new(param('user'), param('data'), param('titulo'), param('texto'));
    } else {
        DA::News->update
            (param('id') => param('user'), param('data'), param('titulo'), param('texto'));
    }
    deferred ok => "Notícia gravada!";
    redirect '/gerir_novidades';
};

get '/gerir_novidades' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->gereNoticias(session('username'));
    my $new;
    if (param('edit')) {
        $new = DA::News->id(param('edit'));
    }
    template manage_news =>
      {
       news  => get_news(),
       new   => $new,
       today => DA::Users::_now(),
      };
};

get '/gerir_novidades/:action/:id' => sub {
    return forward '/' unless session('username');
    return forward '/' unless DA::Users->gereNoticias(session('username'));
    return forward '/' unless param('action') eq 'apagar' || param('action') eq 'editar';
    if (param('action') eq "apagar") {
        DA::News->delete(param('id'));
        deferred ok => "Notícia apagada!";
        return redirect '/gerir_novidades';
    }
    if (param('action') eq "editar") {
        return forward '/gerir_novidades' => { edit => param('id') };
    }
};


prefix "/ajax" => sub {
    post "/ss" => sub {
        content_type "json";
        my $query = _safe_like(param("word") || "");
        length($query) < 2 and return to_json { ans => "<div>Pesquisa demasiado curta</div>" };
        my $ans = [];
        if (param('type') eq "reverse") {
            my @words = split /\s+/, $query;
            $ans = DA::Database->revsearch(\@words => 20);
        } else {
            $ans = DA::Database->affixes(param('type'), $query => 20);
        }
        DA::Database->adv_ans_to_json($ans);
    };


	post "/wordModStatus" => sub {
        content_type "json";
        to_json(DA::Database->moderation_stats());
    };

    post "/wordsByLetter" => sub {
        my $ans = database->selectall_arrayref("SELECT substr(normalized,1,1) AS letter, COUNT(word) FROM word GROUP BY letter ORDER BY letter;");
        my $data;
        while (my $pair = shift(@$ans)) {
            push @{$data->{axis}}   => $pair->[0];
            push @{$data->{values}} => $pair->[1]*1;
        }
        content_type "json";
        to_json($data);
    };

    post "/wordsBySize" => sub {
        my $ans = database->selectall_arrayref("SELECT tamanho,COUNT(tamanho) FROM (SELECT LENGTH(word) AS tamanho FROM word) AS tamanhos GROUP BY tamanho ORDER BY tamanho;");
        my $data;
        while (my $pair = shift(@$ans)) {
            push @{$data->{axis}}   => $pair->[0]*1;
            push @{$data->{values}} => $pair->[1]*1;
        }
        content_type "json";
        to_json($data);
    };    

    get '/userAvailable' => sub {
        DA::Users->existe(param 'username') ? 'false' : 'true';
    };

    get '/userOrEmailExists' => sub {
        DA::Users->existeUserOrEmail(param 'recover') ? 'true' : 'false';
    };

    get '/favourites' => sub {
        my $action   = param('task');
        if (session('username') && ($action eq "add" || $action eq "remove")) {

            $action eq "add" and DA::Users->adicionar_favorito(session('username') => param('wid'));

            $action eq "remove" and
              DA::Users->remover_favorito(session('username') => param('wid'));

            my $nr = DA::Database::_nr_favourites(param('wid'));
            my $msg = $nr == 1 ? "$nr favorito" : "$nr favoritos";
            content_type 'json';
            to_json { ok => $msg };
        } else {
            content_type 'json';
            to_json { error => "unknown command [$action]" };
        }

    };

    get '/public_name' => sub {
        if (session('username') && defined(param('value'))) {
            my $v=DA::Users->nome_publico(session('username'), param('value'));
            content_type 'json';
            to_json { ok => $v };
        } else {
            content_type 'json';
            to_json { error => "illegal operation" };
        }
    };

    get '/update_name' => sub {
        if (session('username') && defined(param('value'))) {
            my $v=DA::Users->alterar_nome(session('username'), param('value'));
            content_type 'json';
            to_json { ok => $v };
        } else {
            content_type 'json';
            to_json { error => "illegal operation" };
        }
    };
    get '/update_email' => sub {
        if (session('username') && defined(param('value'))) {
            my $v=DA::Users->alterar_email(session('username'),param('value'));
            content_type 'json';
            to_json { ok => $v };
        } else {
            content_type 'json';
            to_json { error => "illegal operation" };
        }
    };
};

prefix "/estaticos" => sub {
    get "/api.html"     => sub { template 'statics/api'     };
    get "/sources.html" => sub { template 'statics/sources' };
    get "/about.html"   => sub { template 'statics/about'   };
    get "/intro.html"   => sub { template 'statics/intro'   };
    get "/abrev.html"   => sub { template 'statics/abrev'   };
    get "/geo.html"     => sub { template 'statics/geo'     };
    get "/legal.html"   => sub { template 'statics/legal'   };
};

sub get_news {
    my ($n) = @_;
    $n = $n ? "LIMIT $n" : "" ;
    my $r = database->selectall_arrayref("SELECT * FROM new ORDER BY date DESC $n;",
                                         { Slice => {} });
    for (@$r) {
        $_->{fulldate} = $_->{date};
        $_->{date} =~ s/\s+\d{2}:\d{2}:\d{2}$//;
    }
    return $r;
}

sub myformat {
    my ($number) = @_;
    $number =~ s/(\d)(\d{3})($| )/$1 $2$3/g;
    return $number;
}

sub _clamp {
    my ($val, $min, $max) = @_;
    $val = $min if $val < $min;
    $val = $max if $val > $max;
    return $val;
}

sub _norm {
  my $word = shift;
  $word =~ s!\.!!g;
  $word =~ y{áéíóúàèìòùãõâêîôûçÿïýĩẽüũ}
            {aeiouaeiouaoaeioucyiyieuu};
  return $word;
}

sub _safe_like {
    my $s = shift;
    $s =~ s/[_%]//g;
    return $s;
}


sub _prefixa {
    my $s = shift;
    if (param("jsonp")) {
        return param("jsonp")."($s)"
    } elsif (param("callback")) {
        return param("callback")."($s)"
    } else {
        return $s;
    }
}

sub _404 {
    send_error("Not found" => 404);
}


true;
