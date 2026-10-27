import Foundation
import Testing
@testable import FirstStateCore

@Suite("Focus deadlines and additive workspace persistence")
struct FocusAndWorkspaceTests {
    let start = Date(timeIntervalSince1970:1000)
    @Test func pausedTimeDoesNotCountAsWork() throws {
        var preferences=FocusPreferences(); preferences.workMinutes=25
        var session=FocusSession(task:"Read",preferences:preferences,now:start)
        session.pause(at:start.addingTimeInterval(60))
        #expect(session.remaining(at:start.addingTimeInterval(600)) == 1440)
        session.resume(at:start.addingTimeInterval(600))
        let record=try #require(session.record(at:start.addingTimeInterval(660),completed:false))
        #expect(record.focusedSeconds == 120)
        #expect(record.pauseCount == 1)
        let pause=try #require(record.pauses.first)
        #expect(pause.endedAt?.timeIntervalSince(pause.startedAt) == 540)
    }
    @Test func settlingAfterLongAbsenceRecordsOnlyOneWorkInterval() {
        var session=FocusSession(task:"Read",preferences:FocusPreferences(),now:start)
        let record=session.settle(at:start.addingTimeInterval(7200))
        #expect(record?.focusedSeconds == 1500)
        #expect(record?.completed == true)
        #expect(session.awaitingNextPhase)
        #expect(session.recoveryMessage != nil)
        #expect(session.settle(at:start.addingTimeInterval(7300)) == nil)
        #expect(session.cycle == 1)
    }
    @Test func relaunchKeepsDeadlineAndPauseState() throws {
        var session=FocusSession(task:"Algebra",preferences:FocusPreferences(),now:start)
        let data=try JSONEncoder().encode(session)
        let restored=try JSONDecoder().decode(FocusSession.self,from:data)
        #expect(restored.remaining(at:start.addingTimeInterval(120)) == 1380)
        session.pause(at:start.addingTimeInterval(120))
        let paused=try JSONDecoder().decode(FocusSession.self,from:JSONEncoder().encode(session))
        #expect(paused.remaining(at:start.addingTimeInterval(900)) == 1380)
        #expect(!paused.isRunning)
    }
    @Test func breakTransitionsUseFrozenConfigurationAndNewIdentity() {
        var p=FocusPreferences(); p.workMinutes=1; p.intervalsBeforeLongBreak=2; p.longBreakMinutes=12
        var s=FocusSession(task:"Read",preferences:p,now:start)
        let firstID=s.id
        _=s.settle(at:start.addingTimeInterval(60))
        s.nextPhase(at:start.addingTimeInterval(61))
        #expect(s.phase == .shortBreak)
        #expect(s.id != firstID)
        s.nextPhase(at:start.addingTimeInterval(62),skipBreak:true)
        #expect(s.phase == .work && s.cycle == 2)
        _=s.settle(at:start.addingTimeInterval(122))
        s.nextPhase(at:start.addingTimeInterval(123))
        #expect(s.phase == .longBreak && s.duration == 720)
    }
    @Test func normalNextCannotDiscardAnActiveWorkInterval() {
        var s=FocusSession(task:"Read",preferences:FocusPreferences(),now:start)
        let before=s
        s.nextPhase(at:start.addingTimeInterval(30))
        #expect(s == before)
    }
    @Test func schemaThreeProgressKeepsExistingIdentityAndDefaultsNewWorkspace() throws {
        let json=#"{"schemaVersion":3,"hasCompletedOnboarding":true,"profile":{"displayName":"Avery","dailyGoalMinutes":15,"selectedCourseID":"ap-biology"},"attempts":[],"sessions":[],"communityResponses":{"evidence":"Keep this"},"joinedChallengeIDs":[],"collegeChecklistIDs":["aid"]}"#
        let snapshot=try JSONDecoder().decode(ProgressSnapshot.self,from:Data(json.utf8))
        #expect(snapshot.profile.displayName == "Avery")
        #expect(snapshot.profile.selectedCourseID == "ap-biology")
        #expect(snapshot.communityResponses["evidence"] == "Keep this")
        #expect(snapshot.workspace == LearnerWorkspace())
        #expect(snapshot.workspace.schoolID == nil)
        #expect(!snapshot.workspace.includeSchoolInSummary)
    }
    @Test func workspaceRoundTripKeepsNotesPreferencesAndActiveTimer() throws {
        var snapshot=ProgressSnapshot()
        snapshot.workspace.schoolID=SchoolDirectory.schools.first?.id
        snapshot.workspace.lessonNotes["read-record"]="Private note"
        snapshot.workspace.tasks=[PersonalTask(title:"Review a claim")]
        snapshot.workspace.sound = .pink
        snapshot.workspace.focus=FocusSession(task:"Read",preferences:FocusPreferences(),now:start)
        let restored=try JSONDecoder().decode(ProgressSnapshot.self,from:JSONEncoder().encode(snapshot))
        #expect(restored == snapshot)
    }
    @Test func everyPublishedAPModuleHasInstructionPracticeAndRubric() {
        #expect(APPreparation.modules.count == 10)
        for module in APPreparation.modules {
            let material=APPreparation.content.lesson(for:module.objectiveID)
            #expect(material != nil)
            #expect(material?.notes.count == 4)
            #expect(APPreparation.content.questions(for:module.objectiveID).count == 4)
            #expect(module.rubric.count == 4)
            #expect(!module.coverage.isEmpty)
            #expect(module.frameworkURL.scheme == "https")
        }
    }
    @Test func directoryIDsLocationsAndSourcesAreValidAndSearchTrimsInput() {
        #expect(Set(SchoolDirectory.schools.map(\.id)).count == SchoolDirectory.schools.count)
        #expect(Set(SchoolDirectory.schools.compactMap(\.county)) == Set(["New Castle","Kent","Sussex"]))
        #expect(SchoolDirectory.schools.allSatisfy { $0.sourceURL.scheme == "https" && !$0.grades.isEmpty })
        #expect(SchoolDirectory.schools.contains { $0.matches("  odessa  ") })
        #expect(!SchoolDirectory.schools.contains { $0.matches("zzzz-no-school-zzzz") })
    }
    @Test func crosswalkOnlyLinksExistingWork() {
        for mapping in StandardsRegistry.mappings {
            #expect(mapping.objectiveIDs.allSatisfy { AppContent.content.objective(id:$0) != nil })
            #expect(mapping.questionIDs.allSatisfy { AppContent.content.question(id:$0) != nil })
            #expect(mapping.status != .addressed)
        }
    }
}
