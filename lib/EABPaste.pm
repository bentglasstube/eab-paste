package EABPaste;

use 5.010;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';

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

  database->quick_insert(
    pastes => {
      token   => $token,
      title   => param('title') || 'untitled',
      author  => param('author') || 'anonymous',
      data    => $content,
      created => time,
    });

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
