package Padre::Plugin::PPIExplorer;

BEGIN {
    $Padre::Plugin::PPIExplorer::VERSION = '0.1';
}

use 5.008002;
use strict;
use warnings;
use Params::Util   ();
use Padre::Current ();
use Padre::Wx      ();
use Padre::Plugin  ();

our @ISA = 'Padre::Plugin';

# This constant is used when storing
# and restoring the cursor position.
# Keep it small to limit resource use.
use constant {
    SELECTIONSIZE => 40,
    TRUE          => 1,
    FALSE         => undef,
};

sub padre_interfaces {
    'Padre::Plugin'     => '0.54',
        'Padre::Config' => '0.54';
}

sub plugin_name {
    Wx::gettext('Perl PPIExplorer');
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        Wx::gettext("Dump the selected text")   => \&dump_selection,
        Wx::gettext("Dump the active document") => \&dump_document,
    ];
}

# isa: function
# no pod
sub _OnError {
    my $main = shift;
    $main->output->AppendText( "PPIExplorer Error:\n" . $@ );
    return FALSE;
}

# parameter: $main,$current,$source,$document
# returns: TRUE or FALSE
# description: raise error if error
# isa: method
sub _dump {
    my $main     = shift;
    my $current  = shift;
    my $source   = shift;
    my $document = $current->document;

    # Check for problems
    unless ( defined $source ) { return FALSE };
    
    unless ( $document->isa('Padre::Document::Perl') ) {
	my $ret = Wx::MessageBox(
			"Document is not a Perl document. Should I try?",
			"Warn",
			3, 
		$main,
	);
	unless ( $ret == 3 ){
		return TRUE;
	}
    }

    $main->show_output(1);
    my $output = $main->output;
    require PPI;
    require PPI::Dumper;

    my $output_doc;
    eval {
	   my $ppi_document = PPI::Document->new( \$source );
       	   $output_doc = PPI::Dumper->new($ppi_document)->string;

    } or do {
            return _OnError($main,"PPIExplorer Error:\n".$@ ) if ($@);
        };
        
    if ($output_doc) {
	$output->clear;
        $output->AppendText("$output_doc");
    }

    return TRUE;
}

#POD: dump the current selected text
sub dump_selection {
    my $main = shift;
    my $current = $main->current;
    my $text    = $current->text;
    my $dump    = _dump( $main, $current, $text );
    unless ( defined Params::Util::_STRING($dump) ) {
        return FALSE;
    }
    #$current->editor->ReplaceSelection($dump);
    return TRUE;
}

#POD: dump the entire current document
sub dump_document {
    my $main = shift;
    my $current  = $main->current;
    my $document = $current->document;
    my $text     = $document->text_get;
    my $dump     = _dump( $main, $current, $text );
    unless ( defined Params::Util::_STRING($dump) ) {
        return FALSE;
    }
    return TRUE;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::PerlExplorer - Dump PPI of perl code. uses PPI::Dumper

=head1 VERSION

version 0.1

=head1 SYNOPSIS

Simple plugin to run PPI::Dumper on your source code.

=head1 AUTHORS

=over 4

=item *

Matthias Ries <dev@coffein-shock.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Matthias Ries and others

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
