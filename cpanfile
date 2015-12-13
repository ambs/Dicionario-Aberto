requires "Dancer2" => "0.159003";

requires "YAML"             => "0";
requires "URL::Encode::XS"  => "0";
requires "CGI::Deurl::XS"   => "0";
requires "HTTP::Parser::XS" => "0";

requires "DateTime::Format::MySQL" => "0";

on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
};
