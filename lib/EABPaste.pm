package EABPaste;

use 5.010;
use strict;
use warnings;
use threads;

use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::IRCNotice;

our $VERSION = '0.1';

if ($ENV{DATABASE_URL}) {
  warning "Database URL: $ENV{DATABASE_URL}";

  my ($scheme, $user, $pass, $host, $port, $path) =
    ($ENV{DATABASE_URL} =~ m|^(\w+)://(.+?):(.+?)@(.+?):(\d+?)/(\w+)$|);

  my $driver = '';
  if ($scheme eq 'postgres') {
    $driver = 'Pg';
  }

  config->{plugins}{Database} = {
    driver   => $driver,
    database => $path,
    host     => $host,
    port     => $port,
    username => $user,
    password => $pass,
  };
}

get '/' => sub {
  template 'index';
};

my @chars = split //, 'abcdefghijklmnopqrstuvwxyz0123456789';
post '/' => sub {
  my $token = join '', map $chars[ int rand @chars ], 1 .. 6;

  my $content;
  if (my $file = upload('file')) {
    $content = $file->content;
  } else {
    $content = param('paste');
  }

  my $title = param('title') || 'untitled';
  my $author = param('author') || 'anonymous';

  database->quick_insert(
    pastes => {
      token   => $token,
      title   => $title,
      author  => $author,
      data    => $content,
      created => time,
    });

  async {
    notify("$title @ http://paste.eatabrick.org/$token ($author)");
  }->detach();

  redirect "/$token", 303;
};

get '/search' => sub {
  my $query = param('q');

  my @pastes = database->quick_select(
    pastes => {
      title => { like => "%$query%" },
    }, {
      order_by => { desc => 'created' },
      limit    => 25,
    });

  template 'list', { pastes => \@pastes, title => 'search results' };
};

get '/rss' => sub {
  content_type 'text/xml';
  my @pastes = database->quick_select(
    pastes => {}, {
      order_by => { desc => 'created' },
      limit    => 25,
    });
  template 'rss', { pastes => \@pastes }, { layout => undef };
};

# should be /recent but that conflicts with a possible token
get '/hist' => sub {
  my @pastes = database->quick_select(
    pastes => {}, {
      order_by => { desc => 'created' },
      limit    => 25,
    });
  template 'list', { pastes => \@pastes, title => 'recent pastes' };
};

get '/by/:author' => sub {
  my @pastes = database->quick_select(
    pastes => { author => param('author') },
    { order_by => { desc => 'created' } },
  );

  if (@pastes) {
    template 'list', {
      pastes => \@pastes,
      title  => 'pastes by ' . param('author'),
      };
  } else {
    status 'not_found';
    template '404';
  }
};

get '/:token.txt' => sub {
  if (my $paste = database->quick_select(pastes => { token => param('token') }))
  {
    content_type 'text/plain';
    return $paste->{data};
  } else {
    status 'not_found';
    template '404';
  }
};

get '/:token' => sub {
  if (my $paste = database->quick_select(pastes => { token => param('token') }))
  {
    template 'view', $paste;
  } else {
    status 'not_found';
    template '404';
  }
};

any qr{.*} => sub {
  status 'not_found';
  template '404';
};

1;
