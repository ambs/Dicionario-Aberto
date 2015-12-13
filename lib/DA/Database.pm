package DA::Database;


use XML::DT;
use HTML::Trim;
use DA::Abbrevs;
use Text::Diff::FormattedHTML 'diff_strings';
use utf8;

my $database;
sub database { return $database; }
sub set_database { $database = $_[0]; }

# use POSIX qw(locale_h);
# setlocale(LC_CTYPE,   "pt_PT.utf8");
# setlocale(LC_COLLATE, "pt_PT.utf8");
# use locale;

our @LETTERS = qw!a b c d e f g h i j k l m n o p
                  q r s t u v w x y z ã õ á é í ó
                  ú à è ì ò ù â ê î ô û ç ä ë ï ö
                  ü ÿ ý ũ ẽ -!;

sub moderate {
    my $self = shift;
    return unless scalar(@_) == 4;
    my ($wid, $rid, $xml, $moderator) = @_;

    database->quick_update('revision',
                           { word_id => $wid, revision_id => $rid },
                           { timestamp => _now(), moderator => $moderator, xml => $xml });

    _cache_preview($wid, $xml);
}

sub _cache_preview {
    my ($word_id, $xml) = @_;
    my $preview = _xml2preview($xml);
    database->quick_update('preview_cache',
                           { word_id => $word_id },
                           { preview => HTML::Trim::vtrim($preview, 80, "..."),
                             timestamp => _now() });
}


sub canBeModerated {
    my $self = shift;
    return unless scalar(@_) == 2;
    my ($wid,  $rid) = @_;
    database->quick_select('revision', { word_id => $wid,
                                         revision_id => $rid,
                                         deleted => 0,
                                         moderator => undef });
}

sub word_id {
    my ($self, $word, $sense) = @_;
    my $id = database->quick_select('word', { word => $word, sense => $sense });
    return unless $id;
    $id->{word_id};
}

sub word_ids {
    my ($self, $word) = @_;
    my @ids = map { $_->{word_id} } database->quick_select('word', { word => $word });
    return \@ids;
}

sub diff {
    my ($self, %ops) = @_;
    return unless exists $ops{word} and exists $ops{sense} and exists $ops{to};

    my $last_xml = $self->fetch_xml_revision($ops{word}, $ops{sense}, $ops{to});
    my $prev_xml = $self->_fetch_last_moderated_revision($ops{word}, $ops{sense});

    return "" unless $prev_xml;
    return diff_strings( {vertical => 1},$prev_xml, $last_xml);
}

sub update_last_revision {
    my ($self, $wid) = @_;
    my $rs = database->selectall_arrayref("SELECT revision_id FROM revision WHERE word_id = ? AND deleted = 0 ORDER BY revision_id DESC LIMIT 1", { Slice => {} }, $wid);
    return undef unless $rs;
    my $revision_id = $rs->[0]{revision_id};
    database->quick_update('word',
                           { word_id => $wid },
                           { last_revision => $revision_id });

    # get the XML for that revision, and cache it
    my $revision = database->quick_select('revision', { word_id => $wid,
                                                        revision_id => $revision_id });
    _cache_preview($wid, $revision->{xml});
}

sub delete_revision {
    my $self = shift;
    die unless scalar(@_) == 4;
    my ($w, $s, $r, $u) = @_;
    my $id = $self->word_id($w, $s);
    database->quick_update('revision',
                           { revision_id => $r, word_id => $id },
                           { timestamp => _now(), deleted => 1, deletor => $u });
}

sub fetch_xml_revision {
    my $self = shift;
    die unless scalar(@_) == 3;
    my $rs = database->selectall_arrayref("SELECT xml FROM word INNER JOIN revision ON word.word_id = revision.word_id WHERE word = ? AND sense = ? AND revision_id = ?", { Slice => {} }, @_);
    ($rs and $rs->[0]{xml}) || undef;
}

