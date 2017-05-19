package DA::Database;

use 5.006;
use strict;
use warnings;

use utf8;

use Scalar::Util qw.blessed.;
use Digest::MD5 'md5_hex';
use DBI;

=head1 NAME

DA::Database - Module to manage Dicionario-Aberto DB

=head1 SYNOPSIS

    use DA::Database;

    my $dic = DA::Database->new($dbh);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new Dicionário-Aberto access object.

=cut

our @LETTERS = qw!a b c d e f g h i j k l m n o p q r s t u v w x y z
                  ã õ á é í ó ú à è ì ò ù â ê î ô û ç ä ë ï ö ü ÿ ý ũ ẽ -!;

sub new {
	my $class = shift;

	my $self = bless {}, $class;

	my $thing = shift;


	if (ref($thing) eq "CODE") {
		$self->{dbh_sub} = $thing;
	}
	elsif (blessed($thing) && $thing->can("prepare")) {
		$self->{dbh} = $thing;
	} 
	else {
		$self->{dbh} = DBI->connect($thing, @_);
	}

	return bless $self, $class;
}

sub dbh {
	my ($self) = shift;

	if (exists($self->{dbh_sub})) {
		return $self->{dbh_sub}->();
	}
	if (exists($self->{dbh})) {
		return $self->{dbh};
	}
	die "no DBH?";
}

sub random {
	my ($self) = @_;
	my $sth = $self->dbh->prepare(<<"---");
 SELECT word_id, word, sense FROM word WHERE deleted=0 ORDER BY rand() LIMIT 1
---
	$sth->execute();
	my ($wid, $word, $sense) = $sth->fetchrow_array;
		           
	return ($wid, $word, $sense);
}

sub revision_from_wid {
	my ($self, $wid) = @_;

	my $sth = $self->dbh->prepare(<<"---");
 SELECT `xml` FROM `word` INNER JOIN `revision` 
     ON `word`.`word_id` = `revision`.`word_id`
      AND `word`.`last_revision` = `revision`.`revision_id` 
     WHERE `word`.`word_id` = ?;
---

	$sth->execute($wid);
	my ($xml) = $sth->fetchrow_array;
	return $xml;
}

sub authenticate {
  my ($self, $user, $password) = @_;
  $password = md5_hex $password;

  my $sth = $self->dbh->prepare(<<"---");
    SELECT * FROM user WHERE username = ? AND password = ? and banned = 0;
---
  $sth->execute($user, $password);
  my @row = $sth->fetchrow_array();
  return @row ? 1 : 0;
}


sub get_browse_range {
  my ($self, $position) = @_;

  my $mSth = $self->dbh->prepare(<<"---");
  SELECT MAX(idx) FROM browse_idx;
---
  $mSth->execute();
  my ($max) = $mSth->fetchrow_array;

  $position = $max if $position > $max;

  my $margin = 7;
  my $lower  = $position - $margin;
  my $higher = $position + $margin;
  my $range  = ($margin - 1) * 2 + 1;

  my $sth = $self->dbh->prepare(<<"---");
  SELECT idx, word FROM browse_idx
  WHERE idx > ? AND idx < ? ORDER BY idx
---
  $sth->execute($lower, $higher);

  my $cword = "";
  my $cid = 0;
  my @words = ();
  while (my ($id, $word) = $sth->fetchrow_array) {
    push @words, { id => $id , word => $word} ;
    if ($id == $position) {
      $cword = $word;
      $cid = $id;
    }
  }

  return { words => \@words, cword => $cword, cid => $cid };
}

sub get_browse_letter_position {
  my ($self, $letter) = @_;

  my $l = lc $letter;

  my $sth = $self->dbh->prepare("SELECT idx FROM browse_idx WHERE word = ?");
  $sth->execute($l);
  my @ans = $sth->fetchrow_array;
  return $ans[0] if @ans;
  

  $sth = $self->dbh->prepare('CALL getClosestMatch(?);');
  $sth->execute($l);
  my ($position) = $sth->fetchrow_array;

  return $position;
}

sub wotd {
    my ($self) = @_;
    my $sth = $self->dbh->prepare("SELECT `value` FROM `metadata` WHERE `key` = ?");
    $sth->execute('wotd');
    
    my ($wid) = $sth->fetchrow_array;

    return $self->revision_from_wid($wid);
}

