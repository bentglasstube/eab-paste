create table if not exists pastes (
  token   varchar(16)  not null primary key,
  title   varchar(100) not null,
  author  varchar(50)  not null,
  data    text         not null,
  created integer      not null
);

create index created_desc on pastes (
  created desc
);
