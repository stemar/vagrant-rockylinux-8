# Changelog

## 1.0.2 - 2026-01-15

### Added

- Added `CHANGELOG.md`
- Added `config/adminer-plugins.php`

### Changed

- Updated YAML array format in `settings.yaml`.
    - Added `:id` to all `:forwarded_ports`.
- Updated `Vagrantfile` by adding local variables.
    - Modernized path in the `YAML.load_file()` call.
- Replaced `FORWARDED_PORT_80` variable with `HOST_HTTP_PORT` in 3 files.
    - Updated `provision.sh`, `adminer.conf`, `virtualhost.conf` with new variable name.
- Modified the version section of `provision.sh` for the section title and the Apache version output.
- Updated the last section of `README.md`.
- Updated `config/adminer.php`.

### Fixed

- Updated Adminer to version 5+ plugin code and files.

## 1.0.1 - 2023-01-23

### Changed

- Updated PHP, Ruby, Python.
- Made Ruby install optional.

## 1.0.0 - 2022-05-05

_First release_
