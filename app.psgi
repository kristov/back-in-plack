#!/usr/bin/env perl
use strict;
use warnings;
use Plack::Request;                                                  
use Plack::Response;                                                 
use Template;                                                        
my $tt = Template->new({INCLUDE_PATH => "./"});                      
my $app = sub {
    my ($env) = @_;                                                  
    my $request = Plack::Request->new($env);
    my $response = Plack::Response->new;                             
    $response->status(200);                                          
    my $body = "";                                                   
    $tt->process("hello.html", {path => $request->path}, \$body);    
    $response->body($body);                                          
    return $response->finalize;
};
$app;
