package DA::Users;

use Digest::MD5 'md5_hex';

my $database;
my $EMAIL;
sub database { return $database; }
sub set_database { $database = $_[0]; }
sub set_email { $email = $_[0]; }

sub adicionar_favorito {
    my $date     = _now();
    my ($self, $user, $wid) = @_;
    database->do("INSERT INTO favourite VALUES(?, ?, ?)" .
                 "ON DUPLICATE KEY UPDATE timestamp = ?", {},
                 $user, $date, $wid, $date);
}

sub remover_favorito {
    my ($self, $user, $wid) = @_;
    database->quick_delete('favourite', { username => $user,
                                          word_id  => $wid });
}

sub nome_publico {
    my ($self, $user, $val) = @_;
    database->do("UPDATE user SET name_public = ? WHERE username = ?", {}, $val, $user);
    $val;
}

sub alterar_nome {
    my ($self, $user, $val) = @_;
    database->do("UPDATE user SET name = ? WHERE username = ?", {}, $val, $user);
    $val;
}

sub alterar_email {
    my ($self, $user, $val) = @_;
    database->do("UPDATE user SET email = ? WHERE username = ?", {}, $val, $user);
    $val;
}

sub favoritos {
    my ($self, $user) = @_;
    return database->selectall_arrayref("SELECT word, sense AS n FROM word INNER JOIN favourite ON word.word_id = favourite.word_id WHERE username = ?", { Slice => {} }, $user);
}

sub alterarSenhaToken {
    my ($self, $token, $pass) = @_;
    $pass = md5_hex($pass);

    my $restore = database->quick_select('user_restore', { md5 => $token });

    my $role = database->quick_select('role', { role_name => "user" });

    if ($restore) {
        if ($restore->{new} == 1) {
            database->quick_insert('user',
                                   {
                                    username => $restore->{user},
                                    password => $pass,
                                    email    => $restore->{email},
                                    name     => $restore->{name},
                                    name_public => false,
                                    created  => $restore->{requested},
                                    role_id  => $role->{role_id},
                                    banned   => false,
                                   });
        } else {
            database->quick_update('user',
                                   { username => $restore->{user} },
                                   { password => $pass });
        }
        database->quick_delete('user_restore', { md5 => $token });
    }
}

sub alterarSenha {
    my ($self, $user, $pass) = @_;
    $pass = md5_hex($pass);

    database->quick_update('user',
                           { username => $user },
                           { password => $pass });
}

sub tokenValido {
    my ($self, $token) = @_;
    return database->quick_select('user_restore', { md5 => $token }) ? true : false;
}

sub existe {
    my ($self, $user) = @_;

    return database->quick_select( user => { username => $user }) ? true : false;
}

sub existeUserOrEmail {
    my ($self, $recover) = @_;
    if ($recover =~ /@/) {
        database->quick_select( user => { email => $recover }) ? true : false
    } else {
        database->quick_select( user => { username => $recover }) ? true : false
    }
}



sub record {
    my ($self, $user) = @_;

    my $reg = database->selectall_arrayref(
      "SELECT * FROM user INNER JOIN role ON user.role_id = role.role_id WHERE username = ?",
                                 { Slice => {} }, $user);
    $reg->[0];
}

sub gereNoticias {
    my ($self, $user) = @_;
    my $data = $self->record($user);
    return $data->{manage_news};
}

sub moderaRevisoes {
    my ($self, $user) = @_;
    my $data = $self->record($user);
    return $data->{moderate_revision};
}

sub recuperar {
    my ($self, $recover) = @_;

    my @users; # use an array, as the same email can have multiple users
    if ($recover =~ /@/) {
        @users = database->quick_select( user => { email => $recover });
    } else {
        @users = database->quick_select( user => { username => $recover });
    }
    return unless @users;

    for my $user (@users) {
        my $username = $user->{username};
        my $md5 = md5_hex("$username ".localtime);
        database->quick_delete('user_restore', { user => $username });
        database->quick_insert('user_restore',
                               {
                                md5   => $md5,
                                user  => $username,
                                new   => 0,
                                email => $user->{email},
                                name  => ""
                               });
        $EMAIL->({
                from => "hashashin\@gmail.com",
                to => $user->{email},
                subject => "[Dicionário Aberto] Alteração da senha de $username",
                message => _msg_change_pass($username, $md5),
        });
    }
}

sub registar {
    my ($self, $username, $email, $name) = @_;
    my $md5 = md5_hex("$username ".localtime);

    database->quick_delete('user_restore', { user => $username });

    database->quick_insert('user_restore',
                           {
                            md5   => $md5,
                            user  => $username,
                            new   => 1,
                            email => $email,
                            name  => $name
                           });

    $EMAIL->({
            from => "hashashin\@gmail.com",
            to => $email,
            subject => "[Dicionário Aberto] Novo utilizador $username",
            message => _msg_change_pass($username, $md5),
           });
}

sub _msg_change_pass {
    my ($user, $md5) = @_;
    my $host = request->host();
    <<"EOT";
Caríssimo,

Para confirmar/alterar a senha do seu utilizador ($user) aceda ao seguinte endereço:
  http://$host/confirm/$md5

Obrigado,

A equipa do Dicionário Aberto.
EOT
}

sub autenticado {
    my ($self, $user, $pass) = @_;
    $pass = md5_hex $pass;

    return database->quick_select( user => { username => $user,
                                             password => $pass,
                                             banned   => 0 }) ? true : false;
}

sub reportado {
    my ($self, $user) = @_;

    return database->quick_select( reported_used => { username => $user,
                                                      closed   => 0 } ) ? true : false;
}




sub _now {
    my @date = localtime(time);

    $date[5]+=1900;
    $date[4]++;
    sprintf "%4d-%02d-%02d %02d:%02d:%02d", $date[5], $date[4], $date[3], $date[2], $date[1], $date[0];
}


21; # half the truth
