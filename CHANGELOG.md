# Changelog

All notable changes after forking will be documented in this file.

## Release 3.0.0

**Features**
- Apply user specified in Foreman BMC interface
- Purge (disable) unspecified `users`
- `ensure => disabled` to disable users
- `ensure => absent` to remove packages

**Internal**
- Converted to PDK
- Allow `stdlib` up to version < 7.0.0

**Limitations**
- Simplifying by restricting to channel 1 only