sub _fetch_last_moderated_revision {
    my $self = shift;
    my $rs = database->selectall_arrayref("SELECT xml FROM word INNER JOIN revision ON word.word_id = revision.word_id WHERE word = ? AND sense = ? AND revision.moderator IS NOT NULL AND revision.deleted = 0 ORDER BY revision_id DESC LIMIT 1", { Slice => {} }, @_);
    ($rs and $rs->[0]{xml}) || undef;
}

sub revisions2moderate {
    my ($class, %ops) = @_;

    my $limit = "LIMIT 100";
    $limit = "LIMIT 1" if exists($ops{one});
    my $ans = database->selectall_arrayref("SELECT word.word, word.sense, revision.revision_id, revision.timestamp, revision.creator FROM word INNER JOIN revision ON word.word_id = revision.word_id WHERE revision.moderator IS NULL AND revision.deleted = 0 ORDER BY rand() $limit", {Slice=>{}});
}

sub xmlEntries {
    my ($class, $word, %ops) = @_;

    my $query;
    my @binds = ($word);

    if ($ops{sense}) {
        push @binds, $ops{sense};
        $query =<< 'EOQ';
      SELECT revision.xml
        FROM word INNER JOIN revision
        ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id
        WHERE word.deleted = 0 AND word = ? AND sense = ?
        ORDER BY sense
EOQ
    } else {
        $query =<< 'EOQ';
      SELECT revision.xml
        FROM word INNER JOIN revision
        ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id
        WHERE word = ? AND word.deleted = 0
        ORDER BY sense
EOQ
    }

    return map { _add_brs($_->{xml}) } @{ database->selectall_arrayref($query, { Slice => { } } , @binds)};
}

sub _add_brs {
    my $xml = shift;
    my %dt = (
              -default => sub { toxml },
              'def' => sub {
                  $c =~ s/\n/<br\/>/g;
                  $c =~ s/<br\/>[\s\n]*$//g;
                  $c =~ s/^[\s\n]*<br\/>//g;
                  toxml;
              }
             );
    return dtstring($xml, %dt);
}

sub _do_word_link {
    my ($word, $sense) = @_;
    return "<a href='/search/$word:$sense'>$word<sup>$sense</sup></a>"
}

sub affixes {
    my ($class, $type, $query, $n) = @_;
    $type eq "infix"  and $query = "\%_${query}_%";
    $type eq "suffix" and $query = "\%_${query}";
    $type eq "prefix" and $query = "${query}_%";

    $n = $n ? "LIMIT $n" : "";

    return database->selectall_arrayref("SELECT word, sense, preview FROM word INNER JOIN preview_cache ON word.word_id = preview_cache.word_id WHERE deleted = 0 AND word LIKE ? ORDER BY normalized $n", { Slice => {} }, $query);
}

sub affixes_in_xml {
    my ($class, $type, $query) = @_;
    $type eq "infix"  and $query = "\%_${query}_%";
    $type eq "suffix" and $query = "\%_${query}";
    $type eq "prefix" and $query = "${query}_%";

    database->selectall_arrayref("SELECT revision.xml FROM word INNER JOIN revision ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id WHERE word.deleted = 0 AND word LIKE ?",
                                 { Slice => {} }, $query);
}

sub getWords {
    my ($class, %ops) = @_;
    return () unless exists($ops{prefix}) || exists($ops{suffix});

    my $word = '%';
    $word = $ops{prefix}.$word if exists $ops{prefix};
    $word = $word.$ops{suffix} if exists $ops{suffix};

    return [map { $_->{word} }
      @{ database->selectall_arrayref("SELECT word FROM word WHERE deleted = 0 AND word LIKE ? ORDER BY normalized",
                                      { Slice => { } },
                                      $word) }];
}

sub idxSize {
    my $sth = database->prepare("SELECT COUNT(word) FROM browse_idx");
    $sth->execute;
    my ($r) = $sth->fetchrow_array;
    $r
}

