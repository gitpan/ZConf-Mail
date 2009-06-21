package ZConf::Mail::GUI::Curses;

use warnings;
use strict;
use ZConf::Runner;
use Curses::UI;
use String::ShellQuote;

=head1 NAME

ZConf::Mail::GUI::Curses - The Curses backend for ZConf::Mail::GUI.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

This provides the Curses backend for ZConf::Runner::GUI.

    use ZConf::Mail::GUI::Curses;

    my $zcmail=ZConf::Runner::GUI::Curses->new();

=head1 METHODES

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 useX

This is if it should try to use X or not. If it is not defined,
ZConf::GUI->useX is used.

=head4 zcgui

This is the ZConf::GUI object. A new one will be created if it is

=head4 zcmail

This is a ZConf::Mail object to use. If it is not specified,
a new one will be created.

=head4 zconf

This is the ZConf object to use. If it is not specified the one in the
object for zcrunner will be used. If neither zconf or zcrunner is specified,
a new one is created.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#initiates
	if (defined($args{zcmail})) {
		$self->{zcmail}=$args{zcmail};
	}else {
		$self->{zcmail}=ZConf::Runner->new();
	}

	#
	if (defined($args{zconf})) {
		$self->{zconf}=$self->{zcr}->{zconf};
	}else {
		use ZConf;
		$self->{zconf}=ZConf->new();
		if(defined($self->{zconf}->{error})){
			warn("ZConf-Mail-GUI-Curses new:1: Could not initiate ZConf. It failed with '"
				 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
			$self->{error}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                     .$self->{zconf}->{error}."', '".
			                     $self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#
	if (defined($args{useX})) {
		$self->{useX}=$args{useX};
	}else {
		use ZConf::GUI;
		$self->{zcgui}=ZConf::GUI->new({zconf=>$self->{zconf}});
		$self->{useX}=$self->{zcgui}->useX('ZConf::Mail');
	}

	$self->{terminal}='xterm -rv -e ';
	#if the enviromental variable 'TERMINAL' is set, use 
	if(defined($ENV{TERMINAL})){
		$self->{terminal}=$ENV{TERMINAL};
	}


	return $self;
}

=head2 manageAccounts

Please see the documentation for 'ZConf::MailGUI' for 'manageAccounts'.

=cut

sub manageAccounts{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}

	$self->errorblank;

	my $command='curses-zcmailacountmanage -s '.shell_quote($self->{zcmail}->getSet);

	if ($self->{useX}) {
		$command=$self->{terminal}.shell_quote($command);
	}

	system($command);
	my $exitcode=$? >> 8;

	#error if it got a -1... not in path
	if ($? == -1) {
		$self->{error}=2;
		$self->{errorString}='"curses-zcmailacountmanage" is not in the path.';
		warn('ZConf-Mail-GUI-Curses manageAccounts:2: '.$self->{errorString});
		return undef;
	}

	#error if it is something other than 0
	if (!($? == 0)) {
		$self->{error}=3;
		$self->{errorString}='The backend script exited with a non-zero, "'.$exitcode.'"';
		warn('ZConf-Mail-GUI-Curses manageAccounts:3: '.$self->{errorString});
		return undef;		
	}

	return 1;
}


=head2 compose

Please see compose for 'ZConf::Mail::GUI'.

=cut

sub compose{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	if (!defined($args{account})) {
		$args{account}=$self->{zcmail}->defaultSendableGet;
	}

	#make sure a account is specified
	if (!defined($args{account})) {
		warn('ZConf-Mail-GUI compose:4: No account specified' );
		$self->{error}='4';
		$self->{errorString}='No account specified.';
		return undef;
	}

	#to
	my $to='';
	if (defined($args{to}[0])) {
		$to='-t ';
		my $toJ=join(',', @{$args{to}});
		$to=$to.shell_quote($toJ);
	}

	#cc
	my $cc='';
	if (defined($args{cc}[0])) {
		$cc='-c ';
		my $ccJ=join(',', @{$args{cc}});
		$cc=$cc.shell_quote($ccJ);
	}

	#bcc
	my $bcc='';
	if (defined($args{bcc}[0])) {
		$bcc='-b ';
		my $bccJ=join(',', @{$args{to}[0]});
		$bcc=$bcc.shell_quote($bccJ);
	}

	#replyto
	my $replyto='';
	if (defined($args{'in-reply-to'})) {
		$replyto=shell_quote($args{'in-reply-to'});
		$replyto='-r '.$replyto;
	}

	#account
	my $account='-a '.shell_quote($args{account});

	#files
	my $files='';
	if (defined($args{files}[0])) {
		$files='-f ';
		my $filesJ=join(',', @{$args{files}});
		$files=$files.shell_quote($filesJ);
	}

	my $command='curses-zcmailcompose '.$account.' '.$to.' '.$cc.' '.
	            $bcc.' '.$replyto.' '.$files;

	if ($self->{useX}) {
		$command=$self->{terminal}.shell_quote($command);
	}

	system($command);
	my $exitcode=$? >> 8;

	#error if it got a -1... not in path
	if ($? == -1) {
		$self->{error}=2;
		$self->{errorString}='"curses-zcmailacountmanage" is not in the path.';
		warn('ZConf-Mail-GUI-Curses compose:2: '.$self->{errorString});
		return undef;
	}

	#error if it is something other than 0
	if (!($? == 0)) {
		$self->{error}=3;
		$self->{errorString}='The backend script exited with a non-zero, "'.$exitcode.'"';
		warn('ZConf-Mail-GUI-Curses compose:3: '.$self->{errorString});
		return undef;		
	}

	return 1;
}

=head2 dialogs

This returns the available dailogs.

=cut

sub dialogs{
	return undef;
}

=head2 windows

This returns a list of available windows.

=cut

sub windows{
	return ('accountmanage', 'compose');
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1 dialogs

At this time, no windows are supported.

=head1 windows

manageAccounts

compose

=head1 HOTKEYS

Please see Curses::UI::TextEditor for the support hot keys.

Additional ones are listed below.

=head2 CTRL+a

Attach a file.

=head2 CTRL+f

Call the formatter.

=head2 CTRL+l

Send.

=head2 CTRL+n

Changes to the next tab.

=head2 CTRL+p

Changes to the previous tab.

=head2 CTRL+q

Exit.

=head1 ERROR CODES

=head2 1

Coult no initiate ZConf.

=head2 2

Missing arguements.

=head2 3

Backend script failed.

=head1 useX

If useX is true, ther enviromental variable 'TERMINAL' is used for finding
what terminal should be used executing the backend script.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Mail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Mail::GUI::Curses


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Mail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Runner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Mail>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Mail>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Mail::GUI::Curses
