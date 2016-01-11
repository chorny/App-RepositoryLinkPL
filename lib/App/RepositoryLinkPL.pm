package App::RepositoryLinkPL;

use 5.012;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental";

use File::Slurp;

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT = our @EXPORT_OK = qw/github_clone rewrite_remote github_fork commit git_push/;
our %builder_file = (qw/DZ dist.ini MB Build.PL MBT Build.PL EUMM Makefile.PL MI Makefile.PL/);

sub process_repo {
  my ($author, $repo)=@_;
  if (!-e $repo) {
    die unless github_clone($author,$repo);
  }
  my $repo_url_web = "http://github.com/$author/$repo";
  my $res = process_current_dir('$repo_url_web');
}

sub process_current_dir {
  my $repo_url_web = shift || die "no repository in call to process_current_dir";

  my $dist_builder = detect_builder('.');
  say "Dist builder: $dist_builder";
  my $process_file = $builder_file{$dist_builder} || die "builder not found";
  my $content = read_file($process_file);
  my $commit_message = 'repository for META.*';
  for ($dist_builder) {
    when ('DZ') {
      if ($content =~ /^\s*\[/s) {
        return ({error => "problem in dist.ini", file => $process_file, builder => $dist_builder});
      }
      if ($content =~ /^\s*repository(?:\.(?:web|url))?\s+=\s+/m || $content=~/^\[(?:\@RJBS|GithubMeta)\]$/m) {
        print "Already present\n";
        return 'already';
      }
      unless ($content =~ s/(\[MetaResources\])/$1\nrepository = $repo_url_web/) {
        $content .= "\n[MetaResources]\nrepository = $repo_url_web\n";
      }
    }
    when ('EUMM') {
      if ($content !~ /(?<!#)['"]?repository/) {
        system("eumm-upgrade --noparent");
        $content = read_file('Makefile.PL');
        if ($content =~ /(?<!#)repository/) {
          $commit_message = 'Upgrade Makefile.PL';
        } else {
          print "repository was not added\n";
          return ({error => "repository was not added - already present", file => $process_file, builder => $dist_builder});
        }
      } else {
        print "repository already present\n";
        return 'already';
      }
    }
    when ('MI') {
      my $mi_version = get_mi_version('.');
      if (!defined $mi_version) {
        #$content =~ /\bname\s+['"]([^"']+)['"];/ or die "cannot find name in Makefile.PL";
        #my $dname = $1;
      }
      if ($content =~ /\bauto_set_repository;|\bgithubmeta/) {
        print "this distribution sets repository information automatically\n";
        return 'already';
      } elsif ($content=~/\brepository[\(\s']/) {
        print "repository already present\n";
        return 'already';
      } else {
        if ($content =~ s/(\&?WriteAll(?:\([^\(\)]*\))?;)/repository '$repo_url_web';\n$1/) {
          my $version=0;
          my $message = "";
          $version=1.10;

          if ($mi_version >= $version) {
            #$message = "";
          }
          unless ($content =~ s/(use inc::Module::Install)((?: 0\.\d+)?);/qq{$1}.' '.update_version(qq{$2},$version).';'.($message?" #$message":'');/e) {
            print "repository was not added\n";
            return ({error => "repository was not added", file => $process_file, builder => $dist_builder});
          }
        } else {
          print "repository was not added: WriteAll not found\n";
          return ({error => "repository was not added: WriteAll not found", file => $process_file, builder => $dist_builder});
        }
      }
    }
    when ('MB') {
      if ($content !~ /(?<!#)['"]?repository/) {
        require Text::FindIndent;
        my $indentation_type = Text::FindIndent->parse($content);
        die "Bad indent: $indentation_type" unless $indentation_type eq 's4' || $indentation_type eq 's2' || $indentation_type eq 't8';

        my $space_to_use;
        if ($indentation_type =~ /^[sm](\d+)/) {
          print "Indentation with $1 spaces\n";
          $space_to_use=$1;
        } elsif ($indentation_type =~ /^t(\d+)/) {
          print "Indentation with tabs, a tab should indent by $1 characters\n";
          $space_to_use=0;
        } else {
          print "Indentation unknown, will use 4 spaces\n";
          $space_to_use=4;
        }

      
        my $replace=<<EOT;
    meta_merge => {
        resources => {
            repository => '$repo_url_web',
        },
    },
EOT
        require App::EUMM::Upgrade;
        $replace = App::EUMM::Upgrade::apply_indent($replace,4,$space_to_use);
        unless ($content =~ s/(Module::Build\s*->\s*new\s*\()/$1\n$replace/) {
          return ({error => "no Module::Build->new", file => $process_file, builder => $dist_builder});
        }
      } else {
        return 'already';
      }
    }
    default {
      die "Unknown builder: $dist_builder";
    }
  }
  write_file($process_file, $content) if $dist_builder ne 'EUMM';
  return ({error => 0, file => $process_file, builder => $dist_builder, commit_message => $commit_message});
}

sub update_version {
  my ($current_version, $new_version)=@_;
  $current_version =~ s/^\s+//s;
  if (!$current_version || $current_version < $new_version) {
    return $new_version;
  } else {
    return $current_version;
  }
}

sub github_clone {
  my ($author, $repo)=@_;
  my $repo_url_ro = "git://github.com/$author/$repo.git";
  print "git clone $repo_url_ro\n";
  system("git clone $repo_url_ro");
  return 1 if -e $repo;
  return 0;
}

sub commit {
  my $message = shift;
  my @files = @_;
  require Git::Class;
  my $work = Git::Class::Worktree->new(path => '.');
  $work->add(@files);
  $work->commit('-m',$message);
}

sub github_fork {
  my ($author, $repo, $new_author, $github_token) = @_;
  require Net::GitHub;
  my $gh = Net::GitHub->new(
      access_token => $github_token,
  );
  $gh->set_default_user_repo($author, $repo);
  my $repos = $gh->repos;
  my $fork = $repos->create_fork || die;
}

sub rewrite_remote {
  my ($author, $repo, $new_author)=@_;
  my $file='.git/config';
  my $gitconfig = read_file($file) || die "no content in '.git/config'";
  my $new_git_url = "git\@github.com:$new_author/$repo.git";
  if ($gitconfig =~ s#\Qurl = git://github.com/\E$author/$repo\.git#url = $new_git_url#) {
    write_file($file,$gitconfig);
  } else {
    die "cannot find old url in rewrite_remote()";
  }
}

sub git_push {
  require Git::Class;
  my $work = Git::Class::Worktree->new(path => '.');
  $work->push;
}

sub detect_builder {
  my $dir = shift;
  if (-e $dir.'/'.'dist.ini') {
    return 'DZ';
  } elsif (-e $dir.'/'.'Build.PL') {
    my $content = read_file($dir.'/'.'Build.PL');
    my $mb = 0;
    my $mbt = 0;
    $mbt = 1 if ($content =~ /(?:use|require) Module::Build::Tiny[ ;]/);
    $mb = 1 if ($content =~ /(?:use|require) (?:Module::Build|Alien::Base::ModuleBuild|Alien::make::Module::Build|Module::Build::Pluggable)[ ;]/);
    if ($mb xor $mbt) {
      return 'MBT' if $mbt;
      return 'MB' if $mb;
    } else {
      return "error";
    }
  } elsif (-e $dir.'/'.'Makefile.PL') {
    my $content = read_file($dir.'/'.'Makefile.PL');
    my $mi = 0;
    my $eumm = 0;
    $mi = 1 if ($content =~ /(?:use|require) inc::Module::Install(?:\Q::DSL\E)?[ ;]/);
    $eumm = 1 if ($content =~ /(?:use|require) (?:ExtUtils::MakeMaker|Inline::MakeMaker)[ ;]/);
    if ($mi xor $eumm) {
      return 'MI' if $mi;
      return 'EUMM' if $eumm;
    } else {
      return "error";
    }
  } else {
    return "error";
  }

}

sub get_mi_version {
  my $dir = shift;
  return undef unless -e $dir.'/inc/Module/Install.pm';
  return _get_module_version($dir.'/inc/Module/Install.pm');
}

sub _get_module_version {
  my $module = shift;
  require Module::Metadata;

  my $info = Module::Metadata->new_from_file($module, collect_pod => 0);
  if (defined $info) {
    return $info->version;
  } else {
    return undef;
  }
}

1; # End of App::RepositoryLinkPL

__END__

=head1 NAME

App::RepositoryLinkPL - companion module for repositorylink-pl program

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

repositorylink-pl is a program to add repository link to Makefile.PL/Build.PL,
so it will be published via META.*.
It can clone repository from github, add link, do fork and pull
request or just add link to distribution in current directory
independently from repository type/location.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-RepositoryLinkPL>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::RepositoryLinkPL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-RepositoryLinkPL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-RepositoryLinkPL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-RepositoryLinkPL>

=item * Search CPAN

L<http://search.cpan.org/dist/App-RepositoryLinkPL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Alexandr Ciornii.

This program is released under the following license: GPL3


=cut
