import Foundation

public enum ContentIssue: Error, Equatable, CustomStringConvertible, Sendable {
    case duplicateCourseID(String)
    case missingCourseObjective(courseID: String, objectiveID: String)
    case objectiveInMultipleCourses(String)
    case duplicateLessonMaterial(String)
    case missingLessonMaterial(String)
    case orphanLessonMaterial(String)
    case invalidYouTubeID(objectiveID: String)
    case duplicateObjectiveID(String)
    case duplicateQuestionID(String)
    case missingObjective(questionID: String, objectiveID: String)
    case invalidPrerequisite(objectiveID: String, prerequisiteID: String)
    case prerequisiteCycle([String])
    case emptyField(itemID: String, field: String)
    case duplicateChoiceID(questionID: String, choiceID: String)
    case invalidCorrectChoice(questionID: String)
    case tooFewChoices(questionID: String)
    case invalidContentVersion(questionID: String)

    public var description: String {
        switch self {
        case let .duplicateCourseID(id): "Duplicate course identifier: \(id)"
        case let .missingCourseObjective(courseID, objectiveID): "Course \(courseID) references missing objective \(objectiveID)"
        case let .objectiveInMultipleCourses(id): "Objective \(id) belongs to more than one course"
        case let .duplicateLessonMaterial(id): "Duplicate lesson material for objective \(id)"
        case let .missingLessonMaterial(id): "Missing lesson material for objective \(id)"
        case let .orphanLessonMaterial(id): "Lesson material references missing objective \(id)"
        case let .invalidYouTubeID(id): "Lesson \(id) has an invalid YouTube video identifier"
        case let .duplicateObjectiveID(id): "Duplicate objective identifier: \(id)"
        case let .duplicateQuestionID(id): "Duplicate question identifier: \(id)"
        case let .missingObjective(questionID, objectiveID): "Question \(questionID) references missing objective \(objectiveID)"
        case let .invalidPrerequisite(objectiveID, prerequisiteID): "Objective \(objectiveID) references missing prerequisite \(prerequisiteID)"
        case let .prerequisiteCycle(ids): "Prerequisite cycle: \(ids.joined(separator: " → "))"
        case let .emptyField(itemID, field): "\(itemID) has an empty \(field)"
        case let .duplicateChoiceID(questionID, choiceID): "Question \(questionID) has duplicate choice \(choiceID)"
        case let .invalidCorrectChoice(questionID): "Question \(questionID) has no matching correct choice"
        case let .tooFewChoices(questionID): "Question \(questionID) has fewer than two choices"
        case let .invalidContentVersion(questionID): "Question \(questionID) has an invalid content version"
        }
    }
}

public enum ContentValidator {
    public static func validate(_ content: LearningContent) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        let objectiveIDs = content.objectives.map(\.id)
        let objectiveSet = Set(objectiveIDs)
        for id in duplicates(in: content.courses.map(\.id)) { issues.append(.duplicateCourseID(id)) }
        var courseObjectiveIDs: [String] = []
        for course in content.courses {
            if course.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: course.id, field: "title")) }
            for objectiveID in course.objectiveIDs {
                courseObjectiveIDs.append(objectiveID)
                if !objectiveSet.contains(objectiveID) { issues.append(.missingCourseObjective(courseID: course.id, objectiveID: objectiveID)) }
            }
        }
        for id in duplicates(in: courseObjectiveIDs) { issues.append(.objectiveInMultipleCourses(id)) }
        let materialIDs = content.lessonMaterials.map(\.objectiveID)
        for id in duplicates(in: materialIDs) { issues.append(.duplicateLessonMaterial(id)) }
        for id in Set(courseObjectiveIDs).subtracting(materialIDs).sorted() { issues.append(.missingLessonMaterial(id)) }
        for material in content.lessonMaterials {
            if !objectiveSet.contains(material.objectiveID) { issues.append(.orphanLessonMaterial(material.objectiveID)) }
            if let video = material.video, video.youtubeID.range(of: #"^[A-Za-z0-9_-]{11}$"#, options: .regularExpression) == nil {
                issues.append(.invalidYouTubeID(objectiveID: material.objectiveID))
            }
            if material.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: material.objectiveID, field: "lesson overview")) }
            if material.notes.isEmpty { issues.append(.emptyField(itemID: material.objectiveID, field: "lesson notes")) }
        }
        for id in duplicates(in: objectiveIDs) { issues.append(.duplicateObjectiveID(id)) }
        for objective in content.objectives {
            if objective.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: objective.id, field: "title")) }
            if objective.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: objective.id, field: "summary")) }
            for prerequisite in objective.prerequisiteIDs where !objectiveSet.contains(prerequisite) {
                issues.append(.invalidPrerequisite(objectiveID: objective.id, prerequisiteID: prerequisite))
            }
        }
        if let cycle = findCycle(in: content.objectives) { issues.append(.prerequisiteCycle(cycle)) }

        let questionIDs = content.questions.map(\.id)
        for id in duplicates(in: questionIDs) { issues.append(.duplicateQuestionID(id)) }
        for question in content.questions {
            if !objectiveSet.contains(question.objectiveID) { issues.append(.missingObjective(questionID: question.id, objectiveID: question.objectiveID)) }
            if question.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: question.id, field: "prompt")) }
            if question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyField(itemID: question.id, field: "explanation")) }
            if question.choices.count < 2 { issues.append(.tooFewChoices(questionID: question.id)) }
            for id in duplicates(in: question.choices.map(\.id)) { issues.append(.duplicateChoiceID(questionID: question.id, choiceID: id)) }
            if !question.choices.contains(where: { $0.id == question.correctChoiceID }) { issues.append(.invalidCorrectChoice(questionID: question.id)) }
            if question.contentVersion < 1 { issues.append(.invalidContentVersion(questionID: question.id)) }
        }
        return issues
    }

    private static func duplicates(in values: [String]) -> [String] {
        var seen = Set<String>(); var duplicates = Set<String>()
        for value in values where !seen.insert(value).inserted { duplicates.insert(value) }
        return duplicates.sorted()
    }

    private static func findCycle(in objectives: [LearningObjective]) -> [String]? {
        let graph = Dictionary(uniqueKeysWithValues: objectives.map { ($0.id, $0.prerequisiteIDs) })
        var visiting = Set<String>(); var visited = Set<String>(); var path: [String] = []
        func visit(_ id: String) -> [String]? {
            if let index = path.firstIndex(of: id) { return Array(path[index...]) + [id] }
            if visited.contains(id) { return nil }
            visiting.insert(id); path.append(id)
            for dependency in graph[id, default: []] where graph[dependency] != nil {
                if let cycle = visit(dependency) { return cycle }
            }
            _ = path.popLast(); visiting.remove(id); visited.insert(id)
            return nil
        }
        for id in graph.keys.sorted() where !visited.contains(id) {
            if let cycle = visit(id) { return cycle }
        }
        return nil
    }
}
