# ==========================================================================
#
# ZoneMinder Foscam FI8910W IP Control Protocol Module
# Copyright (C) 2012  Troy Will
# from the Zoneminder PanasonicIP.pm by Philip Coombes, Copyright (C) 2001-2008
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# ==========================================================================
#
# This module contains an implementation of a Foscam IP FI8910W camera control
# protocol
#
package ZoneMinder::Control::FoscamFI8910W;

use 5.006;
use strict;
use warnings;

require ZoneMinder::Base;
require ZoneMinder::Control;

our @ISA = qw(ZoneMinder::Control);

our $VERSION = $ZoneMinder::Base::VERSION;

# ==========================================================================
#
# Foscam FI8910W IP Control Protocol
#
# ==========================================================================

use ZoneMinder::Logger qw(:all);
use ZoneMinder::Config qw(:all);

use Time::HiRes qw( usleep );

sub new {
    my $class = shift;
    my $id    = shift;
    my $self  = ZoneMinder::Control->new($id);
    bless( $self, $class );
    srand( time() );
    return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self  = shift;
    my $class = ref($self) || croak("$self not object");
    my $name  = $AUTOLOAD;
    $name =~ s/.*://;
    if ( exists( $self->{$name} ) ) {
        return ( $self->{$name} );
    }
    Fatal("Can't access $name member of object of class $class");
}

sub open {
    my $self = shift;

    $self->loadMonitor();

    use LWP::UserAgent;
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent( "ZoneMinder Control Agent/" . ZM_VERSION );

    $self->{state} = 'open';
}

sub close {
    my $self = shift;
    $self->{state} = 'closed';
}

sub printMsg {
    my $self    = shift;
    my $msg     = shift;
    my $msg_len = length($msg);

    Debug( $msg . "[" . $msg_len . "]" );
}

sub sendCmd {
    my $self = shift;
    my $cmd  = shift;

    my $result = undef;

    printMsg( $cmd, "Tx" );

    my $camera_address = $self->{Monitor}->{ControlAddress};
    my $credentials    = $self->{Monitor}->{ControlDevice};
    my $req =
      HTTP::Request->new(
        GET => "http://$camera_address/$cmd" . '&' . "$credentials" );

    my $res = $self->{ua}->request($req);

    if ( $res->is_success ) {
        $result = !undef;
    }
    else {
        Error( "Error check failed: '" . $res->status_line() . "'" );
    }

    return ($result);
}

sub cameraReset {
    my $self = shift;
    Debug("Camera Reset");
    my $cmd = "nphRestart?PAGE=Restart&Restart=OK";
    $self->sendCmd($cmd);
}

sub moveConUp {
    my $self = shift;
    Debug("Move Up");
    my $cmd = "decoder_control.cgi?command=0";
    $self->sendCmd($cmd);
}

sub moveStop {
    my $self = shift;
    Debug("Move Stop");
    my $cmd = "decoder_control.cgi?command=1";
    $self->sendCmd($cmd);
}

sub moveConDown {
    my $self = shift;
    Debug("Move Down");
    my $cmd = "decoder_control.cgi?command=2";
    $self->sendCmd($cmd);
}

sub moveConLeft {
    my $self = shift;
    Debug("Move Left");
    my $cmd = "decoder_control.cgi?command=6";
    $self->sendCmd($cmd);
}

sub moveConRight {
    my $self = shift;
    Debug("Move Right");
    my $cmd = "decoder_control.cgi?command=4";
    $self->sendCmd($cmd);
}

sub moveConUpRight {
    my $self = shift;
    Debug("Move Diagonally Up Right");
    my $cmd = "decoder_control.cgi?command=90";
    $self->sendCmd($cmd);
}

sub moveConDownRight {
    my $self = shift;
    Debug("Move Diagonally Down Right");
    my $cmd = "decoder_control.cgi?command=92";
    $self->sendCmd($cmd);
}

sub moveConUpLeft {
    my $self = shift;
    Debug("Move Diagonally Up Left");
    my $cmd = "decoder_control.cgi?command=91";
    $self->sendCmd($cmd);
}

sub moveConDownLeft {
    my $self = shift;
    Debug("Move Diagonally Down Left");
    my $cmd = "decoder_control.cgi?command=93";
    $self->sendCmd($cmd);
}

sub presetClear {
    my $self   = shift;
    my $params = shift;
    my $preset = $self->getParam( $params, 'preset' );
    Debug("Clear Preset $preset");
    my $cmd = "nphPresetNameCheck?Data=$preset";
    $self->sendCmd($cmd);
}

sub presetSet {
    my $self      = shift;
    my $params    = shift;
    my $preset    = $self->getParam( $params, 'preset' );
    my $presetCmd = 30 + ( $preset * 2 );
    Debug("Set Preset $preset: $presetCmd");
    my $cmd = "decoder_control.cgi?command=$presetCmd";
    $self->sendCmd($cmd);
}

sub presetGoto {
    my $self      = shift;
    my $params    = shift;
    my $preset    = $self->getParam( $params, 'preset' );
    my $presetCmd = 31 + ( $preset * 2 );
    Debug("Goto Preset $preset: $presetCmd");
    my $cmd = "decoder_control.cgi?command=$presetCmd";
    $self->sendCmd($cmd);
}

sub presetHome {
    my $self = shift;
    Debug("Home Preset");
    my $cmd = "decoder_control.cgi?command=25";
    $self->sendCmd($cmd);
}

1;
