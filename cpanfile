requires "Catalyst" => "5.90128";
requires "Class::Null" => "2.110730";
requires "File::DataClass" => "v0.73.4";
requires "HTML::Tree" => "5.07";
requires "JSON" => "2.90";
requires "Moo" => "2.001001";
requires "MooX::HandlesVia" => "0.001008";
requires "Ref::Util" => "0.203";
requires "Sub::Exporter" => "0.987";
requires "Sub::Install" => "0.928";
requires "Type::Tiny" => "1.000005";
requires "Unexpected" => "v1.0.3";
requires "namespace::autoclean" => "0.26";
requires "namespace::clean" => "0.25";
requires "perl" => "5.010001";
requires "strictures" => "2.000000";

on 'build' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Build" => "0.4004";
  requires "Module::Metadata" => "0";
  requires "Sys::Hostname" => "0";
  requires "Test::Requires" => "0.06";
  requires "version" => "0.88";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};