sub htmlEntries {
    my ($class, $word, %ops) = @_;

    my $query;
    my @binds = ($word);
    my $username = $ops{username} || undef;

    my $revision = "AND word.last_revision = revision.revision_id";
    if (exists($ops{revision}) && $ops{revision} =~ /(\d+)/) {
        $revision = "AND revision.revision_id = $1";
    }

    if ($ops{sameprefix}) {
        push @binds, "$word%";
        $query =<< 'EOQ';
      SELECT word.word, word.word_id, revision.xml, revision.revision_id, word.sense, revision.moderator
        FROM word INNER JOIN revision
        ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id
        WHERE word != ? AND word LIKE ? AND word.deleted = 0
        ORDER BY sense
        LIMIT 10
EOQ
    } else {
        if ($ops{sense}) {
            push @binds, $ops{sense};
            $query =<< "EOQ";
      SELECT word.word, word.word_id, revision.xml, revision.revision_id, word.sense, revision.moderator
        FROM word INNER JOIN revision
        ON word.word_id = revision.word_id
        WHERE word = ? AND sense = ? $revision AND word.deleted = 0
        ORDER BY sense
EOQ
        } else {
            $query =<< "EOQ";
      SELECT word.word, word.word_id, revision.xml, revision.revision_id, word.sense, revision.moderator
        FROM word INNER JOIN revision
        ON word.word_id = revision.word_id
        WHERE word = ? $revision AND word.deleted = 0
        ORDER BY sense
EOQ
        }
    }

    my @a = @{ database->selectall_arrayref($query, { Slice => { } } , @binds) };

    for my $e (@a) {
        ($e->{term}, $e->{definition}, $e->{class}) = _xml2html($e->{xml});
        my $nr = _nr_favourites($e->{word_id});
        $e->{nfav} = $nr == 1 ? "$nr favorito" : "$nr favoritos";

        if ($username) {
            $e->{userfav} = _is_favourite($e->{word_id}, $username);
        }

        my $ids = database->selectall_arrayref('SELECT revision_id FROM revision WHERE word_id = ? AND deleted = 0', {}, $e->{word_id});

        $e->{revisions} = [ sort map { $_->[0] } @$ids ];

        ## Relations
        $e->{relations} = $class->getRelations($e->{word_id});
    }

    return \@a;
}

sub getRelations {
    my ($class, $word_id) = @_;
    my $query = 'SELECT `to_wid`, `description` FROM word_word_rel INNER JOIN relation ON word_word_rel.relation_id = relation.relation_id WHERE word_word_rel.from_wid=?';
    my $sth = database->prepare($query);
    $sth->execute($word_id) or die $sth->errstr;
    my @row;
    my $res;
    while (@row = $sth->fetchrow_array) {
        push @{$res->{$row[1]}}, $row[0]
    }

    for my $k (keys %$res) {
        $res->{$k} = _rels_to_html($res->{$k});
    }

    return $res;
}

sub _rels_to_html {
    my ($array) = @_;

    my $query = "<% query %>/";

    return join ", ", map {
        my $x = word_from_wid($_);
        "<i><a href=\"$query$x->[0]:$x->[1]\">"._formatword($x->[0], $x->[1])."</a></i>"
    } @$array;
}

