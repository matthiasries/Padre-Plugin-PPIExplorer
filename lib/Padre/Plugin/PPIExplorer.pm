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

sub padre_interfaces {
    'Padre::Plugin'     => '0.54',
        'Padre::Config' => '0.54';
}

use constant {
    SELECTIONSIZE => 40,
    TRUE          => 1,
    FALSE         => undef,
};

sub plugin_name {
    Wx::gettext('Perl PPIExplorer');
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        Wx::gettext("Dump the selected text to the output") => \&dump_selection_to_output,
        Wx::gettext("Dump the active text to the output")   => \&dump_document_to_output,
        '---'                                               => undef,
        Wx::gettext("Dump the selected text to new file")   => \&dump_selection_to_newdoc,
        Wx::gettext("Dump the active document to new file") => \&dump_document_to_newdoc,
    ];
}

# returns: Boolean
# description: print Error to output 
sub _OnError {
    my $main = shift;
    $main->output->AppendText( "PPIExplorer Error:\n" . @_ . $@ );
    return FALSE;
}


# parameter: $main,$current,$source,$document
# returns: String
# description: Generates PPI-Output from document
sub _dump {
    my $main     = shift;
    my $current  = shift;
    my $source   = shift;
    my $document = $current->document;

    # Check for problems
    unless ( defined $source ) { return FALSE }

    unless ( $document->isa('Padre::Document::Perl') ) {
        my $ret = Wx::MessageBox( "Document is not a Perl document. Should I try?", "Warn", 3, $main, );
        return FALSE unless ( $ret == 3 );
    }
    require PPI;
    require PPI::Dumper;

    my $output_doc;
    eval {
        my $ppi_document = PPI::Document->new( \$source );
        $output_doc = PPI::Dumper->new($ppi_document)->string;

    } or do {
        return _OnError( $main, "PPIExplorer Error:\n" . $@ ) if ($@);
    };
    return $output_doc;
}

sub _dump_to_output {
    my $main       = shift;
    my $current    = shift;
    my $source     = shift;
    my $document   = $current->document;
    my $output_doc = _dump( $main, $current, $source );
    $main->show_output(1);
    my $output = $main->output;

    if ($output_doc) {
        $output->clear;
        $output->AppendText("$output_doc");
    }

    return TRUE;
}

sub _dump_to_doc {
    my $main       = shift;
    my $current    = shift;
    my $source     = shift;
    my $document   = $current->document;
    my $output_doc = _dump( $main, $current, $source );
    my $filename   = _get_filename($main);
    return unless defined $filename;
    
    if ($output_doc) {
        $main->show_output(1);
        eval {
            open  my $filehandle , '>',$filename;
            print $filehandle $output_doc;
            close $filehandle;
        } or do {
            if (@$){
                $main->output->AppendText( "Can't write '$filename':" .$@ );
                return FALSE;            
            }
        };
        $main->output->AppendText("Write to file '$filename'\n");
    
        if ( $main->yes_no( Wx::gettext("Should I open the new file?"), Wx::gettext("Exist") ) )
        {
                _OnError($main,'Could not open file') and return FALSE if ! -e $filename;
                $main->setup_editors($filename);            
        };
        
    }
    return TRUE;

}
sub _get_filename {
	my $main = shift;
	my $doc         = $main->current->document or return;
	my $current     = $doc->filename;
	my $default_dir = '';

	if ( defined $current ) {
		require File::Basename;
		$default_dir = File::Basename::dirname($current);
	}

	require File::Spec;

	while (1) {
		my $dialog = Wx::FileDialog->new(
			$main, Wx::gettext("Save file as..."),
			$default_dir, ( $current or $doc->get_title ) . '.txt',
			"*.*", Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return FALSE;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile( $default_dir, $filename );
		if ( -e $path ) {
			return $path if $main->yes_no( Wx::gettext("File already exists. Overwrite it?"), Wx::gettext("Exist") );
		} else {
			return $path;
		}
	}
}

#POD: dump the current selected text
sub dump_selection_to_output {
    my $main    = shift;
    my $current = $main->current;
    my $text    = $current->text;
    _dump_to_output( $main, $current, $text );
    return TRUE;
}

#POD: dump the entire current document
sub dump_document_to_output {
    my $main     = shift;
    my $current  = $main->current;
    my $document = $current->document;
    my $text     = $document->text_get;
    _dump_to_output( $main, $current, $text );
    return TRUE;
}

#POD: dump the current selected text
sub dump_selection_to_newdoc {
    my $main    = shift;
    my $current = $main->current;
    my $text    = $current->text;
    my $dump    = _dump_to_doc( $main, $current, $text );
    unless ( defined Params::Util::_STRING($dump) ) {
        return FALSE;
    }

    #$current->editor->ReplaceSelection($dump);
    return TRUE;
}

#POD: dump the entire current document
sub dump_document_to_newdoc {
    my $main     = shift;
    my $current  = $main->current;
    my $document = $current->document;
    my $text     = $document->text_get;
    my $dump     = _dump_to_doc( $main, $current, $text );
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
