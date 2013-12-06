package WWW::WordStream;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use LWP::UserAgent;
#use IO::Socket::SSL qw(debug3);
use JSON;
use Carp;
use URI::Escape qw/uri_escape uri_escape_utf8/;
use Data::Dumper;

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{username} or croak "username is required";
    $args{password} or croak "password is required";

    $args{ua} = LWP::UserAgent->new(
        timeout => 1200,
    );

    bless \%args, $class;
}

sub login {
    my $self = shift;

    my $username = $self->{username};
    my $password = $self->{password};
    my $url = "https://api.wordstream.com/authentication/login?username=" . uri_escape($username) . "&password=" . uri_escape($password);
    my $resp = $self->{ua}->get($url);
    unless ($resp->is_success) {
        $errstr = $resp->status_line;
        return;
    }
    my $data = decode_json($resp->decoded_content);
    if ($data->{error}) {
        $errstr = $data->{error};
        return;
    }
    $self->{session_id} = $data->{data}->{session_id};
    return $data->{data}->{session_id};
}

sub get_keyword_volumes {
    my ($self, @keywords) = @_;

    my $keywords = join("\n", @keywords);
    my $url = "http://api.wordstream.com/keywordtool/get_keyword_volumes";
    my $resp = $self->{ua}->post($url, [
        keywords => $keywords,
        session_id => $self->{session_id},
        block_adult => 'false',
    ]);
    unless ($resp->is_success) {
        $errstr = $resp->status_line;
        # print Dumper(\$resp);
        return;
    }
    my $data = decode_json($resp->decoded_content);
    if ($data->{error}) {
        $errstr = $data->{error};
        return;
    }
    return $data->{data};
}

sub get_api_credits {
    my ($self) = @_;

    my $url = "https://api.wordstream.com/authentication/get_api_credits?session_id=" . $self->{session_id};
    my $resp = $self->{ua}->get($url);
    unless ($resp->is_success) {
        $errstr = $resp->status_line;
        return;
    }
    my $data = decode_json($resp->decoded_content);
    if ($data->{error}) {
        $errstr = $data->{error};
        return;
    }
    return $data->{data};
}

sub logout {
    my $self = shift;

    $self->{ua}->get("https://api.wordstream.com/authentication/logout?session_id=" . $self->{session_id});
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::WordStream - Blah blah blah

=head1 SYNOPSIS

  use WWW::WordStream;

=head1 DESCRIPTION

WWW::WordStream is

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
