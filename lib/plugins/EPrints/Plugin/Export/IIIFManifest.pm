package EPrints::Plugin::Export::IIIFManifest;

use EPrints::Plugin::Export::TextFile;
use JSON;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "IIIF Manifest";
	$self->{accept} = [ 'dataobj/*' ];
	$self->{visible} = "all";
	$self->{suffix} = ".js";
	$self->{mimetype} = "application/json; charset=utf-8";

	return $self;
}

sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;
print STDERR "output dataobj\n";

	my $repo = $plugin->repository;
	my $id = $dataobj->uri;

	my $IMAGE_SERVER_URL = $plugin->param( 'image_server_url' ) || sprintf( '%s/%s', $repo->config( 'base_url' ), 'iiif');
	my $IMAGE_SERVER_BASE = $plugin->param( 'image_server_base' ) || $dataobj->value( 'dir' );

	my $data = {
		'@context' => 'http://iiif.io/api/presentation/2/context.json',
		'@id' => $id,
		'@type' => 'sc:Manifest',
		label => $dataobj->value( 'title' ),
		sequences => [
			{ 
				'@id' => sprintf( '%s/sequence/0', $id ),
				'@type' => 'sc:Sequence',
				label => 'Sequence 0'
			}
		],
		metadata => [
			{
				label => 'Title',
				value => $dataobj->value( 'title' ),
			}
		],
	};

	my @canvases;
	my @docs = $dataobj->get_all_documents;
	for( my $i = 0; $i < scalar @docs; $i++ )
	{
		my $doc = $docs[$i];
		my $path = sprintf( '%s/%s', $IMAGE_SERVER_BASE, $doc->exists_and_set( 'relative_path' ) ? $doc->value( 'relative_path' ) : $doc->value( 'main' ) );
		my $canvas = sprintf( '%s/canvas/%s/%d', $id, $path, $i );

		push @canvases, {
			'@id' => $canvas,
			'@type' => 'sc:Canvas',
			thumbnail => sprintf( '%s%s', $repo->config( 'http_url' ), $doc->thumbnail_url( 'small' ) ),
			images => [
				{
					'@id' => sprintf( '%s/imageanno/%s', $id, $path ),
					'@type' => 'oa =>Annotation',
					resource => {
						'@id' => sprintf( '%s/res/%s', $id, $path ),
						'@type' => 'dcTypes =>Image',
						service => {
							'@context' => 'http://iiif.io/api/image/2/context.json',
							'@id' => sprintf( '%s/%s', $IMAGE_SERVER_URL, $path ),
							profile => 'http://iiif.io/api/image/2/level1.json'
						}
					},
					on => $canvas
				}
			]
		};
	}

	$data->{sequences}->[0]->{canvases} = \@canvases;

	return JSON->new->pretty(1)->encode( $data );
}

1;
