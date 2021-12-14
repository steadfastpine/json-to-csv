#!/usr/bin/perl



# version:		1.0
# author:		Scott Forsberg
# published:	2021-04-12



if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help')
{
print "Usage: json_to_csv	[-u url] [-o output_csv_file] [-i input_json_file]
			[-h help] [-v verbosity]
			[-u] [-o] [-i] [-h] [-v]



This program converts json into csv. It can process a local json formatted file, or access a remote url using the perl curl component.



Structure

It is based upon a custom subroutine called json_to_csv(), which is present within the json_to_csv.pl perl file.
The subroutine is modular and may be removed from the file to be used separately, or run from within the perl file using getopts input switches.



Input switches for json_to_csv.pl

-u 		Remote access url.
		When this option is set, the program will read json content from this url via the curl component.

		default url when no option set: http://api.ptagis.org:80/interrogation sites/configurations


-o 		Output csv filename.
		Then this option is set, the program will write the output csv formatted data to the specified filename.

		default filename when no option set: json_to_csv_output.csv 


-i		Input local json file.
		Then this option is set, the program will read a local file from the input path specified.

		default: not set


-v		Verbosity level.
		When set to 1, this will describe the actions being performed.
		When set to 2, this will print the passed variables between getopts and subroutine.

		default: 0


-h		Help.
		Display instructions for the program.
	


Input switch examples


This example will connect to a json content url (http://api.ptagis.org:80/mrrsites)
and write the output in csv to a local file (test_output.csv).

json_to_csv.pl -o test_output.csv -u http://api.ptagis.org:80/mrrsites -v1


This example will process a json content local file (ptagis_interrogation sites_sample.json)
and write the output in csv to a local file (test_output_local.csv).

json_to_csv.pl -o test_output_local.csv -i ptagis_interrogation sites_sample.json -v1


This example will connect to the default url (http://api.ptagis.org:80/interrogation sites/configurations)
and write it to the default output file (json_to_csv_output.csv).

json_to_csv.pl -v1



Input variables for json_to_csv() subroutine

json_to_csv(\$url,\$file_output_csv,\$file_input_json,\$verbosity)



Output format

The first line of the out csv file contains json keys as column headers.
Subsequent lines will contain the values as content of each column.
Column order is sorted alphabetical ascending by the keys.



Output csv example

\"antennaGroupName\",\"antennaID\",\"configurationSequence\",\"endDate\",\"siteCode\",\"siteName\",\"startDate\",
\"Upstream Eightmile Ck\",\"D1\",\"100\",\"\",\"158\",\"Fifteenmile Ck at Eightmile Ck\",\"2011-11-29T00:00:00\",
\"Middle Eightmile Ck\",\"D2\",\"100\",\"\",\"158\",\"Fifteenmile Ck at Eightmile Ck\",\"2011-11-29T00:00:00\",



Installation of perl components


First, open the perl interface from the bash shell.

> perl -MCPAN -e shell


Next, enter the following commands to install each required component.

> install WWW::Curl::Simple
> install JSON
> install JSON::XS



";
exit;
}



use Getopt::Std;

my %options=();
getopts("u:o:i:v:", \%options);

my $url;
my $file_output_csv;
my $file_input_json;
my $verbosity;

# process switch -u for urls
if (defined $options{u}){
	$url=$options{u};
}

# process switch -o for output csv file path
if (defined $options{o}){
	$file_output_csv=$options{o};
}


# process switch -i for input json file path
if (defined $options{i}){
	$file_input_json=$options{i};
}


# process switch -v for verbosity
if (defined $options{v}){
	$verbosity=$options{v};
}


if($verbosity ge 2){
	print "\n";
	print "getopts - url: ($url)\n";
	print "getopts - file output csv: ($file_output_csv)\n";
	print "getopts - file input json: ($file_input_json)\n";
}






# define the subroutine
sub json_to_csv 
{

	use utf8;
	use strict;
	use JSON;
	use JSON::XS qw( decode_json );

	my ($url, $file_output_csv, $file_input_json, $verbosity) = @_;
	my $content_json;

	if ($url eq ''){
		$url="http://api.ptagis.org:80/interrogationsites/configurations";
	}

	if ($file_output_csv eq ''){
		$file_output_csv="json_to_csv_output.csv";
	}


	if($verbosity ge 2){
		print "\n";
		print "subroutine - url: ($url)\n";
		print "subroutine - file output csv: ($file_output_csv)\n";
		print "subroutine - file input json: ($file_input_json)\n";
	}



	if ($file_input_json ne ''){


		if($verbosity ge 1){
			print "\nperforming conversion on local json input file: ($file_input_json)\n";
			print "output csv file: ($file_output_csv)\n\n";
		}

		open(my $fh, '<', $file_input_json) or die "# error: cannot open json input file $file_input_json\n\n";
		{
			local $/;
			$content_json = <$fh>;
		}
		close($fh);

	}elsif($url ne ''){

		if($verbosity ge 1){
			print "\nperforming conversion on remote json url: ($url)\n";
			print "output csv file: ($file_output_csv)\n\n";
		}

		# perl curl
		use WWW::Curl::Easy;

		my $curl = WWW::Curl::Easy->new;
		$curl->setopt(CURLOPT_HEADER,0);
		$curl->setopt(CURLOPT_URL, "$url");
		$curl->setopt(CURLOPT_WRITEDATA,\$content_json);
		 
		my $retcode = $curl->perform;
		 
		if ($retcode == 0) {
			my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
		}
	}


	# decode json content
	my $json = decode_json($content_json);

	# format the open file handle to process utf-8
	use open ":std", ":encoding(UTF-8)";

	# open file for writing
	open(FH, '>', $file_output_csv) or die $!;


	# iterates through keys of json data for csv header
	for my $record (@$json) {

		my $line;
		for my $key (sort keys(%$record)) {


			$line=$line.'"'.$key.'",';

		}

		print FH "$line\n";
		last;
	}


	# iterates through values of json data for csv content
	for my $record (@$json) {

		my $line;
		for my $key (sort keys(%$record)) {

			my $val = $record->{$key};

			$line=$line.'"'.$val.'",';
		}

		print FH "$line\n";
	}


	# close file
	close(FH);
}


# calling subroutine
json_to_csv($url,$file_output_csv,$file_input_json,$verbosity);
  
















