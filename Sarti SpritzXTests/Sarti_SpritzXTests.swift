//
//  Sarti_SpritzXTests.swift
//  Sarti SpritzXTests
//
//  Created by Tobias Thiele on 12.09.26.
//

import XCTest
@testable import Sarti_SpritzX

final class Sarti_SpritzXTests: XCTestCase {
    func testVocabularyImportIsCompleteAndHasUniqueIDs() {
        XCTAssertEqual(ItalianContent.vocabulary.count, 269)
        XCTAssertEqual(Set(ItalianContent.vocabulary.map(\.id)).count, 269)
    }

    func testLessonsContainAllImportedPhrases() {
        XCTAssertEqual(ItalianContent.lessons.count, 5)
        XCTAssertEqual(ItalianContent.lessons.flatMap(\.phrases).count, 70)
    }

    func testGeneratedQuizHasOneUniqueCorrectOption() {
        let questions = ItalianContent.makeQuiz(limit: 30)

        XCTAssertEqual(questions.count, 30)
        for question in questions {
            XCTAssertTrue(question.answers.contains(question.correctAnswer))
            XCTAssertEqual(question.answers.filter { $0 == question.correctAnswer }.count, 1)
            XCTAssertEqual(Set(question.answers).count, question.answers.count)
        }
    }
}
