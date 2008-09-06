#!/usr/bin/perl -w
use File::Spec;

use strict;
use warnings;

my $path_tandem = '/usr/local/src/tandem-linux-08-02-01-3/bin/tandem.exe';
my $parent_dir = File::Spec->rel2abs('..');
my $current_dir = File::Spec->rel2abs('.');
my $file_taxonomy = File::Spec->catfile($parent_dir,'tandem-taxonomy.xml');
my $file_input = File::Spec->catfile($parent_dir,'tandem-isb_input_kscore.xml');

#my $db_name = 'ECOLI_MG1655_BKRB2';
my $db_name = 'YEAST_ensembl50';

my $file_shell = 'run-tandem_k.sh';
my $tandem_dir = 'tandem_k';

unless( -d $tandem_dir ) {
  print STDERR "Make $tandem_dir\n";
  `mkdir $tandem_dir`;
}

open(SHELL, ">$file_shell");
print SHELL "#!/bin/bash\n";
foreach my $file_mzxml (`ls mzXML/*mzXML`) {
  chomp($file_mzxml);
  my $file_base = 'unknown';
  if( $file_mzxml =~ /mzXML\/([A-z0-9_\-\.]+)\.mzXML/ ) {
    $file_base = $1;
  }
  if( $file_base eq 'unknown' ) {
    die "Unknown file_base : $file_mzxml\n";
  }

  #print STDERR $file_base,"\n";
  my $file_config = $file_base.'.tandem_k.xml';
  $file_config = File::Spec->catfile($current_dir,$tandem_dir,$file_config);
  my $file_output = $file_base.'.tandem_k.out';
  $file_output = File::Spec->catfile($current_dir,$tandem_dir,$file_output);
  my $file_seq = $file_base.'.tandem_k.seq';
  $file_seq = File::Spec->catfile($current_dir,$tandem_dir,$file_seq);
  my $file_log = $file_base.'.tandem_k.log';
  $file_log = File::Spec->catfile($current_dir,$tandem_dir,$file_log);
  my $file_pepxml = $file_base.'.tandem_k.pepxml';
  $file_pepxml = File::Spec->catfile($current_dir,$tandem_dir,$file_pepxml);

  print STDERR "Write $file_config ... ";
  open(CONF,">$file_config");
  print CONF &tandem_config_xml( 
                        -input_xml => $file_input,
                        -mzXML => $file_mzxml, -output => $file_output,
                        -seq => $file_seq, -log => $file_log,
                        -taxonomy => $file_taxonomy, -db_name => $db_name),"\n";
  close(CONF);
  print STDERR "Done\n";
  print SHELL $path_tandem,' ',$file_config,"\n";
  #print SHELL join(' ',$path_tandem2xml,$file_output,$file_pepxml),"\n";
  $file_output =~ s/out/\*out/g;
  print SHELL "gzip $file_output\n";
  #print SHELL "gzip $file_pepxml\n";
}
close(SHELL);
`chmod 744 $file_shell`;

sub tandem_config_xml {
  my %param = @_;

  my $rv = '<?xml version="1.0" encoding="UTF-8"?><bioml>'."\n";
  $rv .= '<note type="input" label="list path, default parameters">';
  $rv .= $param{-input_xml}."</note>\n";

  $rv .= '<note type="input" label="spectrum, path">';
  $rv .= $param{-mzXML}."</note>\n";

  $rv .= '<note type="input" label="output, path">';
  $rv .= $param{-output}."</note>\n";

  $rv .= '<note type="input" label="output, log path">';
  if( exists $param{-log} ) {
    $rv .= $param{-log}."</note>\n";
  } else {
    $rv .= "</note>\n";
  }

  $rv .= '<note type="input" label="output, sequence path">';
  if( exists $param{-seq} ) {
    $rv .= $param{-seq}."</note>\n";
  } else {
    $rv .= "</note>\n";
  }

  $rv .= '<note type="input" label="list path, taxonomy information">';
  $rv .= $param{-taxonomy}."</note>\n";

  $rv .= '<note type="input" label="protein, taxon">';
  $rv .= $param{-db_name}."</note>\n";
 
  $rv .= '<note type="input" label="spectrum, parent monoisotopic mass error minus">2.0</note>
<note type="input" label="spectrum, parent monoisotopic mass error plus">4.0</note>
<note type="input" label="spectrum, parent monoisotopic mass error units">Daltons</note>
<note type="input" label="spectrum, parent monoisotopic mass isotope error">no</note>

	
<note type="input" label="residue, modification mass">57.021464@C</note>

<note type="input" label="protein, cleavage semi">yes</note>
<note type="input" label="scoring, maximum missed cleavage sites">2</note>
</bioml>';

  return $rv;
}
