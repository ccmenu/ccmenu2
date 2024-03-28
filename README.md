# CCMenu 2

![Build Status](https://github.com/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/badge.svg?branch=main)

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

### Version 23 (CCMenu2 pre-release 4)

- [X] Store GitHub tokens in Keychain
- [X] Basic auth login for CCTray feeds
- [X] GitHub API rate limit handling

### Version 24 (CCMenu2 pre-release 5)

- [X] Optimised CCTray reader requests
- [X] Edit pipelines
- [X] Remaining menu appearance options
- [X] Reduced polling frequency on low data connections

### Pre-release 6 (planned)

- [ ] Import and export of pipeline config
- [ ] Set user/password for CCTray pipelines
- [X] Refresh GitHub token
- [X] Allow selection of branch on GitHub

### To consider 

- [ ] Sounds
- [ ] Support for workflow-specific GitHub tokens
- [ ] Improve accessibility
- [ ] Add support for localisation
- [ ] Show avatar in notifications (committer or repo owner)
- [ ] Support for log in with GitHub (is this even possible?)
- [ ] Support for GitHub apps
- [ ] Pipeline groups with submenus 
- [ ] Add Nevergreen-style dashboard (full screen window)
- [ ] Embed libjq to transform feeds from other CI servers
