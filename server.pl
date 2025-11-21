#!/usr/bin/env perl
use strict;
use warnings;
use Socket;
use File::Basename;

my $port = 3000;
my $base_dir = dirname(__FILE__);
my $pagepath='/index.html';

for (@ARGV){
	if (/-h/){ print "remote control: portnumber topURL\n"; exit ; }
	elsif (/^([0-9][0-9]*)$/){ $port=$1 ; }
	else { $pagepath="/$_"; }
}

# Create socket
socket(my $server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
setsockopt($server, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsockopt: $!";
bind($server, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";
listen($server, SOMAXCONN) or die "listen: $!";

print "Server running on http://localhost:$port\n";
print "Press Ctrl+C to stop\n";

while (my $client = accept(my $conn, $server)) {
	my $request = '';
	while (<$conn>) {
		$request .= $_;
		last if /^\r?\n$/;
	}
	
	my ($method, $path) = $request =~ /^(\w+)\s+(\S+)/;
	$method='' unless defined $method;
	$path='' unless defined $path;
	
	# Handle POST /api/execute
	if ($method eq 'POST' && $path eq '/api/execute') {
		# Read POST body
		my $content_length = 0;
		if ($request =~ /Content-Length:\s*(\d+)/i) {
			$content_length = $1;
		}
		
		my $body = '';
		if ($content_length > 0) {
			read($conn, $body, $content_length);
		}
		
		# Extract argument from JSON
		my $argument = '';
		if ($body =~ /"argument"\s*:\s*"([^"]+)"/) {
			$argument = $1;
		}
		
		my $response_body;
		if (!$argument) {
			$response_body = '{"error":"Argument is required"}';
		} else {
			my $script_path = "$base_dir/send_ir.sh";
			
			if (!-f $script_path) {
				$response_body = '{"error":"Script not found"}';
			} else {
				chmod 0755, $script_path;
				
				# Sanitize argument
				$argument =~ s/[^a-zA-Z0-9_-]//g;
				
				# Execute script
				my $output = `bash "$script_path" "$argument" 2>&1`;
				my $exit_code = $? >> 8;
				
				# Escape for JSON
				$output =~ s/\\/\\\\/g;
				$output =~ s/"/\\"/g;
				$output =~ s/\n/\\n/g;
				$output =~ s/\r/\\r/g;
				$output =~ s/\t/\\t/g;
				
				my $success = $exit_code == 0 ? 'true' : 'false';
				$response_body = qq({"success":$success,"exit_code":$exit_code,"output":"$output","argument":"$argument"});
			}
		}
		
		print $conn "HTTP/1.1 200 OK\r\n";
		print $conn "Content-Type: application/json\r\n";
		print $conn "Access-Control-Allow-Origin: *\r\n";
		print $conn "Content-Length: " . length($response_body) . "\r\n";
		print $conn "\r\n";
		print $conn $response_body;
	}
	# Handle OPTIONS for CORS
	elsif ($method eq 'OPTIONS') {
		print $conn "HTTP/1.1 200 OK\r\n";
		print $conn "Access-Control-Allow-Origin: *\r\n";
		print $conn "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n";
		print $conn "Access-Control-Allow-Headers: Content-Type\r\n";
		print $conn "Content-Length: 0\r\n";
		print $conn "\r\n";
	}
	# Serve static files
	else {
		$path =~ s/\?.*//;  # Remove query string
		$path = $pagepath if $path eq '/';
		
		my $file_path = "$base_dir$path";
		
		if (-f $file_path) {
			open my $fh, '<', $file_path or die "Cannot open $file_path: $!";
			my $content = do { local $/; <$fh> };
			close $fh;
			
			my $content_type = 'text/html';
			$content_type = 'text/css' if $path =~ /\.css$/;
			$content_type = 'application/javascript' if $path =~ /\.js$/;
			
			print $conn "HTTP/1.1 200 OK\r\n";
			print $conn "Content-Type: $content_type\r\n";
			print $conn "Content-Length: " . length($content) . "\r\n";
			print $conn "\r\n";
			print $conn $content;
		} else {
			my $error = "404 Not Found";
			print $conn "HTTP/1.1 404 Not Found\r\n";
			print $conn "Content-Type: text/plain\r\n";
			print $conn "Content-Length: " . length($error) . "\r\n";
			print $conn "\r\n";
			print $conn $error;
		}
	}
	
	close $conn;
}

close $server;