sub generateNearMisses {
    my ($class, $word, %conf) = @_;
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
    my $sth = database->prepare($query);
    return [] unless $sth;

    $sth->execute();

    my $val;
    my @ANS = ();
    while( ($val) = $sth->fetchrow_array) {
        push @ANS, $val;
    }
    @ANS = grep { $_ ne $word } @ANS unless $includeself;

    my $r = \@ANS;
    return $r;
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

sub _xml2txt {
    my ($self, $xml) = @_;

    my %H = (
             # cit / quote 
             -default => sub { $c },
             entry => sub {
                 my $n = $v{n} || '1';
                 $c =~ s/\n+/\n/g;
                 $c =~ s/^\n//;
                 $c =~ s/\n$//;
                 "Entry [$v{term}:$n]\n$c"
             },
             pron => sub { father("pron",$c); "" },
             sense => sub {
                 my $r = "  sense:\n";
                 if ($v{gramgrp} || $v{usg}) {
                     $v{gramgrp} ||= "";
                     $v{usg}     ||= "";
                     $r .= "  $v{gramgrp} $v{usg}\n"
                 }
                 $r .= $c
             },
             form  => sub {
                 father("term", _trim($c));
                 $v{pron} ? "  [$v{pron}]\n" : ""
             },
             orth  => sub { $c },
             usg     => sub {
                 my $f = father("usg") || "";
                 father("usg", "$f $c"); ""
             },
             gramGrp => sub {
                 father("gramgrp", $c); "" 
             },
             etym => sub { "  Etym: $c" },
             def => sub {
                 for ($c) {
                     s!^[\s\n]*!!;
                     s![\s\n]*$!!;
                     s!^!    !mg;
                 }
                 $c
             }
            );

    return dtstring($xml, %H);
}

sub _xml2html {
    my ($xml) = @_;

    my $query = "<% query %>/";

    my $class = "";
    my $result;
    my %H = (
             # cit / quote 
             -default => sub { $c },
             entry => sub {
                 $class = " geo"  if $v{geo};
                 $class = " name" if $v{name};
                 $result = [ _trim($v{term}), $c, $class];
             },
             pron => sub {
                 father("pron",$c); ""
             },
             sense => sub {
                 $q = "div";
                 if ($v{gramgrp} || $v{usg}) {
                     $v{gramgrp} ||= "";
                     $v{usg}     ||= "";
                     $a = "<i>" . _mark_abbrevs("$v{gramgrp} $v{usg}") . "</i>";
                     delete($v{gramgrp});
                     delete($v{usg});
                     $c = "$a<br/>$c"
                 }
                 toxml },
             form  => sub {
                 $c = _trim($c);
                 $c .= ", (<i>$v{pron}</i>)" if ($v{pron});
                 father("term", $c); "" },
             orth  => sub {
                 my $n = gfather("n") || "";
                 $n && ($n = "<sup>$n</sup>");
                 "$c$n"
             },
             usg     => sub {
                 my $f = father("usg") || "";
                 father("usg", "$f $c"); ""
             },
             gramGrp => sub {
                 father("gramgrp", $c); "" 
             },
             etym => sub {
                 for ($c) {
                     s!\[\[([^]|]+)\|([^]]+)\]\]!<i><a href="$query$2">$1</a></i>!g;
                     s!\[\[([^]]+)\]\]!"<i><a href=\"$query$1\">"._formatword($1)."</a></i>"!ge;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i><a href="$query$1">$1</a></i>!g;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_ \+ _([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i><a href="$query$1">$1</a></i> + <i><a href="$query$2">$2</a></i>!g;
                     s!_([^_]+)_( \*)?!<i>$1</i>!g;
                     s!\^(\d)!<sup>$1</sup>!g;
                     s!\^\{([^\}]+)\}!<sup>$1</sup>!g;
                 }
                 $c
             },
             def => sub {
                 for ($c) {
                     s!\[\)e\]!&#277;!g;
                     s!^[\s\n]*!!;
                     s![\s\n]*$!!;
                     s!\n!<br/>!g;
                     s!\[\[([^]|]+)\|([^]]+)\]\]!<i><a href="$query$2">$1</a></i>!g;
                     s!\[\[([^]]+)\]\]!"<i><a href=\"$query$1\">"._formatword($1)."</a></i>"!ge;
                     s!O mesmo que\s*_([^_]+)_!O mesmo que <i><a href="$query$1">$1</a></i>!g;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_ \+ _([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i><a href="$query$1">$1</a></i> + <i><a href="$query$2">$2</a></i>!g;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i><a href="$query$1">$1</a></i>!g;
                     s!Cp\.\s*_([^_]+)_!Cp. <i><a href="$query$1">$1</a></i>!g;
                     s!V\.\s*_([^_]+)_!V. <i><a href="$query$1">$1</a></i>!g;
                     s!_([^_]+)_( \*)?!<i>$1</i>!g;
                     s!\^\{([^\}]+)\}!<sup>$1</sup>!g;
                     s!\^(\d|[a])!<sup>$1</sup>!g;
                 }
                 $c
             }
            );

    dtstring($xml, %H);
    @$result;
}

sub _trim {
    my ($x) = @_;
    for ($x) {
        s/^\s*//;
        s/\s*$//;
    }
    return $x;
}


