# usql-static
Statically linked [usql] for a variety of architectures and applications.

## Usage
Pre-built binaries are in `builds/` and can be used directly, just put them in your PATH.

To build binaries use `build.sh`, which takes (optional) arguments in the form:

```
./build.sh <version>-<build>-<arch>
```

`<version>` can be `latest` (default) or a version number, `<build>` defaults to `base` if omitted and all possible architectures will be built if `<arch>` is not specified.

A custom build not already defined in the build script can be added at the top of `build.conf`.

### Builds
Builds are named: `usql<version>-<build>-<arch>`

#### \<build>
`all`, `base` and `most` are [defined by usql][usql#building]. Other builds are typically named for the drivers they include or the software they're built for (i.e. they include all the database drivers the application can use).

* ``all``				- 'all' drivers
* ``base``			- 'base' drivers (Microsoft SQL, MySQL, PostgreSQL, SQLite3)
* ``most``			- 'most' drivers
* ``mysql``			- MySQL
* ``mypost``		- MySQL, PostgreSQL
* ``openxpki``	- MySQL, ODBC, Oracle, PostgreSQL
* ``postgres``	- PostgreSQL
* ``sqlite3``		- SQLite3

A more detailed description of each build and the drivers they include can be found in [`build_info.txt`](build_info.txt).

**Note:** Not all database drivers build on all platforms, so the `<build>` tag won't be 100% reliable in all cases. See [below](#known-issues) for more details.

#### \<arch>
Valid architectures we can build for are: `amd64`, `arm64v8`, `armv6`, `armv7`, `i386`, and `ppc64le`.

The `armv6` and `armv7` binaries are both hard float/`armhf` builds:

* ``armv6``		- Tag_FP_arch: VFPv2
* ``armv7``		- Tag_FP_arch: VFPv3-D16

The build system doesn't easily allow for an ARMv5 Alpine build if there's no suitable image in the upstream repos it uses and I've not yet found the motivation to look into why I can't trick the compiler with `GOARM=5` or some similar thing.

### Docker Containers
Binaries are also available via Docker images, containing nothing but the executable in the root directory, from [Docker Hub][dockerhub]. These are intended for use as part of multi-stage Docker builds and *will not run on their own*.

The Docker images are tagged as `moonbuggy2000/usql-static:<version>-<build>-<arch>`, similarly to the binaries.

## Known Issues
The exact driver exclusion settings can be seen in the `BUILD_ARCH_EXCLUDE_DRIVERS` array declared at the top of `build.conf`. Some general notes:

* `moderncsqlite`		- won't build for `ppc64le`
* `netezza`					- won't build for 32-bit systems
* `adodb`/`oleodbc`	- no `variant_arm64.go` file, but we build `arm64` by copying `varant_amd64.go` and assuming (with no real basis) that this is a sensible thing to do
* `snowflake`				- this will throw an error in builds that include it unless a `~/.cache/snowflake/ocsp_response_cache.json` file exists

The build system is theoretically capable of building for `s390x` as well, but in practice the builds hang indefinitely and give no indication as to why. I've not had the time or inclination to investigate.

## Links
GitHub: https://github.com/moonbuggy/usql-static

Docker Hub: https://hub.docker.com/r/moonbuggy2000/usql-static

[usql]: https://github.com/xo/usql "usql"
[usql#building]: https://github.com/xo/usql#building "usql#building"
[dockerhub]: https://hub.docker.com/r/moonbuggy2000/usql-static "moonbuggy2000/usql-static"
