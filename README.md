# CCMenu 2

This is a complete rewrite of [CCMenu](https://github.com/erikdoe/ccmenu).

There will be a number of pre-releases via GitHub before it reaches the AppStore.

Significant known issues are filed as bugs.

For now the roadmap is tracked in this readme file.


## Roadmap

### Version 20 (CCMenu2 pre-release 1)

- [X] Monitor hard-coded pipelines
- [X] Read legacy config
- [X] Support for GitHub Actions workflows
- [X] Add pipelines 
- [X] Persistent sorting of pipelines
- [X] Sign in at GitHub

### Version 21 (CCMenu2 pre-release 2)

- [X] GitHub repository and workflow selection
- [X] Caching of last-used authentication token

### Version 22 (CCMenu2 pre-release 3)

- [X] Notifications
- [X] Build timer updates every second
- [X] Discover project names for CCTray feeds

### Pre-release 4 (planned)

- [X] Store GitHub tokens in Keychain
- [X] Basic auth login for CCTray feeds

### Pre-release 5 (planned)

- [ ] Optimised CCTray reader requests
- [ ] Edit pipelines
- [ ] Remaining menu appearance options

### Later

- [ ] Sounds
- [ ] Import and export of pipeline config

### To consider

- [ ] Improve accessibility
- [ ] Add support for localisation
- [ ] Show avatar in notifications (committer or repo owner)
- [ ] Pipeline groups with submenus 
- [ ] Reduced polling frequency on low data connections
- [ ] Add Nevergreen-style dashboard (full screen window)
- [ ] Embed libjq to transform feeds from other CI servers