sub _mark_abbrevs {
    my @ab = @abbrevs;
    my $string = shift;
    while (@ab) {
        my $abbrev = shift @ab;
        my $expans = shift @ab;
        $string =~ s{(?<!">)\b(\Q$abbrev\E)(?!</a)}{<abbr title="$expans">$1</abbr>}gi;
    }
    return $string;
}


sub _formatword {
  my $word = shift;
  my $id = undef;
  ($word, $id) = split /:/, $word if $word =~ /:/;
  if ($id) {
     return "$word<sup>$id</sup>"
  } else {
     return $word
  }
}


sub _to_json {
    my $class = shift;
    my $xml = shift;
    my %handler=(
                 -pcdata => sub {
                     for ($c) { s/^[\n\s]+//; s/[\n\s]+$//; s/\n/\\n/g } $c;
                 },
                 dic => sub {
                     $c =~ s/\]sensesense\[/,\n/g;
                     $c =~ s/sense\[/"sense" : [/g;
                     $c =~ s/\]sense/],/g;
                     $c =~ s/,[\n ]+([\]}])/$1/g;
                     $c =~ s/,[\n ]*$//g;
                     $c
                 },
                 superEntry => sub {
                     "{\"$q\" : [ $c ]}"
                 },
                 form => sub {
                     "\"$q\" : {\n$c\n},"
                 },
                 entry => sub {
                     my $attr = "";
                     $attr = join(",\n", map { " \"\@$_\" : \"$v{$_}\""} keys %v).",\n" if %v;
                     "{\"$q\" : {\n$attr$c\n}},"
                 },
                 orth => sub { "\"orth\" : \"$c\"," },
                 pron => sub { "\"pron\" : \"$c\"," },
                 sense => sub {
                     my $attr = "";
                     $attr = join(",\n", map { " \"\@$_\" : \"$v{$_}\""} keys %v).",\n" if %v;
                     "sense[{$attr$c}]sense"
                 },
                 gramGrp => sub {
                     "\"$q\" : \"$c\",\n"
                 },
                 def => sub {
                     "\"$q\" : \"$c\",\n"
                 },
                 usg => sub {
                     my $attr = join(",\n", map { " \"\@$_\" : \"$v{$_}\""} keys %v).",\n";
                     $attr = "" if $attr eq ",\n";
                     "\"usg\" : {\n$attr \"#text\" : \"$c\"\n},"
                 },
                 usg => sub {
                     my $attr = join(",\n", map { " \"\@$_\" : \"$v{$_}\""} keys %v).",\n";
                     $attr = "" if $attr eq ",\n";
                     "\"usg\" : {\n$attr \"#text\" : \"$c\"\n},"
                 },
                 quote => sub { $c },
                 cit => sub { $c },
                 etym => sub {
                     my $attr = join(",\n", map { " \"\@$_\" : \"$v{$_}\""} keys %v).",\n";
                     $attr = "" if $attr eq ",\n";
                     "\"etym\" : {\n$attr \"#text\" : \"$c\"\n},"
                 },
                );
    return dtstring($xml,%handler);
}


sub _nr_favourites {
    my $word_id = shift;
    my $ans = database->selectall_arrayref("SELECT COUNT(username) AS total FROM favourite WHERE word_id = ?", { Slice => {} }, $word_id);
    return $ans->[0]{total}

}

sub _is_favourite {
    my ($word_id, $username) = @_;
    my $ans = database->selectall_arrayref("SELECT COUNT(username) AS total FROM favourite WHERE word_id = ? AND username = ?", { Slice => {} }, $word_id, $username);
    return $ans->[0]{total};
}

sub moderation_stats {

    my ($D, $M, $T);
    my $totals = database->selectall_hashref("SELECT substr(normalized,1,1) AS letter, COUNT(word) from word group by letter order by letter;", 'letter');

    my $deleted = database->selectall_hashref(<<"EOS", 'letter');
SELECT substr(normalized,1,1) AS letter, COUNT(word) from word inner join revision
                                                       on word.word_id = revision.word_id
                                                    where revision.deleted = 1 and revision_id = 2
                                                 group by letter order by letter;
EOS

    my $moderated = database->selectall_hashref(<<"EOS", 'letter');
SELECT substr(normalized,1,1) AS letter, COUNT(word) from word inner join revision
                                                       on word.word_id = revision.word_id
                                                    where revision.deleted = 0 AND
                                              revision.moderator is not null and revision_id = 2
                                                 group by letter order by letter;
EOS

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

sub _now {
    my @date = localtime(time);

    $date[5]+=1900;
    $date[4]++;
    sprintf "%4d-%02d-%02d %02d:%02d:%02d", $date[5], $date[4], $date[3], $date[2], $date[1], $date[0];
}

sub _format_adv_search {
    [ map { _format_adv($_) } @{$_[0]} ]
}

sub _format_adv {
    my $r = shift;
    my $link = _do_word_link($_->{word},$_->{sense});
    my $preview = $_->{preview};
    "$link&nbsp;&mdash;&nbsp;$preview"
}

sub adv_ans_to_json {
    my ($s, $ans) = @_;
    if (@$ans) {
        to_json({ans => join("\n", map {"<div>$_</div>"} (@{_format_adv_search($ans)}, '...'))});
    } else {
        to_json({ans => "<div>Nenhuma palavra encontrada.</div>"});
    }
}

sub _rev_idx_word {
    my $word = shift;

    my $sth = database->prepare('SELECT rev_idx_word_id FROM rev_idx_word WHERE rev_idx_word = ?');
    $sth->execute($word);
    if (my @row = $sth->fetchrow_array()) {
        return $row[0];
    }
    else {
        return undef;
    }
}

sub _ont_expand_word_list {
    my ($self, $word_list) = @_;
    my $results_list = [];
    for my $word (@$word_list) {
        my $exp = $self->_ont_expand_word($word);
        push @$results_list, $exp if defined $exp;
    }
    return $results_list;
}

sub _ont_expand_word {
    my ($self, $word) = @_;
    my $wids = $self->word_ids($word);
    if (@$wids) {
        my %ans;
        for my $wid (@$wids) {
            $ans{$wid} ++;
            my @x = database->quick_select('word_word_rel',
                                           { from_wid => $wid },
                                           { columns => ['to_wid'] });
            for my $x (@x) {
                $ans{$x->{to_wid}} ++;
            }
        }
        return \%ans
    } else {
        return undef;
    }
}

sub ontsearch {
    my ($self, $word_list, $limit) = @_;
    my $results_list = $self->_ont_expand_word_list($word_list);
    my $results;
    for my $hit (@$results_list) {
        for my $a (keys %$hit) {
            $results->{$a}++;
        }
    }
    my @ans;
    my $q = join(",", keys %$results);
    my $sth = database->prepare("SELECT word.word_id, word, sense, preview FROM word INNER JOIN preview_cache ON word.word_id = preview_cache.word_id WHERE deleted = 0 AND word.word_id IN ($q);");
    $sth->execute();
    my $db = $sth->fetchall_hashref('word_id');

    for my $ans (sort { $results->{$b} <=> $results->{$a} } keys %$results) {
        push @ans, { %{$db->{$ans}}};
    }
    return \@ans;
}

sub revsearch {
    my ($self, $word_list, $limit) = @_;

    my @words = map { _rev_idx_word(lc $_) || () } grep { length >= 4 } @$word_list;

    @words = map {
        " word_id IN (SELECT word_id FROM rev_idx_rel WHERE rev_idx_rel.rev_idx_word_id=$_) "
    } @words;
    my $q = "SELECT DISTINCT(word_id) FROM rev_idx_rel WHERE ".join(" AND ", @words);

    if ($limit) {
        $q = "SELECT word, sense, preview FROM word INNER JOIN preview_cache ON word.word_id = preview_cache.word_id WHERE deleted = 0 AND word.word_id IN ($q) ORDER BY normalized LIMIT $limit";
    } else {
        $q = "SELECT word, sense, preview FROM word INNER JOIN preview_cache ON word.word_id = preview_cache.word_id WHERE deleted = 0 AND word.word_id IN ($q) ORDER BY normalized";
    }

    return database->selectall_arrayref($q, { Slice => {} });
}


sub revsearch_in_xml {
    my ($self, $word_list) = @_;

    my @words = map { _rev_idx_word(lc $_) || () } grep { length >= 4 } @$word_list;

    @words = map {
        " word_id IN (SELECT word_id FROM rev_idx_rel WHERE rev_idx_rel.rev_idx_word_id=$_) "
    } @words;
    my $q = "SELECT DISTINCT(word_id) FROM rev_idx_rel WHERE ".join(" AND ", @words);

    $q = "SELECT revision.xml FROM word INNER JOIN revision ON word.last_revision = revision.revision_id AND word.word_id = revision.word_id WHERE word.deleted = 0 AND word.word_id IN ($q) ORDER BY normalized";

    return database->selectall_arrayref($q, { Slice => {} });
}

sub _xml2preview {
    my $xml = shift;
    my $result;
    my %H = (
             # cit / quote...
             -default => sub { $c },
             entry    => sub { $result = $c; },
             pron     => sub { father("pron",$c); "" },
             sense => sub {
                 $q = "span";
                 if ($v{gramgrp} || $v{usg}) {
                     $v{gramgrp} ||= "";
                     $v{usg}     ||= "";
                     $a = "<i>$v{gramgrp} $v{usg}</i>";
                     delete($v{gramgrp});
                     delete($v{usg});
                     $c = "$a; $c"
                 }
                 toxml },
             form  => sub {
                 $c = "";
                 $c = "(<i>$v{pron}</i>)" if ($v{pron});
                 father("term", $c); "" },
             orth  => sub { "" },
             usg     => sub {
                 my $f = father("usg") || "";
                 father("usg", "$f $c"); ""
             },
             gramGrp => sub {
                 father("gramgrp", $c); "" 
             },
             etym => sub {
                 for ($c) {
                     s!\[\[([^]|]+)\|([^]]+)\]\]!<i>$1</i>!g;
                     s!\[\[([^]]+)\]\]!"<i>"._formatword($1)."</i>"!ge;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i>$1</i>!g;
                     s{De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_ \+ _([a-záéíóúàèìòùãõêîôâûç][^_]+)_}
                      {De <i>$1</a> + <i>$2</i>}g;
                     s!_([^_]+)_( \*)?!<i>$1</i>!g;
                     s!\^(\d)!<sup>$1</sup>!g;
                     s!\^\{([^\}]+)\}!<sup>$1</sup>!g;
                 }
                 $c
             },
             def => sub {
                 for ($c) {
                     s!\[\)e\]!&#277;!g;
                     s!^[\s\n]*!!;
                     s![\s\n]*$!!;

                     s!\[\[([^]|]+)\|([^]]+)\]\]!<i>$1</i>!g;
                     s!\[\[([^]]+)\]\]!"<i>"._formatword($1)."</i>"!ge;
                     s!O mesmo que\s*_([^_]+)_!O mesmo que <i>$1</i>!g;
                     s{De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_ \+ _([a-záéíóúàèìòùãõêîôâûç][^_]+)_}
                      {De <i>$1</i> + <i>$2</i>}g;
                     s!De\s*_([a-záéíóúàèìòùãõêîôâûç][^_]+)_!De <i>$1</i>!g;
                     s!Cp\.\s*_([^_]+)_!Cp. <i>$1</i>!g;
                     s!V\.\s*_([^_]+)_!V. <i>$1</i>!g;
                     s!_([^_]+)_( \*)?!<i>$1</i>!g;
                     s!\^\{([^\}]+)\}!<sup>$1</sup>!g;
                     s!\^(\d|[a])!<sup>$1</sup>!g;
                 }
                 $c
             }
            );

    dtstring($xml, %H);
    $result =~ s/\n//g;
    return $result;
}

sub word_from_wid {
    my ($id) = @_;
    my $x = database->quick_select('word', { word_id => $id });
    return [ $x->{word}, $x->{sense} ]; 
}


1;
