# the URL of the IIIF-compliant image server
# $c->{plugins}{"Export::IIIFManifest"}{params}{iiif_server_url} = "";
# the base path of images on the server
# $c->{plugins}{"Export::IIIFManifest"}{params}{iiif_base_path} = "";
# the field in the document object that contains the path and filename of the image on the server
# $c->{plugins}{"Export::IIIFManifest"}{params}{iiif_path_field} = "";

$c->{plugins}{"Export::IIIFManifest"}{params}{disable} = 0;
