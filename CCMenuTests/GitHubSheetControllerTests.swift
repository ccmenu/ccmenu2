/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

final class GitHubSheetControllerTests: XCTestCase {

    func testReplacesMessageWithNewMessage() throws {
        let controller = GitHubSheetController(model: PipelineModel(settings: UserSettings()))
        let oldMessage = GitHubRepository(message: "old")
        controller.selectionState.repositoryList = [ oldMessage ]
        let newMessage = GitHubRepository(message: "new")

        controller.updateRepositoryList(newList: [ newMessage ])

        let list = controller.selectionState.repositoryList
        XCTAssertEqual(1, list.count)
        XCTAssertEqual(newMessage, list[0])
    }

    func testReplacesMessageWithFilteredAndSortedList() throws {
        let controller = GitHubSheetController(model: PipelineModel(settings: UserSettings()))
        controller.selectionState.owner = "octocat"
        let oldMessage = GitHubRepository(message: "old")
        controller.selectionState.repositoryList = [ oldMessage ]
        let repo1 = GitHubRepository(id: 1, name: "foo", owner: GitHubOwner(login: "octocat"))
        let repo2 = GitHubRepository(id: 2, name: "bar", owner: GitHubOwner(login: "octocat"))
        let repo3 = GitHubRepository(id: 3, name: "foo", owner: GitHubOwner(login: "ccmenu"))

        controller.updateRepositoryList(newList: [ repo1, repo2, repo3 ])

        let list = controller.selectionState.repositoryList
        XCTAssertEqual(2, list.count)
        XCTAssertEqual(repo2, list[0])
        XCTAssertEqual(repo1, list[1])
    }

    func testreplacesRepositoryListWithNewList() throws {
        let controller = GitHubSheetController(model: PipelineModel(settings: UserSettings()))
        controller.selectionState.owner = "octocat"
        let repo1 = GitHubRepository(id: 1, name: "foo", owner: GitHubOwner(login: "octocat"))
        controller.selectionState.repositoryList = [ repo1 ]
        let repo2 = GitHubRepository(id: 2, name: "bar", owner: GitHubOwner(login: "octocat"))

        controller.updateRepositoryList(newList: [ repo2 ])

        let list = controller.selectionState.repositoryList
        XCTAssertEqual(1, list.count)
        XCTAssertEqual(repo2, list[0])
    }

    func testAddsDefaultRepositoryWhenEmptyListIsAdded() throws {
        let controller = GitHubSheetController(model: PipelineModel(settings: UserSettings()))
        let oldMessage = GitHubRepository(message: "old")
        controller.selectionState.repositoryList = [ oldMessage ]

        controller.updateRepositoryList(newList: [ ] )

        let list = controller.selectionState.repositoryList
        XCTAssertEqual(1, list.count)
        XCTAssertEqual(GitHubRepository(), list[0])
    }

}
