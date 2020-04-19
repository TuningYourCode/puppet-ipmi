ipmi::user { 'test':
  ensure   => present,
  username => 'test',
  password => 'password',
  id       => 4,
}
