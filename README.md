![Build Status](https://github.com/ccmenu/ccmenu2/actions/workflows/build-and-test.yaml/badge.svg?branch=main)

# CCMenu

CCMenu shows the status of builds on CI/CD servers in the menu bar.

This repository holds the new version of CCMenu, rewritten from the ground up using Swift and Swift UI.

Please visit [ccmenu.org](https://ccmenu.org) for a detailed description of CCMenu.


## Downloads

The recommended download is [CCMenu on the App Store](https://apps.apple.com/de/app/ccmenu/id603117688).

You can also download all versions of CCMenu from the respective GitHub release. Please bear in mind, though, that CCMenu doesn't have an update check built in, and relies on the App Store for that.

All releases based on the code in this repository are available from the [release list of this repository](https://github.com/ccmenu/ccmenu2/releases). The "classic" versions of CCMenu (versions below 20) are available from the [release list of the original repository](https://github.com/ccmenu/ccmenu/releases). 


## Bugs / Contributing / Help

You can ask for help or contribute to the future development of CCMenu by discussing or suggesting features in the GitHub [discussions](https://github.com/ccmenu/ccmenu2/discussions).

If you suspect that you have found a bug, please open an [issue](https://github.com/ccmenu/ccmenu2/issues). For now there's no template, but please try to include as much information as possible. The easier it is to reproduce the bug, the more likely it is to be fixed.

Pull requests that fix known bugs are welcome. Please try to add a unit test that demonstrates that the bug was fixed. Of course, you can also open a PR with a new feature, but please keep in mind that adding new features will likely need some discussion. In either case, any PR must pass the existing tests, including the UI tests, which are in a separate build target. 

If you are interested in a new feature but you don't know Swift *DON'T* implement the feature through extensive use of an AI coding assistant. Write a feature request instead.


## Feature ideas

Below are some ideas for future features. There's no roadmap for their implementation, and some are probably never going to be implemented. 

- Sounds (was a feature in the classic CCMenu)
- Workflow-specific GitHub tokens
- Support for updating passwords of cctray pipelines
- Improved accessibility
- Support for localisation / localisation
- Avatar in notifications (committer or repo owner)
- Support for log in with GitHub (is this even possible?)
- GitHub API access as a GitHub app (currently CCMenu uses OAuth)
- Pipeline groups with submenus 
- [Nevergreen](https://github.com/build-canaries/nevergreen)-style dashboard (full screen window)
- Embedded libjq to transform feeds from other CI servers

Please start a [discussion](https://github.com/ccmenu/ccmenu2/discussions) or open an issue to let us know what features you'd like to see in CCMenu.

Join the [discussion on servers](https://github.com/ccmenu/ccmenu2/discussions/10) to add your voice on which server types should be supported.
