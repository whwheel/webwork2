package WeBWorK::ContentGenerator::Instructor::PGProblemEditor;
use base qw(WeBWorK::ContentGenerator::Instructor);


=head1 NAME

WeBWorK::ContentGenerator::Instructor::ProblemSetEditor - Edit a set definition list

=cut

use strict;
use warnings;
use CGI qw();
use WeBWorK::Utils qw(readFile);
use Apache::Constants qw(:common REDIRECT);


our $libraryName;
our $rowheight;

sub title {
	my $self = shift;
	#FIXME  don't need the entire path  ??
	return "Instructor Tools - PG Problem Editor for ". $self->{ce}->{problemPath};
}
sub go {
	my $self 			= shift;
	my ($setName, $problemNumber) = @_;
	my $r 				= 	$self->{r};
	my $ce				=	$self->{ce};
	my $submit_button 	= $r->param('submit');  # obtain submit command from form

	# various actions depending on state.
	if (     defined($submit_button) and ($submit_button eq 'Save' or $submit_button eq 'Refresh')    ) {
	
		$self->initialize($setName,$problemNumber);  # write the necessary files
													 # return file path for viewing problem
													 # in $self->{ce}->{currentSourceFilePath}
		#redirect to view the problem
		
		my $hostname 		= 	$r->hostname();
		my $port     		= 	$r->get_server_port();
		my $uri		 		= 	$r->uri;
		my $courseName		=	$self->{ce}->{courseName};
		my $editFileSuffix  =	$self->{ce}->{editFileSuffix};
		my $seed			= 	($r->param('seed')) ? $r->param('seed') : '';
		my $displayMode		=	($r->param('displayMode')) ? $r->param('displayMode') : '';

		my $viewURL  		= 	"http://$hostname:$port";
		$viewURL		   .= 	"/webwork/$courseName/$setName/$problemNumber/?";
		$viewURL		   .=	$self->url_authen_args;
		$viewURL		   .=   "&displayMode=$displayMode&seed=$seed";   # optional displayMode and seed overrides
		$viewURL		   .=	"&editMode=temporaryFile";
		$viewURL		   .=	'&sourceFilePath='.$self->{ce}->{currentSourceFilePath}; # path to pg text for viewing
		$viewURL		   .=	"&submit_button=$submit_button";                         # allows Problem.pg to recognize state
		$viewURL		   .=   '&editErrors='.$self->{ce}->{editErrors};																				 # of problem being viewed.
		$r->header_out(Location => $viewURL );
		return REDIRECT;
	} else {
		# initialize and 
		# display the editing window
		
		$self->SUPER::go(@_);
	}

}


