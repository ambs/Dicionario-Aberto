package DA::News;
use Dancer ':syntax';
use Dancer::Plugin::Database;

sub delete {
    my ($class, $id) = @_;
    database->quick_delete( new => { idnew => $id });
}

sub id {
    my ($class, $id) = @_;
    database->quick_select( new => { idnew => $id });
}

sub new {
    my ($class, $user, $date, $title, $text) = @_;
    database->quick_insert( new => {
                                    date  => $date,
                                    user  => $user,
                                    title => $title,
                                    text  => $text,
                                   });
}

sub update {
    my ($class, $id, $user, $date, $title, $text) = @_;
    database->quick_update( 'new'
                            => { idnew => $id }
                            => { date  => $date,
                                 user  => $user,
                                 title => $title,
                                 text  => $text,
                               });
}

21; # half the truth
