package Catalyst::View::GraphViz;

use strict;
use base qw/Catalyst::Base/;
use GraphViz;
use NEXT;

our $VERSION = '0.01_1';

=head1 NAME

Catalyst::View::GraphViz - GraphViz View Class

=head1 SYNOPSIS

=head2 Use the helper

    myapp_create.pl view GraphViz GraphViz


=head2 In your application's View class

    #lib/MyApp/View/GraphViz.pm
    package MyApp::View::GraphViz;

    use base 'Catalyst::View::GraphViz';

    #Override the default format (which is png)
    __PACKAGE__->config->{format} = 'gif';

    1;


=head2 Build the GraphViz object

    #In some Controller method (or rather; some View method since
    #that's where the View code should go. See below.)
    use GraphViz;
    $graph = GraphViz->new();
    $graph->add_node("Hello", shape => 'box');
    $graph->add_node("world", shape => 'box');
    $graph->add_edge("Hello", "world");
    
    $c->stash->{graphviz}->{graph} = $graph;
    $c->stash->{graphviz}->{format} = "cmapx"; #HTML image map (default: png)
    


=head2 Forward to the View

    #Meanwhile, maybe in a private C<end> action
    if(!$c->res->body) {
        if($c->stash->{template}) {
            $c->forward('Graphiti::V::TT');
        } elsif($c->stash->{graphviz}->{graph}) {
            $c->forward('Graphiti::View::GraphViz');  #This was created by the helper
        } else {
            die("No output method!\n");
        }
    }



=head1 DESCRIPTION

This is the Catalyst view class for L<GraphViz>. Your application
subclass should inherit from this class.

This plugin renders the GraphViz object specified in
C<$c-E<gt>stash-E<gt>{graphviz}-E<gt>{graph}> into the
C<$c-E<gt>stash-E<gt>{graphviz}-E<gt>{format}> (one of e.g. png
gif, or one of the other as_* methods described in the
L<GraphViz> module. PNG is the default format.

The output is stored in C<$c-E<gt>response-E<gt>output>.

The normal way of using this is to render a PNG image for a request
and let Catalyst serve it.

Another use of this View is to let it generate the text of a client
side imagemap (using a SubRequest) which you then put into the web
page currently being rendered. See below for an example.


=head2 Build the GraphViz Object In a View

The Catalyst::View::GraphViz takes a pre-built GraphViz object to
render. But where should this GraphViz object be constructed?

Consider how the GraphViz View relates to templating systems:

              Templating System      GraphViz
              -----------------      --------
  Model     | Model object(s)        Model object(s) (a graph)
  View      | TT/Mason/?             View::GraphViz
  View code + Template file          View class
  Output    | Rendered HTML          Rendered graph image

So when using TT as a rendering engine, the template contains the
instructions for how to display Model. You have many templates for
displaying the same model object in different ways.

And when using GraphViz as a rendering engine, the View class contains
the instructions for how to display the Model. You have many View
classes for displaying the same model object in different ways.

Here's how to create a specific View class for each type of graph.




=head2 Make A Subrequest To Generate An Imagemap



=head1 METHODS

=head2 new($c)

The constructor for the GraphViz view. Sets up the template provider, 
and reads the application config.

=cut
sub new {
    my $self = shift;
    my $c    = shift;

    $self = $self->NEXT::new(@_);

    return $self;
}

=head2 process($c)

Render the GraphViz object specified in
C<$c-E<gt>stash-E<gt>{graphviz}>.

Output is stored in C<$c-E<gt>response-E<gt>output>.

=cut
my $plain = 'text/plain; charset=utf-8';
my $html = 'text/html; charset=utf-8';
my %hExtType = (
    ps => 'application/postscript',
    hpgl => $plain,
    pcl => $plain,
    mif => 'application/x-mif',
    pic => 'image/x-pict',
    gd => $plain,
    gd2 => $plain,
    gif => 'image/gif',
    jpeg => 'image/jpeg',
    png => 'image/x-png',
    wbmp => 'image/x-ms-bmp',
    cmap => $plain,
    cmapx => $plain,
    ismap => $plain,
    imap => $plain,
    vrml => 'x-world/x-vrml',
    vtx => $plain, #?
    mp => $plain,  #?
    fig => $plain, #?
    svg => 'image/svg+xml',
    svgz => 'image/svg+xml',
    dot => $plain,
    canon => $plain,
    plain => $plain,
);
sub process {
    my ($self, $c) = @_;

    my $oGv = $c->stash->{graphviz}->{graph};
    if(!$oGv) {
        $c->log->debug('No GraphViz object specified in $c->stash->{graphviz}->{graph} for rendering') if $c->debug;
        return 0;
    }

    my $format = $c->stash->{graphviz}->{format} || $c->config->{graphviz}->{format} || $self->config->{format} || "png";
    my $contentType;
    my $output;
    eval {
        $c->log->debug(qq/Rendering GraphViz object as ($format)/) if $c->debug;
        $contentType = $hExtType{$format} or die("Unknown format ($format). Known formats are (" . join("|", sort keys %hExtType) . ")\n");

        my $methodRender = "as_$format";
        $output = $oGv->$methodRender() or die("Could not render GraphViz obejct as ($format)\n");
    };
    if($@) {
        my $error = $@;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }
    
    $c->response->content_type or $c->response->content_type($contentType);

    $c->response->body($output);

    return 1;
}





=head2 config

This allows your view subclass to pass additional settings to the
GraphViz config hash.

=cut





=head1 SEE ALSO

L<Catalyst>, L<GraphViz>



=head1 AUTHOR

Johan Lindström, C<johanl@cpan.org>



=head1 CREDITS

Largely based on the TT view.

Obviosly uses Acme's L<GraphViz> module, which in turn uses the
brilliant GraphViz package (http://www.graphviz.org/).

Quick link to a useful, but obscure, doc page:
http://www.graphviz.org/pub/scm/graphviz2/doc/info/shapes.html



=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
