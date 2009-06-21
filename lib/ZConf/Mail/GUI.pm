package ZConf::Mail::GUI;

use warnings;
use strict;
use ZConf::Mail;
use Getopt::Std;
use ZConf::GUI;
use URI;

=head1 NAME

ZConf::Mail::GUI - Implement various GUI functions for ZConf::Mail.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use ZConf::Mail::GUI;

    my $zcmg = ZConf::Mail::GUI->new();
    ...

=head1 METHODES

=head2 new

This initiates the new the object for this module.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zcmail

This is a ZConf::Mail object to use. If it is not specified,
a new one will be created.

=head4 zconf

This is the ZConf object to use. If it is not specified the one in the
object for zcrunner will be used. If neither zconf or zcrunner is specified,
a new one is created.

=head4 zcgui

This is the ZConf::GUI to use. If one is not specified,

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#initiates
	if (!defined($args{zcmail})) {
		if (!defined($args{zconf})) {
			$self->{zcm}=ZConf::Mail->new();
		}else {
			$self->{zcm}=ZConf::Mail->new({zconf=>$args{zconf}});
		}
	}else {
		$self->{zcm}=$args{zcmail};
	}

	#handles it if initializing ZConf::Mail failed
	if ($self->{zcm}->{error}) {
		my $errorstring=$self->{zcm}->{errorString};
		$errorstring=~s/\"/\\\"/g;
		my $error='Initializing ZConf::Mail failed. error="'.$self->{zcm}->{error}
		          .'" errorString="'.$self->{zcm}->{errorString}.'"';
	    $self->{error}=3;
		$self->{errorString}=$error;
		warn('ZConf-Mail-GUI new:3: '.$error);
		return $self;		
	}

	if (!defined($args{zconf})) {
		$self->{zconf}=$args{zconf};
	}else {
		$self->{zconf}=$self->{zcm}->{zconf};
	}

	#initializes the GUI
    $self->{gui}=ZConf::GUI->new({zconf=>$self->{zconf}});
	if ($self->{gui}->{error}) {
		my $errorstring=$self->{gui}->{errorString};
		$errorstring=~s/\"/\\\"/g;
		my $error='Initializing ZConf::GUI failed. error="'.$self->{gui}->{error}
		          .'" errorString="'.$self->{gui}->{errorString}.'"';
	    $self->{error}=2;
		$self->{errorString}=$error;
		warn('ZConf-Mail-GUI new:2: '.$error);
		return $self;
	}

	$self->{useX}=$self->{gui}->useX('ZConf::Mail');

	my @preferred=$self->{gui}->which('ZConf::Mail');

	my $toeval='use ZConf::Mail::GUI::'.$preferred[0].';'."\n".
	           '$self->{be}=ZConf::Mail::GUI::'.$preferred[0].
			   '->new({zconf=>$self->{zconf}, useX=>$self->{useX},'.
			   'zcgui=>$self->{gui}, zcmail=>$self->{zcm}}); return 1';

	my $er=eval($toeval);

	return $self;
}

=head2 compose

This opens a window for composing a message.

=head3 args hash

=head4 account

This is the account to use. If this is not defined, the default
sendable account is used.

=head4 to

An array of To addresses.

=head4 cc

An array of CC addresses.

=head4 bcc

An array of BCC addresses.

=head4 files

An array of files to attach.

=head4 in-reply-to

This will set the in-reply-to header value.

    $zcmg->compose({account=>'smtp/whatever', to=>'foo@bar'});
    if($zcmg->{error}){
        print "Error!\n";
    }

=cut

sub compose{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	if (!defined($args{account})) {
		$args{account}=$self->{zcm}->defaultSendableGet;
	}

	#make sure a account is specified
	if (!defined($args{account})) {
		$self->{error}='4';
		$self->{errorString}='No account specified or there is no default sendable';
		warn('ZConf-Mail-GUI compose:4: '.$self->{errorString} );
		return undef;
	}

	$self->{be}->compose(\%args);
	if($self->{be}->{error}){
		$self->{error}=3;
		$self->{errorString}='Backend errored. error="'.$self->{be}->{error}.'" '.
		                     'errorString="'.$self->{be}->{errorString}.'"';
		warn('ZConf-Mail-GUI compose:3: '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 composeFromURI

This composes a new message from a URI.

=head3 args hash

=head4 account

This is the account to use.

=head4 uri

This is the URI to use.

    $zcmg->composeFromURI({account=>'smtp/whatever', uri=>'mailto:foo@bar'});
    if($zcmg->{error}){
        print "Error!\n";
    }

=cut

sub composeFromURI{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	if (!defined($args{account})) {
		$args{account}=$self->{zcm}->defaultSendableGet;
	}

	#make sure a account is specified
	if (!defined($args{account})) {
		$self->{error}='4';
		$self->{errorString}='No account specified or there is no default sendable';
		warn('ZConf-Mail-GUI composeFromURI:4: '.$self->{errorString} );
		return undef;
	}

	#make sure a URI is specified.
	if (!defined($args{uri})) {
		warn('ZConf-Mail-GUI composFromURIe:4: No URI specified' );
		$self->{error}=4;
		$self->{errorString}='No URI specified.';
		return undef;
	}

	if (!($args{uri}=~/[Mm][Aa][Ii][Ll][Tt][Oo]\:/)) {
		$self->{errorString}='Does not appear to be a ';
		$self->{error}=5;
		warn('ZConf-Mail-GUI composeFromURI:4: '.$self->{errorString});
		return undef;		
	}

	my $uri=URI->new($args{uri});

	my $to=$uri->to;

	if (!defined($to) || ($to eq '')) {
		$self->{errorString}='No to address could be found in the URI';
		$self->{error}=6;
		warn('ZConf-Mail-GUI composeFromURI:6: '.$self->{errorString});
		return undef;
	}

	$self->compose({account=>$args{account}, to=>[$to]});
	if ($self->{error}) {
		warn('ZConf-Mail-GUI compmoseFromURI: compose fialed');
	}

	return 1;
}

=head2 manageAccounts

This manages the accounts.

    $zcmg->manageAccounts;
    if($self->{error}){
        print "Error!\n";
    }

=cut

sub manageAccounts{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	$self->{be}->manageAccounts(\%args);
	if($self->{be}->{error}){
		$self->{error}=3;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" '.
		                     'errorString="'.$self->{be}->{errorString}.'"';
		warn('ZConf-Mail-GUI manageAccounts:3: '.$self->{errorString});
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

accountmanage

compose

=head1 ERROR CODES

=head2 1

Failed to initialize ZConf::Mail.

=head2 2

Failed to initialize ZConf::GUI.

=head2 3

Backend error.

=head2 4

Missing arguement.

=head2 5

The URI is not a mailto URI.

=head2 6

The URI appears to not contain any to address.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Mail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Mail::GUI


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

1; # End of ZConf::Runner::GUI
