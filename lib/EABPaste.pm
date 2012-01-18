package EABPaste;
use Dancer ':syntax';

our $VERSION = '0.1';

my @data = ();
my %data = ();

get '/' => sub {
  template 'index';
};

my @chars = split //, 'abcdefghijklmnopqrstuvwxyz0123456789';
post '/' => sub {
  my $token = join '', map $chars[int(rand(@chars))], 1 .. 6;

  my $entry = {
    title  => params->{title} || 'untitled',
    author => params->{author} || 'anonymous',
    data   => params->{paste},
    token  => $token,
  };

  unshift @data, $entry;
  $data{$token} = $entry;

  if (@data > config->{max_entries}) {
    my $old = pop @data;
    delete $data{$old->{token}};
  }

  template 'view', $entry;
};

get '/rss' => sub {
  content_type 'text/xml';
  template 'rss', { posts => \@data }, { layout => undef };
};

get '/:token' => sub {
  if (my $paste = $data{params->{token}}) {
    template 'view', $paste;
  } else {
    status 'not_found';
    template '404';
  }
};

true;
