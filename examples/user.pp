ipmi::user { 'ADMIN':
  ensure   => present,
  id       => 4,
  password => 'password',
}
