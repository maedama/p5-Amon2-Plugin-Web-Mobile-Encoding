package Amon2::Plugin::Web::MobileEncoding;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

our $CODE_POINT_CARRIER_MIXED = "carrier-mixed";
our $CODE_POINT_GOOGLE = "google-code";
our $USED_CODE_POINT = $CODE_POINT_GOOGLE;

use Carp qw(croak);

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method($c, 'encoding' => sub {
        my $encode_jp_mob_encoding =  detect_encoding(shift->mobile_agent);
        if ($USED_CODE_POINT == $CODE_POINT_GOOGLE) {
            encode_jp_mob_to_encode_jp_emoji($encode_jp_mob_encoding);
        }
        elsif ($USED_CODE_POINT == $CODE_POINT_CARRIER_MIXED) {
            if ( $encode_jp_mob_encoding eq "utf8" ) {
                return "x-utf8-e4u-mobile-unicode";
            }
            else {
                return $encode_jp_mob_encoding;
            }
        }
    });
    Amon2::Util::add_method($c, 'html_content_type' => sub {
        my $ma = shift->mobile_agent;
        my $ct  = $ma->is_docomo ? 'application/xhtml+xml;charset=' : 'text/html;charset=';
        $ct .= $ma->can_display_utf8 ? 'utf-8' : 'Shift_JIS';
        $ct;
    });
    Amon2::Util::add_method($c, 'replace_4byte_utf8_char' => sub {
        my ($self, $str, $replaced) = @_;
        $replaced ||= "\x{3013}";
        $str =~s/[\x{10000}-\x{3ffff}\x{40000}-\x{fffff}\x{100000}-\x{10ffff}]/$replaced/g;
        return $str;
    });
}

sub encode_jp_mob_to_encode_jp_emoji {
    my $encoding = shift;
    if ($encoding =~ /x-(sjis|utf8)-(docomo|kddi-auto|softbank)/ ) {
        return "x-$1-e4u-$2";
    } elsif ($encoding eq "utf8") {
        return "x-utf8-e4u-unicode";
    }
    else {
        return $encoding;
    }
}

sub detect_encoding {
    my $agent = shift;
    if ($agent->is_docomo) {
        return $agent->xhtml_compliant ? 'x-utf8-docomo' : 'x-sjis-docomo';
    } elsif ($agent->is_ezweb) {
        return 'x-sjis-kddi-auto';
    } elsif ($agent->is_vodafone) {
        return $agent->is_type_3gc ? 'x-utf8-softbank' : 'x-sjis-softbank';
    } elsif ($agent->is_airh_phone) {
        return 'x-sjis-airh';
    } else { # $agent->is_non_mobile には utf-8 とします
        return 'utf8';
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::MobileEncoding - It's new $module

=head1 SYNOPSIS

    use Amon2::Plugin::Web::MobileEncoding;

=head1 DESCRIPTION

Amon2::Plugin::Web::MobileEncoding is ...

=head1 LICENSE

Copyright (C) maedama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

maedama E<lt>klemensplatz@gmail.comE<gt>

=cut

