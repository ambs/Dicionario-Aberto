package DA::Database;

use 5.006;
use strict;
use warnings;

use utf8;

use Scalar::Util qw.blessed.;
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
 SELECT word_id FROM word WHERE deleted=0 ORDER BY rand() LIMIT 1
---
	$sth->execute();
	my ($wid) = $sth->fetchrow_array;
		           
	return $self->revision_from_wid($wid);
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

sub get_browse_range {
  my ($self, $position) = @_;

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
  my @words = ();
  while (my ($id, $word) = $sth->fetchrow_array) {
    push @words, { id => $id , word => $word} ;
    $cword = $word if $id == $position;
  }

  return { words => \@words, cword => $cword };
}

sub get_browse_letter_position {
  my ($self, $letter) = @_;

  my $l = lc $letter;
  my $ll = "$l%";
  my $sth = $self->dbh->prepare(<<"---");
   SELECT idx FROM browse_idx
      WHERE word = ? OR word LIKE ? 
      ORDER BY idx LIMIT 1
---
  $sth->execute($l, $ll);
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

sub retrieve_entry {
	my ($self, $word, $n) = @_;

	my $query = <<"---";
SELECT * FROM word INNER JOIN revision 
  ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id
  WHERE word=? %%AND%% AND word.deleted=0;
---

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
    my ($self, $word, %conf) = @_;
    my $includeself = 1 if $conf{includeself};

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
    @ANS = grep { $_ ne $word } @ANS unless $includeself;

    return \@ANS;
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
