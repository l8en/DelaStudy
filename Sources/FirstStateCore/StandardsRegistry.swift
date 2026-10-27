import Foundation

public enum CoverageStatus: String, Sendable {
    case related = "Related topic"
    case partial = "Partially addresses"
    case addressed = "Addresses this requirement within the module"
}
public struct StandardsMapping: Identifiable, Sendable {
    public let id: String
    public let body: String
    public let framework: String
    public let subject: String
    public let gradeBand: String
    public let edition: String
    public let sourceURL: URL
    public let adoptionURL: URL
    public let summary: String
    public let objectiveIDs: [String]
    public let questionIDs: [String]
    public let rationale: String
    public let status: CoverageStatus
    public let reviewedOn: String
    public let reviewStatus: String
}
public enum StandardsRegistry {
    public static let mappings: [StandardsMapping] = [
        .init(id:"CCSS.ELA-Literacy.RI.11-12.1",body:"Common Core State Standards Initiative",framework:"Delaware ELA / CCSS",subject:"English language arts",gradeBand:"11–12",edition:"CCSS ELA 2010; current DDOE reference checked 2026-10-19",sourceURL:URL(string:"https://www.thecorestandards.org/ELA-Literacy/RI/11-12/")!,adoptionURL:URL(string:"https://education.delaware.gov/educators/academic-support/standards-and-assessments/english-and-language-arts/")!,summary:"Support an interpretation with textual evidence and identify what remains uncertain.",objectiveIDs:["prep-english-language-and-composition-evidence"],questionIDs:["prep-english-language-and-composition-evidence-q3","prep-english-language-and-composition-evidence-q4"],rationale:"Students connect two specific choices in an original passage to an analytical claim and identify a premise needing verification. The short passage and self-review do not establish grade-band text complexity or independent performance across diverse texts, so the mapping is partial. Written activity: the lesson’s Apply & explain response and four-criterion rubric.",status:.partial,reviewedOn:"2026-10-19",reviewStatus:"Content author check; not educator reviewed"),
        .init(id:"CCSS.ELA-Literacy.RI.11-12.6",body:"Common Core State Standards Initiative",framework:"Delaware ELA / CCSS",subject:"English language arts",gradeBand:"11–12",edition:"CCSS ELA 2010; current DDOE reference checked 2026-10-19",sourceURL:URL(string:"https://www.thecorestandards.org/ELA-Literacy/RI/11-12/")!,adoptionURL:URL(string:"https://education.delaware.gov/educators/academic-support/standards-and-assessments/english-and-language-arts/")!,summary:"Analyze how a writer’s choices serve purpose and rhetorical effect.",objectiveIDs:["prep-english-language-and-composition-evidence"],questionIDs:["prep-english-language-and-composition-evidence-q1","prep-english-language-and-composition-evidence-q2"],rationale:"The written response analyzes a bounded trial and conditional review in relation to a school board audience. Students explain function, not just identify devices. The module does not assess the full range of style, beauty, and complex literary nonfiction expected by the standard; coverage is partial. Activity evidence is the saved analytical paragraph and rubric self-review.",status:.partial,reviewedOn:"2026-10-19",reviewStatus:"Content author check; not educator reviewed"),
        .init(id:"HSA-REI.B.3",body:"Common Core State Standards Initiative",framework:"Delaware Mathematics / CCSS",subject:"Mathematics",gradeBand:"High school algebra",edition:"CCSS Mathematics, 2010; current DDOE reference checked 2026-10-19",sourceURL:URL(string:"https://www.thecorestandards.org/Math/Content/HSA/REI/")!,adoptionURL:URL(string:"https://education.delaware.gov/educators/academic-support/standards-and-assessments/mathematics/de-math-standards/")!,summary:"Solve linear equations and inequalities in one variable, including literal coefficients.",objectiveIDs:["algebra-equations"],questionIDs:["algebra-solve","algebra-balance"],rationale:"Students preserve equality while solving numerical linear equations and identify equivalent operations. Inequalities and literal coefficients are not assessed in this module; coverage is partial.",status:.partial,reviewedOn:"2026-10-19",reviewStatus:"Content author check; not educator reviewed"),
        .init(id:"HS-LS1-3",body:"NGSS Lead States",framework:"Delaware Science / NGSS",subject:"Science",gradeBand:"9–12",edition:"NGSS 2013; evidence statements June 2015",sourceURL:URL(string:"https://www.nextgenscience.org/pe/hs-ls1-3-molecules-organisms-structures-and-processes")!,adoptionURL:URL(string:"https://education.delaware.gov/?page_id=18677")!,summary:"Investigate how feedback mechanisms maintain homeostasis.",objectiveIDs:["biology-membranes"],questionIDs:["biology-osmosis","biology-diffusion"],rationale:"The lesson discusses selective transport and stable internal conditions (DCI LS1.A). It does not ask students to plan and conduct a feedback investigation (SEP) or analyze a feedback system across conditions (CCC Stability and Change). This is a related topic, not performance-expectation coverage.",status:.related,reviewedOn:"2026-10-19",reviewStatus:"Content author check; not educator reviewed")
    ]
    public static func mappings(for course: Course) -> [StandardsMapping] { mappings.filter { !Set($0.objectiveIDs).isDisjoint(with:course.objectiveIDs) } }
}