sub metadata {
  my ($self, $key) = @_;
  return undef unless grep {$key eq $_} qw.count first_word last_word wotd.;
  my $query = <<"";
    SELECT `value` FROM `metadata` WHERE `key` = ?

  my $sth = $self->dbh->prepare($query);
  $sth->execute($key);
  my ($ans) = $sth->fetchrow_array;
  return $ans;
}

sub retrieve_entry {
	my ($self, $word, $n) = @_;

	my $query = <<"";
SELECT * FROM word INNER JOIN revision 
  ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id
  WHERE word=? %%AND%% AND word.deleted=0;

	$query =~ s/%%AND%%/ $n ? "AND sense=?" : "" /e;

	my $sth = $self->dbh->prepare($query);
	$sth->execute($word, $n ? $n : ());

	return $sth->fetchall_arrayref({});

}

sub retrieve_news {
	my ($self, %filter) = @_;

	my @where = ();
	if (exists($filter{id}) && $filter{id} =~ /^\d+$/) {
		push @where, "WHERE idnew = $filter{id}"
	}

	push @where, "ORDER BY date DESC";

	if (exists($filter{limit}) && $filter{limit} =~ /^\d+$/) {
		push @where, "LIMIT $filter{limit}"
	}

	my $sql = "SELECT idnew, user, date, title, text FROM new";
	$sql = join(" ", $sql, @where);

	my $sth = $self->dbh->prepare($sql);
	$sth->execute();

	my $news = $sth->fetchall_arrayref({});

	return $news;
}





sub _delete_queries {
    my @ans;
    for (0..length($_[0])-1) {
        my $x = $_[0];
        substr($x,$_,1) = "";
        push @ans, $x;
    }
    \@ans;
}

sub _trs_queries {
    my @ans;
    for (0..length($_[0])-2) {
        my $x = $_[0];
        (substr($x,$_,1), substr($x,$_+1,1)) = (substr($x,$_+1,1),substr($x,$_,1));
        push @ans, $x;
    }
    \@ans;
}

sub _replace_queries {
    my @ans;
    for (0..length($_[0])-1) {
        my $x = $_[0];
        substr($x,$_,1) = "_";
        push @ans, $x;
    }
    \@ans;
}

sub _add_queries {
    my @ans;
    push @ans, "_$_[0]";
    for (1..length($_[0])-1) {
        my $x = $_[0];
        substr($x,$_,0) = "_";
        push @ans, $x;
    }
    push @ans, "$_[0]_";
    \@ans;
}

sub near_misses {
    my ($self, $word) = @_;

    my %WORDS;

    my $deletions = _delete_queries($word);
    my $trs       = _trs_queries($word);
    $WORDS{$_}++ for (@$deletions, @$trs);

    my $replaces  = _replace_queries($word);
    my $additions = _add_queries($word);
    for my $word (@$replaces, @$additions) {
        for my $letter (@LETTERS) {
            my $x = $word;
            $x =~ s/_/$letter/;
            $WORDS{$x}++
        }
    }

    my $query = join(", ", map { "'$_'" } keys %WORDS);
    %WORDS = ();

    $query = "SELECT DISTINCT(word) FROM word WHERE word IN ($query)";
    my $sth = $self->dbh->prepare($query);
    return [] unless $sth;

    $sth->execute();

    my $val;
    my @ANS = ();
    while( ($val) = $sth->fetchrow_array) {
        push @ANS, $val;
    }

    return \@ANS;
}

sub words_by_letter {
  my $self = shift;
  my $ans = $self->dbh->selectall_arrayref(<<"---");
  SELECT substr(normalized,1,1) AS letter, COUNT(word) FROM word GROUP BY letter ORDER BY letter;
---

  my $data;
  while (my $pair = shift(@$ans)) {
    push @{$data->{axis}}   => $pair->[0];
    push @{$data->{values}} => $pair->[1]*1;
  }

  return $data;
}

sub words_by_size {
  my $self = shift;
  my $sth = $self->dbh->prepare(<<"---");
SELECT tamanho, COUNT(tamanho) FROM
   (SELECT LENGTH(word) AS tamanho FROM word) AS tamanhos GROUP BY tamanho ORDER BY tamanho
---
  $sth->execute();
  my $data;
  my $ans = $sth->fetchall_arrayref;
  while (my $pair = shift(@$ans)) {
    push @{$data->{axis}}   => $pair->[0]*1;
    push @{$data->{values}} => $pair->[1]*1;
  }
  return $data;
}

