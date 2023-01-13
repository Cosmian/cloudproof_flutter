# Changelog

All notable changes to this project will be documented in this file.

## [4.0.1] - 2023-01-13

### Features

- Add wrapping functions for callbacks in `Findex` to help simplify implementation of callbacks
- Add `insecureFetchChainsBatchSize` argument to `Findex.search` to reduce the number of `fetchChains` calls during searches

### Miscellaneous Tasks

- Merge tag 'v4.0.0' into develop

### Testing

- Check non regression on existing SQLite db
- Rework upsertEntries

### Ci

- Rename sqlite filename

## [4.0.0] - 2022-12-20

### Features

- Support findex v1.0.1

### Miscellaneous Tasks

- Merge tag 'v3.1.0' into develop
- Update findex native libraries to 1.0.1

## [3.1.0] - 2022-12-20

### Features

- Add policy class for cover_crypt

### Miscellaneous Tasks

- Merge tag 'v3.0.1' into develop
- Update version

### Refactor

- Rename IndexRow to UidAndValue to align with another languages
- Rename Word to Keywords

### Testing

- Add public doc test

### Ci

- No interaction when autopublish

---

## [3.0.1] - 2022-12-14

### Changed

- fix package installation

---

## [3.0.0] - 2022-12-12

### Added

- add FFI call for cover_crypt encryption
- test vectors verification on cover_crypt

### Changed

- update to cover_crypt 8.0.0 and findex 0.12.0
- decrypt with authentication data

### Fixed

### Removed

---

## [2.0.0] - 2022-11-17

### Added

### Changed

- update to cover_crypt 7.1.0 and findex 0.10.0

### Fixed

### Removed

---

## [1.0.1] - 2022-10-26

### Added

### Changed

### Fixed

- `count` function of SQLite test

### Removed

---

## [1.0.0] - 2022-10-12

### Added

### Changed

- Create first major semver version

### Fixed

### Removed

---

## [0.1.0] - 2022-10-10

### Added

### Changed

- Update Android libs, iOS, MacOS and Windows

### Fixed

### Removed

## [0.0.1] - 2022-10-03

### CoverCrypt

- Decryption with `CoverCryptDecryption`
- Decryption with `CoverCryptDecryptionWithCache`

### Findex

- Search
- Upsert