sub body {
	my $self = shift;
	
	# test area
	my $r 		= 	$self->{r};
	my $db 		= 	$self->{db};
	my $ce		=	$self->{ce};
	my $user 	= 	$r->param('user');
	my $key 	= 	$db->getKey($user)->key();
	
	
	################
	# Gathering info
	# What is needed
	#     $problemPath  -- 
	#     $formURL -- given by $r->uri
	#     $tmpProblemPath 
	#my ($problemPath,$formURL,$tmpProblemPath) = $self->initialize();
	my $problemPath 	= 	$ce->{problemPath};

	#my $tmpProblemPath	=	$ce->{tmpProblemPath};
	
	

	
	

	my $header = "Problem Editor:  $problemPath";

	#########################################################################
	# Find the text for the problem, either in the tmp file, if it exists
	# or in the original file in the template directory
	#########################################################################
	my $problemContents = '';
# 	my $editMode		= (defined($r->param('problemContents')))? 
# 								'tmpMode':'startMode';
# 	
# 	if ( $editMode eq 'tmpMode') {
# 		$problemContents	=	$r->param('problemContents');
# 
# 	} else{
	eval { $problemContents	=	WeBWorK::Utils::readFile($problemPath)  };  # try to read file
	$problemContents = $@ if $@;
#	} 
		
	#  save Action  FIXME  -- is this the write place for this?
# 	my $actionString = '';
# 	if ($r->param('submit') eq 'Save') {
# 		$actionString = "File saved to $problemPath";
# 		#FIXME  it would be MUCH better to work with temporary files
# 		open(FILE,">$problemPath") or die "Can't open $problemPath";
# 		print FILE $problemContents;
# 		close(FILE);
# 		
#	}

	
			
			
	#########################################################################
	# Format the page
	#########################################################################
	# Define parameters for textarea
	# FIXME these parameters should be capable of being updated dynamically.
	my $rows 		= 	20;
	my $columns		= 	80;
	my $mode_list 	= 	['HTML', 'HTML_tth','HTML_dpng', 'Latex2HTML'];
	my $mode	  	= 	( defined($r->param('mode')) 	) ? $r->param('mode') : 'HTML_tth';
	my $seed		=	( defined($r->param('seed'))	) ? $r->param('seed') : '1234';	
	my $uri			=	$r->uri;
	########################################################################
	# Define a link to view the problem
	#FIXME
	
	#########################################################################

	


			   
	return CGI::p($header),
		#CGI::start_form("POST",$r->uri,-target=>'_problem'),  doesn't pass on the target parameter???
		qq!<form method="POST" action="$uri" enctype="application/x-www-form-urlencoded", target="_problem">!,
		$self->hidden_authen_fields,
		CGI::div(
		CGI::textfield(-name=>'seed',-value=>$seed),
		'Mode: ',
		CGI::popup_menu(-name=>'mode', -'values'=>$mode_list,
													 -default=>$mode),
		CGI::a(
			{-href=>'http://webwork.math.rochester.edu/docs/docs/pglanguage/manpages/',-target=>"manpage_window"},
			'Manpages',
			)
		),
		CGI::p(
			CGI::textarea(-name => 'problemContents', -default => $problemContents,
						  -rows => $rows, -columns => $columns, -override => 1,
			),
		),
		CGI::p(
			CGI::submit(-value=>'Refresh',-name=>'submit'),
			CGI::submit(-value=>'Save',-name=>'submit'),
#			$actionString
		),
		
		#CGI::a({-href=>$ce->{viewProblemURL},-target=>'_viewProblem'},'view problem'),
		CGI::end_form(),
		"<p> the parameters passed are "  #FIXME -- debugging code
		. join("<BR>", %{$r->param()}) . 
		"</p> and the gatheredInfo is ",
		"problemPath=$problemPath<br> formURL=".$r->uri . "<br>"   ,
#		"viewProblemURL ".$ce->{viewProblemURL}."<br>",
#		"problem_obj =". $ce->{problem_obj}."<br>",
		"path_components ". $ce->{path_components}.'<br>',
# 		"hostname =$hostname<br>",
# 		"port =$port <br>",
 		"uri = $uri <br>",
# 		"viewURL =".$ce->{viewURL}."<br>",
		 
	;


}

sub initialize {
	
	my ($self, $setName, $problemNumber) = @_;
	my $ce 						= 	$self->{ce};
	my $r						=	$self->{r};
	my $path_info 				= 	$r->path_info || "";
	my $db						=	$self->{db};
	my $user					=	$r->param('user');
	my $effectiveUserName		=	$r->param('effectiveUser');
	my $courseName				=	$ce->{courseName};
	
	my $set            			= 	$db->getGlobalUserSet($effectiveUserName, $setName);
	my $setID					=	$set->set_id;
	
	# Find URL for viewing problem
#	my $viewProblemURL		=	"/webwork/$courseName/".join("/",$setID,$problemNumber)."?" .$self->url_authen_args();
	
	# find path to pg file for the problem
	# FIXME  there is a descrepency in the way that the problems are found.
	# my $problem_record		=	$db->getUserProblem($user,$setID,1);
	my $problem_record          = 	$db->getGlobalUserProblem($effectiveUserName, $setName, $problemNumber);
	my $templateDirectory	=	$ce->{courseDirs}->{templates};
	my $problemPath			=	$templateDirectory."/".$problem_record->source_file;
	my $editFileSuffix		=	'tmp';
	my $submit_button		= 	$r->param('submit');
	
	my $problemContents	= '';
	my $currentSourceFilePath	=	'';
	# update the .pg and .pg.tmp files in the directory
	if (not defined($submit_button) ) {
		# this is a fresh editing job
		# copy the pg file to a new file with the same name with .tmp added
		# store this name in the $ce->currentSourceFilePath for use in body 
		
		eval { $problemContents			=	WeBWorK::Utils::readFile($problemPath)  
		};  # try to read file
		$problemContents = $@ if $@;
		$currentSourceFilePath			=	"$problemPath.$editFileSuffix"; 
		$ce->{currentSourceFilePath}	=	$currentSourceFilePath; 
	} elsif ($submit_button	eq 'Refresh' ) {
		# grab the problemContents from the form and save it to the tmp file
		# store tmp file name in the $ce->currentSourceFilePath for use in body 
		
		$problemContents				=	$r->param('problemContents');
		$currentSourceFilePath			=	"$problemPath.$editFileSuffix";	
		$ce->{currentSourceFilePath}	=	$currentSourceFilePath;
	} elsif ($submit_button eq 'Save') {
		# grab the problemContents from the form and save it to the permanent file
		# unlink (delete) the temporary file
		# store the permanent file name in the $ce->problemContents for use in body 
		
		$problemContents				=	$r->param('problemContents');
		$currentSourceFilePath			=	"$problemPath"; 		
		$ce->{currentSourceFilePath}	=	$currentSourceFilePath;		
	} else {
		# give a warning
		die "Unrecognized submit command $submit_button";
	}
	# print changed pg files
	# FIXME  make sure that the permissions are set correctly!!!
	# Make sure that the warning is being transmitted properly.
	eval {
		local *OUTPUTFILE;
		open OUTPUTFILE, ">", $currentSourceFilePath
				or die "Failed to write to $currentSourceFilePath: $!";
		print OUTPUTFILE $problemContents;
		close OUTPUTFILE;
	};
	my $errors = $@ if $@;
	if (  $errors)   {
	
		$ce->{editErrors}	= "Unable to write to $currentSourceFilePath: $errors";
		
	} else {	# unlink the temporary file if there are no errors.
		$ce->{editErrors}	=	'';
		unlink("$problemPath.$editFileSuffix") if defined($submit_button) and $submit_button eq 'Save';
		
	};
	
		
	# return values.  FIXME  -- is this the right way to pass the values to body??
	# $ce->{viewProblemURL}	=	$viewProblemURL;
	$ce->{problemPath} 		= 	$problemPath;
	$ce->{path_components}	=	join("/",$setID,$problemNumber);
	
	# FIXME  there is no way to edit in a temporary file -- all editing takes place on disk!!!

	
	
}

