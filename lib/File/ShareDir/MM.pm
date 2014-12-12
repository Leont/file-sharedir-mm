package File::ShareDir::MM;

use strict;
use warnings;

use Exporter 5.57 'import';

use File::Find 'find';
use File::Spec::Functions qw/catdir catfile abs2rel/;

our @EXPORT_OK = qw/postamble/;

sub postamble {
	my ($self, %args) = @_;
	return unless $args{share};
	$args{share} = { dist => 'share' } if $args{share} == 1;
	my %share = %{ $args{share} };
	my %files;

	find_files(\%files, $share{dist}, catdir('$(INST_LIB)', qw(auto share dist), '$(DISTNAME)')) if $share{dist};
	for my $module (keys %{ $share{module} }) {
		find_files(\%files, $share{dist}, catdir('$(INST_LIB)', qw(auto share module), $module));
	}
	my $pm_to_blib = $self->oneliner(q{pm_to_blib({@ARGV}, '$(INST_LIB)')}, ['-MExtUtils::Install']);
	return "pure_all :: sharedir\n\nsharedir : \n" . join '', map { "\t\$(NOECHO) $_\n" } $self->split_command($pm_to_blib, %files);
}

sub find_files {
	my ($files, $source, $sink) = @_;
	find(sub {
		return if -d;
		my $rel = abs2rel($File::Find::name);
		$files->{$rel} = catfile($sink, $rel);
	}, $source);
	return;
}

1;

# ABSTRACT: File::ShareDir::Install, but tinier
