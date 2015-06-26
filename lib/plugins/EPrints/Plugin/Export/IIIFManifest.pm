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
	my( $plugin, $eprint ) = @_;
print STDERR "output dataobj\n";

	my $repo = $plugin->repository;
	my $id = $eprint->uri;

	my $IIIF_SERVER_URL = $plugin->param( 'iiif_server_url' ) || sprintf( '%s/%s', $repo->config( 'base_url' ), 'iiif' );
	my $IIIF_BASE_PATH = $plugin->param( 'iiif_base_path' ) || $eprint->value( 'dir' );
	my $IIIF_PATH_FIELD = $plugin->param( 'iiif_path_field' );

	my $data = {
		'@context' => 'http://iiif.io/api/presentation/2/context.json',
		'@id' => $id,
		'@type' => 'sc:Manifest',
		label => $eprint->value( 'title' ),
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
				value => $eprint->value( 'title' ),
			}
		],
	};

	my @docs;
	if( $eprint->value( 'type' ) eq 'collection' )
	{
		# gather parts
		my $parts = $repo->dataset( 'eprint' )->search(
			{
				filters => [
					{ metadata_fields => [qw( relation_type )], 'http://purl.org/dc/terms/isPart', 'EX' },
					{ metadata_fields => [qw( relation_uri )], $eprint->internal_uri, 'EX' },
				],
				satisfy_all => 1,
				custom_order => 'placement',
			}
		);
		$parts->map( $repo, sub {
			my( undef, undef, $eprint, $docs ) = @_;

			push @$docs, $eprint->get_all_documents;
		}, \@docs );
	}
	else
	{
		@docs = $eprint->get_all_documents;
	}

	my @canvases;
	for( my $i = 0; $i < scalar @docs; $i++ )
	{
		my $doc = $docs[$i];
		my $path = sprintf( '%s/%s', $IIIF_BASE_PATH, $doc->exists_and_set( $IIIF_PATH_FIELD ) ? $doc->value( $IIIF_PATH_FIELD ) : $doc->value( 'main' ) );
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
							'@id' => sprintf( '%s/%s', $IIIF_SERVER_URL, $path ),
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
