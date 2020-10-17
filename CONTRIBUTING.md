## Contributing

1. Familiarize yourself with the codebase
1. Create a new issue before starting your project so that we can keep track of
   what you are trying to add/fix.
1. Fork this repository.
1. Edit the code in your fork.
1. Send us a pull request when you are done. We'll review your code, suggest any
   needed changes, and merge it in.

## Branches

- We work in `develop`.
  - Every push on `develop` will create a new package version
- We release from `master`.
- Our work happens in _topic_ branches (feature and/or bug-fix).
  - feature as well as bug-fix branches are based on `develop`


### Merging `develop` into `master`

- When a development cycle finishes, the content of the `develop` is merged into `master` branch.
- The latest package version is then promoted to `released`