#!/usr/bin/perl
use warnings;
use diagnostics;
use strict;

use LWP;
use Data::Dumper;
use XML::RSS;
use DateTime;
use DateTime::Format::HTTP;
use WWW::LargeFileFetcher;
use URI;

our $feed_url='http://www.nhk.or.jp/r-news/podcast/nhkradionews.xml';
our $http_proxy="";
our $get_timeout=30;

our $html_agent = LWP::UserAgent->new;
$html_agent->proxy('http',$http_proxy);
$html_agent->agent('Mozilla/4.0');
$html_agent->timeout($get_timeout);

my $mp3_fetcher = WWW::LargeFileFetcher->new(proxy=>$http_proxy);

binmode STDOUT, ':utf8';

my $HTML;

my $response = $html_agent->get($feed_url);

if ($response->is_success) {
	$HTML = $response->decoded_content;  # or whatever
}
else {
	die $response->status_line;
}


#die $HTML;

# here we parse the html and grab the links
my $rss = XML::RSS->new();
$rss->parse($HTML);

#print Dumper($rss);


foreach my $item (@{$rss->{'items'}}) {
	my $title = $item->{title};
	next unless $title;

	my $item_url = $item->{enclosure}->{url};
	next unless $item_url;

	print $title,"\n";
	print $item_url,"\n";

	my $uri = URI->new($item_url);

	my $path = ($uri->path_segments)[-1];

	if(-e $path){
		print "$path exists\n";
		next;
	}

	print "downloading $path\n";
	if ( 1 != $mp3_fetcher->get($uri->as_string, $path) ){
		print $mp3_fetcher->err_str,"\n";
		next;
	}

	if( -s $path < 1024*1024){
		print "filesize too small, giveup\n";
		unlink $path;
		next;
	}

	print "============================\n";
} 
