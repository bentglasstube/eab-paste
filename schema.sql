create table if not exists pastes (
  token   text    not null primary key,
  title   text    not null,
  author  text    not null,
  data    text    not null,
  created integer not null
);

create index if not exists created_desc on pastes (
  created desc
);
