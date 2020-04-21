# Changelog

All notable changes after forking will be documented in this file.

## Release 3.0.0

**Features**
- Can apply user specified in Foreman BMC interface
- Can purge unspecified `users`
- Allow `ensure => absent` to remove `ipmi`

**Internal**
- Converted to PDK
- Allow `stdlib` up to version < 7.0.0

**Limitations**
- Simplifying by restricting to channel 1 only