sub moderation_stats {
  my $self = shift;
  my ($D, $M, $T);
  my $totals = $self->dbh->selectall_hashref(<<"---", 'letter');
   SELECT substr(normalized,1,1) AS letter, COUNT(word) from word group by letter order by letter;
---

  my $deleted = $self->dbh->selectall_hashref(<<"---", 'letter');
   SELECT substr(normalized,1,1) AS letter, COUNT(word) from word inner join revision
                                                       on word.word_id = revision.word_id
                                                    where revision.deleted = 1 and revision_id = 2
                                                 group by letter order by letter;
---

  my $moderated = $self->dbh->selectall_hashref(<<"---", 'letter');
    SELECT substr(normalized,1,1) AS letter, COUNT(word) from word inner join revision
                                                       on word.word_id = revision.word_id
                                                    where revision.deleted = 0 AND
                                              revision.moderator is not null and revision_id = 2
                                                 group by letter order by letter;
---

    for ('a'..'z') {
        my $t = $totals->{$_}{'COUNT(word)'};
        my $d = $deleted->{$_}{'COUNT(word)'} || 0;
        my $m = $moderated->{$_}{'COUNT(word)'} || 0;

        push @$D => 0+$d;
        push @$M => 0+$m;
        push @$T => 0+($t-$d-$m);
    }

    return { letters => ['a'..'z'],
             data => [
                      { name => 'apagadas',    color => '#BB6666', data => $D },
                      { name => 'aprovadas',   color => '#45A772', data => $M },
                      { name => 'por moderar', color => '#4572A7', data => $T },
                     ]
           }; 
}

sub recover_password {
    my ($self, $data) = @_;
    my $q = "SELECT username, email FROM user WHERE " . ($data =~ /@/ ? "email" : "username") . " = ?";
    my $sth = $self->dbh->prepare($q);
    $sth->execute($data);
    my $records = $sth->fetchall_arrayref;
    if (@$records) {
	for my $u (@$records) {
	    my ($username, $email) = ($u->[0], $u->[1]);
	    my $md5 = md5_hex("$username ".localtime);
	    $self->quick_delete('user_restore', { user => $username });
	    $self->quick_insert('user_restore', {
		md5   => $md5, user  => $username,
		new   => 0, email => $email, name  => "" });

	    return { email => $email, username => $username, md5 => $md5 };
	}
    } else {
	return undef;
    }
}

sub register_user {
    my ($self, $data) = @_;
    my ($username, $email, $name) = ($data->{username}, $data->{email}, $data->{name});

    return undef if $self->user_exists($username);
    return undef if $self->email_exists($email);
    
    my $md5 = md5_hex("$username ". localtime);
    $self->quick_delete( user_restore => { user => $username });
    $self->quick_insert( user_restore => { 
	md5 => $md5, user => $username, new => 1, email => $email, name => $name });

    return { email => $email, username => $username, md5 => $md5 };
}

sub user_exists {
    my ($self, $username) = @_;
    my $sth = $self->dbh->prepare("SELECT * FROM user WHERE username = ?");
    $sth->execute($username);
    my $records = $sth->fetchall_arrayref;
    return @$records ? 1 : 0;
}


sub email_exists {
    my ($self, $email) = @_;
    my $sth = $self->dbh->prepare("SELECT * FROM user WHERE email = ?");
    $sth->execute($email);
    my $records = $sth->fetchall_arrayref;
    return @$records ? 1 : 0;
}


sub quick_insert {
    my ($self, $table, $data) = @_;
    my (@data, @where);
    foreach my $c (keys %$data) {
	push @data, $data->{$c};
	push @where, $c;
    }
    my $columns = join(",", @where);
    my $qmarks  = join(",", ("?") x @where);
    my $sth = $self->dbh->prepare("INSERT INTO $table ($columns) VALUES ($qmarks);");
    $sth->execute(@data);
}

sub quick_delete {
    my ($self, $table, $constraints) = @_;

    my (@data, @where);
    foreach my $c (keys %$constraints) {
	push @data, $constraints->{$c};
	push @where, $c;
    }
    my $where = join (" AND ", map { "$_ = ?" } @where);
    my $sth = $self->dbh->prepare("DELETE FROM $table WHERE $where;");
    $sth->execute(@data);
    
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Alberto Simoes.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DA::Database
