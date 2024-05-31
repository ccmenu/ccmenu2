# Contributing to CCMenu

First off, thank you for taking the time to contribute to CCMenu!

The following is a set of guidelines for contributing to CCMenu. These are just guidelines, not rules. Use your best judgment and feel free to propose changes to this document in a pull request.

This project adheres to the [Contributor Covenant 2.0](https://github.com/ccmenu/ccmenu2/blob/main/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.


## Submitting issues

* If you have encountered an issue or you want to suggest an enhancement, have a look at the [existing issues](https://github.com/ccmenu/ccmenu2/issues?q=is%3Aissue) to see if a similar one has already been submitted.

* When you submit an issue, please provide as much information as possible. The easier it is to understand and reproduce the problem, the more likely it is that we can provide a fix.

* Include the version of CCMenu you are using, especially if you didn't download it from the App Store.


## Pull requests

* Create all pull requests from the `main` branch. Do not include other pull requests that have not been merged yet.

* Limit each pull request to one feature. If you have made several changes, please submit multiple pull requests. Do not include seemingly trival changes, e.g. upgrading the Xcode version, in a pull request for a feature or bugfix.

* If you add a new feature, provide corresponding tests. If you have to remove an existing test because it fails in the presence of newly introduced code, please explain the rationale in the pull request.

* After you have created the pull request, please wait for the automated build to run. This no longer happens automatically – a mainatainer has to approve the run. Normally, this should happen within a day or two. Please verify that the build was successful on the [actions page](https://github.com/ccmenu/ccmenu2/actions/workflows/build-and-test.yaml). **Pull requests with failing builds are ignored and will be closed within a few weeks if they are not fixed.**
