### Building an Image

```bash
./build.sh --help                                   # See usage options
./build.sh --set-ver <version>                      # Build images
./build.sh --set-ver <version> --file <Dockerfile>  # Build images without .env file
```

For a given `--set-ver <version>`, `build.sh` looks for `versions/<version>.env`. If it exists, variables are read from it:

- `BUILD_ARG_<NAME>="value"` — forwarded to `podman build` as `--build-arg <NAME>=value` (the `BUILD_ARG_` prefix is stripped). If the file declares none, zero build-args are passed and the Dockerfile's baked-in `ARG` defaults stay in effect.
- Any other `<NAME>="value"` — used by `build.sh` itself and never forwarded. The `DOCKERFILE` field is one of these; it selects which Dockerfile to build.

If no `versions/<version>.env` exists, `build.sh` requires `--file <path>` to point at the Dockerfile to build, and builds it with no build-args.
The resulting image tag is `BUILD_ARG_OMADA_VER` from the env file if set, otherwise the value passed to `--set-ver`.

Note: v5.x builds use the `.deb` package, which starts the controller during installation and requires capabilities. `build.sh` adds `--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE` automatically when the tag starts with `5.`, so you do not need to pass caps manually. v6.x uses the `.tar.gz` package and needs none.