# sub gatherProblemList {   #workaround for obtaining the definition of a problem set (awaiting implementation of db function)
# 	my $self = shift;
# 	my $setName = shift;
# 	my $output = "";
# 	if ( defined($setName) and $setName ne "" ) {
# 		my $templateDirectory = $self->{ce}->{courseDirs}->{templates};
# 		my $fileName = "$templateDirectory/$setName.def";
# 		my @output =  split("\n",WeBWorK::Utils::readFile($fileName) );
# 		@output = grep  /\.pg/,   @output;     # only get the .pg files
# 		@output = grep  !/Header/, @output;   # eliminate header files
# 		$output = join("\n",@output);
# 	} else {
# 		$output = "No set name |$setName| is defined";
# 	}
# 	
# 	
# 	return  $output
# 
# 
# 
# 
# }
# sub fetchSetDirectories {
# 
# 	my $self = shift;
# 	my $defaultChoice = shift;
# 	my $templateDirectory = $self->{ce}->{courseDirs}->{templates};
# 	opendir SETDEFDIR, $templateDirectory 
# 		or return "Can't open directory $templateDirectory";
# 	
# 	my @allFiles = grep !/^\./, readdir SETDEFDIR;
# 	closedir  SETDEFDIR;
# 
# 	## filter to find only the set directories 
# 	## -- it is assumed that these directories don't contain a period in their names
# 	## and that all other files do.  Directories names must also begin with "set".
# 	## A better plan would be to read only the names of directories, not files.
# 	
# 	## sort the directories
# 	my @setDefFiles = grep /^set[^\.]*$/, @allFiles;
# 	my @sortedNames = sort @setDefFiles;
# 
# 	return "$libraryName/" . CGI::br(). CGI::popup_menu(-name=>'setDirectory', -size=>$rowheight,
# 	 -values=>\@sortedNames, -default=>$defaultChoice ) .CGI::br() ;
# }
# 
# sub fetchPGproblems {
# 
# 	my $self = shift;
# 	my $setDirectory = shift;
# 	
# 	# Handle default for setDirectory  
# 	# fix me -- this is not bullet proof
# 	$setDirectory = "set0" unless defined($setDirectory);
# 	my $templateDirectory = $self->{ce}->{courseDirs}->{templates};
# 	
# 	## 
# 	opendir SETDEFDIR, "$templateDirectory/$setDirectory" 
# 		or return "Can't open directory $templateDirectory/$setDirectory";
# 	
# 	my @allFiles = grep !/^\./, readdir SETDEFDIR;
# 	closedir  SETDEFDIR;
# 
# 	## filter to find only pg problems 
# 	## Some problems are themselves in directories (if they have auxiliary
# 	## .png's for example.  This eventuallity needs to be handled.
# 	
# 	## sort the directories
# 	my @pgFiles = grep /\.pg$/, @allFiles;
# 	my @sortedNames = sort @pgFiles;
# 
# 	return "$setDirectory ". CGI::br() . 
# 	CGI::popup_menu(-name=>'pgProblem', -size=>$rowheight, -multiple=>undef, -values=>\@sortedNames,  ) . 
# 	CGI::br() ;
# }

1;
