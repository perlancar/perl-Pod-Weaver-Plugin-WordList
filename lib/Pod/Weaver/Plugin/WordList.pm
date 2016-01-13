package Pod::Weaver::Plugin::WordList;

# DATE
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $wl_name = $package;
    $wl_name =~ s/\AWordList:://;

    # add Synopsis section
    {
        my @pod;
        push @pod, " use $package;\n\n";
        push @pod, " my \$wl = $package->new;\n\n";

        push @pod, " # Pick a (or several) random word(s) from the list\n";
        push @pod, " my \$word = \$wl->pick;\n";
        push @pod, " my \@words = \$wl->pick(3);\n\n";

        push @pod, " # Check if a word exists in the list\n";
        push @pod, " if (\$wl->word_exists('foo')) { ... }\n\n";

        push @pod, " # Call a callback for each word\n";
        push @pod, " \$wl->each_word(sub { my \$word = shift; ... });\n\n";

        push @pod, " # Get all the words\n";
        push @pod, " my \@all_words = \$wl->all_words;\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(WordList/.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building WordList::* distribution

=for Pod::Coverage ^(weave_section)$

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-WordList]


=head1 DESCRIPTION

This plugin is to be used when building C<WordList::*> distribution. Currently
it does the following:

=over

=item * Add a Synopsis section (it doesn't already exist) showing how to use the module

=back


=head1 SEE ALSO

L<Dist::Zilla::Plugin::WordList>
