import Foundation

public struct LearningContent: Sendable {
    public let courses: [Course]
    public let objectives: [LearningObjective]
    public let questions: [PracticeQuestion]
    public let lessonMaterials: [LessonMaterial]

    public init(courses: [Course] = [], objectives: [LearningObjective], questions: [PracticeQuestion], lessonMaterials: [LessonMaterial] = []) {
        self.courses = courses
        self.objectives = objectives
        self.questions = questions
        self.lessonMaterials = lessonMaterials
    }

    public func objective(id: String) -> LearningObjective? { objectives.first { $0.id == id } }
    public func course(id: String) -> Course? { courses.first { $0.id == id } }
    public func course(containing objectiveID: String) -> Course? { courses.first { $0.objectiveIDs.contains(objectiveID) } }
    public func objectives(for courseID: String) -> [LearningObjective] {
        guard let course = course(id: courseID) else { return [] }
        return course.objectiveIDs.compactMap(objective).sorted { ($0.order, $0.id) < ($1.order, $1.id) }
    }
    public func question(id: String) -> PracticeQuestion? { questions.first { $0.id == id } }
    public func questions(for objectiveID: String) -> [PracticeQuestion] { questions.filter { $0.objectiveID == objectiveID } }
    public func lesson(for objectiveID: String) -> LessonMaterial? { lessonMaterials.first { $0.objectiveID == objectiveID } }
}

public enum AppContent {
    private static let accessed = Date(timeIntervalSince1970: 1_792_155_600) // 2026-10-16 13:00 UTC; stable provenance metadata

    public static let archiveWorksheet = SourceReference(
        title: "Adoption of the Constitution",
        publisher: "Delaware Public Archives",
        url: URL(string: "https://archivesfiles.delaware.gov/lesson-plans/2025/adoption-of-constitution.pdf")!,
        accessedOn: accessed
    )

    public static let archiveLesson = SourceReference(
        title: "Delaware and the Constitution",
        publisher: "Delaware Public Archives",
        url: URL(string: "https://archivesfiles.delaware.gov/lesson-plans/2025/the-constitution-and-delaware.pdf")!,
        accessedOn: accessed
    )

    public static let algebraText = SourceReference(
        title: "Algebra 1 Scope and Sequence",
        publisher: "Illustrative Mathematics",
        url: URL(string: "https://cms-assets.illustrativemathematics.org/xaczotl0hz2ng7y4arg7g6ikj7rh")!,
        accessedOn: accessed
    )

    public static let biologyText = SourceReference(
        title: "Biology for AP Courses",
        publisher: "OpenStax, Rice University",
        url: URL(string: "https://openstax.org/books/biology-ap-courses/pages/preface")!,
        accessedOn: accessed
    )

    public static let collegeAlgebraText = SourceReference(
        title: "College Algebra 2e",
        publisher: "OpenStax, Rice University",
        url: URL(string: "https://openstax.org/books/college-algebra-2e/pages/preface")!,
        accessedOn: accessed
    )

    public static let collegeBiologyText = SourceReference(
        title: "Biology 2e",
        publisher: "OpenStax, Rice University",
        url: URL(string: "https://openstax.org/books/biology-2e/pages/preface")!,
        accessedOn: accessed
    )

    public static let content: LearningContent = {
        let objectives = [
            LearningObjective(id: "read-record", title: "Read the record", summary: "Separate details stated in the document from later context.", order: 0, prerequisiteIDs: [], source: archiveWorksheet),
            LearningObjective(id: "purpose-perspective", title: "Purpose & perspective", summary: "Identify who is speaking, to whom, and what they want.", order: 1, prerequisiteIDs: ["read-record"], source: archiveWorksheet),
            LearningObjective(id: "trace-process", title: "Trace civic process", summary: "Follow how a petition can seek action through representative government.", order: 2, prerequisiteIDs: ["purpose-perspective"], source: archiveLesson),
            LearningObjective(id: "weigh-evidence", title: "Weigh the evidence", summary: "Decide what one primary source can—and cannot—prove.", order: 3, prerequisiteIDs: ["trace-process"], source: archiveLesson),
            LearningObjective(id: "algebra-equations", title: "Solve linear equations", summary: "Use inverse operations while preserving equality.", order: 0, prerequisiteIDs: [], source: algebraText),
            LearningObjective(id: "algebra-graphs", title: "Graph linear relationships", summary: "Connect ordered pairs, slope, intercepts, and equations.", order: 1, prerequisiteIDs: ["algebra-equations"], source: algebraText),
            LearningObjective(id: "biology-cells", title: "Compare cell types", summary: "Identify shared structures and distinguish prokaryotic and eukaryotic cells.", order: 0, prerequisiteIDs: [], source: biologyText),
            LearningObjective(id: "biology-membranes", title: "Model membrane transport", summary: "Explain how membranes regulate movement into and out of cells.", order: 1, prerequisiteIDs: ["biology-cells"], source: biologyText),
            LearningObjective(id: "college-functions", title: "Analyze functions", summary: "Use notation, domains, ranges, and transformations to model relationships.", order: 0, prerequisiteIDs: [], source: collegeAlgebraText),
            LearningObjective(id: "college-quadratics", title: "Model with quadratics", summary: "Connect zeros, vertices, and algebraic forms of quadratic functions.", order: 1, prerequisiteIDs: ["college-functions"], source: collegeAlgebraText),
            LearningObjective(id: "college-bio-genes", title: "Trace gene expression", summary: "Follow information from DNA through RNA to protein.", order: 0, prerequisiteIDs: [], source: collegeBiologyText),
            LearningObjective(id: "college-bio-cycle", title: "Regulate the cell cycle", summary: "Connect checkpoints, mitosis, and loss of growth control.", order: 1, prerequisiteIDs: ["college-bio-genes"], source: collegeBiologyText)
        ]

        let algebraCurriculum = CurriculumReference(title: "Algebra 1 Scope and Sequence", provider: "Illustrative Mathematics", url: algebraText.url, license: "CC BY-NC 2024", attribution: "Course sequence adapted from Illustrative Mathematics Algebra 1.")
        let biologyCurriculum = CurriculumReference(title: "Biology for AP Courses", provider: "OpenStax, Rice University", url: URL(string: "https://openstax.org/details/books/biology-ap-courses")!, license: "CC BY-NC-SA 4.0", attribution: "Access for free at openstax.org.")
        let historyCurriculum = CurriculumReference(title: "Delaware Civics Standards, Grades 9–12", provider: "Delaware Department of Education", url: URL(string: "https://education.delaware.gov/wp-content/uploads/2024/06/DE-K-12-Civics-Standards-2018.docx")!, license: "Public education standard; original lesson content", attribution: "Original practice informed by Delaware standards and Delaware Public Archives sources.")
        let collegeAlgebraCurriculum = CurriculumReference(title: "College Algebra 2e", provider: "OpenStax, Rice University", url: URL(string: "https://openstax.org/details/books/college-algebra-2e")!, license: "CC BY 4.0", attribution: "Access for free at openstax.org.")
        let collegeBiologyCurriculum = CurriculumReference(title: "Biology 2e", provider: "OpenStax, Rice University", url: URL(string: "https://openstax.org/details/books/biology-2e")!, license: "CC BY-NC-SA 4.0", attribution: "Access for free at openstax.org.")
        let courses = [
            Course(id: "first-state-civics", title: "U.S. History", subtitle: "The Constitution and Delaware’s place in the founding era.", subject: .history, level: .highSchool, symbolName: "building.columns.fill", estimatedMinutes: 32, objectiveIDs: ["read-record", "purpose-perspective", "trace-process", "weigh-evidence"], source: archiveLesson, curriculum: historyCurriculum),
            Course(id: "algebra-i", title: "Algebra I", subtitle: "Linear equations and graphs from Illustrative Mathematics Algebra 1.", subject: .mathematics, level: .highSchool, symbolName: "function", estimatedMinutes: 22, objectiveIDs: ["algebra-equations", "algebra-graphs"], source: algebraText, curriculum: algebraCurriculum),
            Course(id: "ap-biology", title: "AP Biology", subtitle: "Cell structure and membrane transport from OpenStax Biology for AP Courses.", subject: .biology, level: .highSchool, symbolName: "microbe.fill", estimatedMinutes: 22, objectiveIDs: ["biology-cells", "biology-membranes"], source: biologyText, curriculum: biologyCurriculum),
            Course(id: "college-algebra", title: "College Algebra", subtitle: "Functions and quadratic models from OpenStax College Algebra 2e.", subject: .mathematics, level: .college, symbolName: "x.squareroot", estimatedMinutes: 24, objectiveIDs: ["college-functions", "college-quadratics"], source: collegeAlgebraText, curriculum: collegeAlgebraCurriculum),
            Course(id: "general-biology", title: "General Biology I", subtitle: "Gene expression and the cell cycle from OpenStax Biology 2e.", subject: .biology, level: .college, symbolName: "dna", estimatedMinutes: 24, objectiveIDs: ["college-bio-genes", "college-bio-cycle"], source: collegeBiologyText, curriculum: collegeBiologyCurriculum)
        ]

        func choices(_ values: [(String, String)]) -> [AnswerChoice] { values.map(AnswerChoice.init) }
        let questions = [
            PracticeQuestion(id: "record-date", objectiveID: "read-record", prompt: "When was the petition written?", context: "The archival transcription ends with a date.", choices: choices([("a", "July 4, 1776"), ("b", "October 24, 1787"), ("c", "December 7, 1787"), ("d", "June 4, 1897")]), correctChoiceID: "b", explanation: "The petition is dated October 24, 1787. December 7 was the later date of Delaware's ratification.", source: archiveWorksheet),
            PracticeQuestion(id: "record-problem", objectiveID: "read-record", prompt: "Which problem do the petitioners themselves identify?", context: "They describe “inconveniences and disadvantages” caused by a want of something.", choices: choices([("a", "A lack of an efficient general government for the Union"), ("b", "A shortage of delegates from Pennsylvania"), ("c", "The location of Delaware's capital"), ("d", "The absence of a state constitution")]), correctChoiceID: "a", explanation: "The petition attributes the problems to the lack of a more efficient general government of the Union. The other choices are not the problem stated in this source.", source: archiveWorksheet),
            PracticeQuestion(id: "purpose-audience", objectiveID: "purpose-perspective", prompt: "Who is the petition's immediate audience?", context: "The petition addresses “your honorable Houses.”", choices: choices([("a", "The Philadelphia Convention"), ("b", "The United States Supreme Court"), ("c", "Delaware's General Assembly"), ("d", "The British Parliament")]), correctChoiceID: "c", explanation: "The document is a petition to Delaware's General Assembly. Identifying the audience helps explain the action it requests.", source: archiveWorksheet),
            PracticeQuestion(id: "purpose-request", objectiveID: "purpose-perspective", prompt: "What action are the petitioners asking the General Assembly to take?", choices: choices([("a", "Write a new Delaware constitution immediately"), ("b", "Set an early time to elect delegates to a state convention"), ("c", "Appoint George Washington governor"), ("d", "Move the state capital to Philadelphia")]), correctChoiceID: "b", explanation: "They ask the Assembly to arrange the election of delegates to a state convention so Delaware can consider ratification.", source: archiveWorksheet),
            PracticeQuestion(id: "process-sequence", objectiveID: "trace-process", prompt: "Which sequence best matches the civic process described by the source and archive lesson?", choices: choices([("a", "Petition → Assembly action → elected convention → ratification decision"), ("b", "Court ruling → petition → governor's veto → ratification"), ("c", "Ratification → election → petition → convention"), ("d", "Governor's order → federal law → local election")]), correctChoiceID: "a", explanation: "The petition asks the Assembly to enable an election of convention delegates; those delegates would consider ratification. This connects public advocacy to representative decision-making.", source: archiveLesson),
            PracticeQuestion(id: "process-outcome", objectiveID: "trace-process", prompt: "What later outcome does the Delaware Public Archives lesson document?", choices: choices([("a", "Delaware rejected the Constitution by one vote"), ("b", "Congress selected Dover as the national capital"), ("c", "Delaware ratified unanimously on December 7, 1787"), ("d", "The petition became Delaware's constitution")]), correctChoiceID: "c", explanation: "The archive lesson states that 30 delegates approved ratification unanimously and Delaware became the first state to ratify on December 7, 1787.", source: archiveLesson),
            PracticeQuestion(id: "evidence-support", objectiveID: "weigh-evidence", prompt: "Which claim is best supported by the petition alone?", choices: choices([("a", "Every Delaware resident favored ratification"), ("b", "The petitioners believed a stronger union could bring stability and prosperity"), ("c", "Ratification immediately improved Delaware's economy"), ("d", "No Delawarean opposed the proposed Constitution")]), correctChoiceID: "b", explanation: "The document directly expresses the petitioners' hopes for peace, stability, efficacy, and prosperity. One supportive petition cannot establish the views of every resident or later economic effects.", source: archiveWorksheet),
            PracticeQuestion(id: "evidence-limit", objectiveID: "weigh-evidence", prompt: "What additional evidence would best test whether support for ratification was shared broadly across Delaware?", choices: choices([("a", "Only a modern dictionary definition of “ratify”"), ("b", "The petition's date written a second time"), ("c", "Letters, newspapers, or meeting records showing different Delaware viewpoints"), ("d", "A map showing only Delaware's present county borders")]), correctChoiceID: "c", explanation: "Multiple contemporary sources with differing viewpoints can test how broadly an opinion was shared. That is stronger than generalizing from a single petition.", source: archiveLesson),
            PracticeQuestion(id: "algebra-balance", objectiveID: "algebra-equations", prompt: "What must remain true when you change one side of an equation?", choices: choices([("a", "Apply the same operation to the other side"), ("b", "Change the equal sign to an inequality"), ("c", "Always divide by two"), ("d", "Remove every negative sign")]), correctChoiceID: "a", explanation: "An equation states that two expressions have equal value. Applying the same valid operation to both sides preserves that equality.", source: algebraText),
            PracticeQuestion(id: "algebra-solve", objectiveID: "algebra-equations", prompt: "Solve 3x + 5 = 20.", choices: choices([("a", "x = 3"), ("b", "x = 5"), ("c", "x = 15"), ("d", "x = 25")]), correctChoiceID: "b", explanation: "Subtract 5 from both sides to get 3x = 15, then divide both sides by 3. The solution is x = 5.", source: algebraText),
            PracticeQuestion(id: "algebra-intercept", objectiveID: "algebra-graphs", prompt: "In y = 2x − 3, what is the y-intercept?", choices: choices([("a", "−3"), ("b", "−2"), ("c", "2"), ("d", "3")]), correctChoiceID: "a", explanation: "Slope-intercept form is y = mx + b. Here b = −3, so the line crosses the y-axis at (0, −3).", source: algebraText),
            PracticeQuestion(id: "algebra-point", objectiveID: "algebra-graphs", prompt: "Which point lies on y = 2x − 3?", choices: choices([("a", "(0, 2)"), ("b", "(1, 1)"), ("c", "(2, 1)"), ("d", "(3, 0)")]), correctChoiceID: "c", explanation: "Substituting x = 2 gives y = 2(2) − 3 = 1, so (2, 1) is a solution and lies on the line.", source: algebraText),
            PracticeQuestion(id: "biology-shared", objectiveID: "biology-cells", prompt: "Which feature is found in both prokaryotic and eukaryotic cells?", choices: choices([("a", "A membrane-bound nucleus"), ("b", "DNA and ribosomes"), ("c", "Mitochondria"), ("d", "A Golgi apparatus")]), correctChoiceID: "b", explanation: "Both cell types contain DNA, ribosomes, cytoplasm, and a plasma membrane. Prokaryotes lack membrane-bound organelles such as a nucleus.", source: biologyText),
            PracticeQuestion(id: "biology-prokaryote", objectiveID: "biology-cells", prompt: "What most clearly distinguishes a prokaryotic cell from a eukaryotic cell?", choices: choices([("a", "It has no DNA"), ("b", "It has no plasma membrane"), ("c", "Its DNA is not enclosed in a membrane-bound nucleus"), ("d", "It cannot reproduce")]), correctChoiceID: "c", explanation: "Prokaryotic DNA occupies a nucleoid region rather than a membrane-bound nucleus. Prokaryotes still have DNA and a plasma membrane.", source: biologyText),
            PracticeQuestion(id: "biology-diffusion", objectiveID: "biology-membranes", prompt: "During simple diffusion, particles generally move in which direction?", choices: choices([("a", "From lower to higher concentration using ATP"), ("b", "From higher to lower concentration"), ("c", "Only into the cell"), ("d", "Only through protein pumps")]), correctChoiceID: "b", explanation: "Simple diffusion is passive movement down a concentration gradient, from an area of higher concentration toward lower concentration.", source: biologyText),
            PracticeQuestion(id: "biology-osmosis", objectiveID: "biology-membranes", prompt: "Osmosis specifically describes the movement of what across a selectively permeable membrane?", choices: choices([("a", "Water"), ("b", "DNA"), ("c", "Ribosomes"), ("d", "ATP")]), correctChoiceID: "a", explanation: "Osmosis is the diffusion of water across a selectively permeable membrane in response to differences in solute concentration.", source: biologyText),
            PracticeQuestion(id: "college-function-value", objectiveID: "college-functions", prompt: "If f(x) = 2x + 1, what is f(3)?", choices: choices([("a", "5"), ("b", "6"), ("c", "7"), ("d", "9")]), correctChoiceID: "c", explanation: "Function notation asks you to substitute the input for x. f(3) = 2(3) + 1 = 7.", source: collegeAlgebraText),
            PracticeQuestion(id: "college-function-domain", objectiveID: "college-functions", prompt: "Which value is excluded from the domain of f(x) = 1/(x − 4)?", choices: choices([("a", "−4"), ("b", "0"), ("c", "1"), ("d", "4")]), correctChoiceID: "d", explanation: "The denominator cannot equal zero. At x = 4, x − 4 = 0, so 4 is excluded from the domain.", source: collegeAlgebraText),
            PracticeQuestion(id: "college-quadratic-zeros", objectiveID: "college-quadratics", prompt: "What are the zeros of x² − 5x + 6?", choices: choices([("a", "−3 and −2"), ("b", "2 and 3"), ("c", "1 and 6"), ("d", "−1 and 6")]), correctChoiceID: "b", explanation: "Factoring gives (x − 2)(x − 3). Each factor equals zero at x = 2 or x = 3.", source: collegeAlgebraText),
            PracticeQuestion(id: "college-quadratic-axis", objectiveID: "college-quadratics", prompt: "What is the axis of symmetry of y = x² − 4x + 1?", choices: choices([("a", "x = −4"), ("b", "x = −2"), ("c", "x = 2"), ("d", "x = 4")]), correctChoiceID: "c", explanation: "For ax² + bx + c, the axis is x = −b/(2a). Here it is −(−4)/(2·1) = 2.", source: collegeAlgebraText),
            PracticeQuestion(id: "college-bio-transcription", objectiveID: "college-bio-genes", prompt: "What is produced directly during transcription?", choices: choices([("a", "An RNA molecule copied from a DNA template"), ("b", "A lipid bilayer"), ("c", "Two daughter cells"), ("d", "A glucose molecule")]), correctChoiceID: "a", explanation: "During transcription, RNA polymerase uses DNA as a template to synthesize an RNA molecule.", source: collegeBiologyText),
            PracticeQuestion(id: "college-bio-translation", objectiveID: "college-bio-genes", prompt: "Where does translation assemble a polypeptide?", choices: choices([("a", "At a ribosome"), ("b", "Inside a lysosome"), ("c", "At a centriole"), ("d", "Inside the Golgi lumen only")]), correctChoiceID: "a", explanation: "Ribosomes read mRNA codons and coordinate tRNAs to assemble amino acids into a polypeptide.", source: collegeBiologyText),
            PracticeQuestion(id: "college-bio-checkpoint", objectiveID: "college-bio-cycle", prompt: "What can a cell-cycle checkpoint do when DNA damage is detected?", choices: choices([("a", "Pause progression so repair can occur"), ("b", "Immediately begin translation"), ("c", "Remove the plasma membrane"), ("d", "Convert RNA into DNA in every cell")]), correctChoiceID: "a", explanation: "Checkpoint proteins can halt the cycle when conditions are unfavorable or DNA is damaged, allowing repair or triggering other protective responses.", source: collegeBiologyText),
            PracticeQuestion(id: "college-bio-metaphase", objectiveID: "college-bio-cycle", prompt: "What characterizes metaphase of mitosis?", choices: choices([("a", "Chromosomes align near the cell’s equator"), ("b", "DNA is first replicated"), ("c", "The nuclear envelope fully reforms around two nuclei"), ("d", "Homologous chromosomes pair for crossing over")]), correctChoiceID: "a", explanation: "During metaphase, duplicated chromosomes align at the metaphase plate before sister chromatids separate in anaphase.", source: collegeBiologyText)
        ]
        let lessons = lessonMaterials()
        return LearningContent(courses: courses, objectives: objectives, questions: questions, lessonMaterials: lessons)
    }()

    private static func lessonMaterials() -> [LessonMaterial] {
        func note(_ title: String, _ body: String) -> [NoteSection] { [NoteSection(title: title, body: body)] }
        let historyVideo = LessonVideo(title: "The Constitution, the Articles, and Federalism", channel: "Crash Course", youtubeID: "bO7FQsCcbD8", duration: "13 min")
        let algebraEquationVideo = LessonVideo(title: "Linear equations", channel: "Khan Academy", youtubeID: "bAerID24QJ0", duration: "8 min")
        let algebraGraphVideo = LessonVideo(title: "Graphing a line from point and slope", channel: "Khan Academy", youtubeID: "5mgH-_5UJ54", duration: "5 min")
        let cellVideo = LessonVideo(title: "Introduction to Cells: The Grand Cell Tour", channel: "Amoeba Sisters", youtubeID: "8IlzKri08kk", duration: "9 min")
        let membraneVideo = LessonVideo(title: "Cell Membranes and Transport", channel: "Amoeba Sisters", youtubeID: "Rtp80mFQvcc", duration: "9 min")
        let functionVideo = LessonVideo(title: "Domain and range from a graph", channel: "Khan Academy", youtubeID: "sXP7VhU1gYE", duration: "4 min")
        let quadraticVideo = LessonVideo(title: "Forms and features of quadratic functions", channel: "Khan Academy", youtubeID: "eRbgHCaWQQE", duration: "8 min")
        let geneVideo = LessonVideo(title: "Transcription and Translation", channel: "Amoeba Sisters", youtubeID: "mSMjwxNK2EU", duration: "1 min")
        let cycleVideo = LessonVideo(title: "The Cell Cycle and Cancer", channel: "Amoeba Sisters", youtubeID: "lpAa4TWjHQ4", duration: "8 min")
        let archiveURL = archiveLesson.url
        let algebraURL = URL(string: "https://cms-assets.illustrativemathematics.org/xaczotl0hz2ng7y4arg7g6ikj7rh")!
        let apCellURL = URL(string: "https://openstax.org/books/biology-ap-courses/pages/4-1-studying-cells")!
        let apMembraneURL = URL(string: "https://openstax.org/books/biology-ap-courses/pages/5-2-passive-transport")!
        let functionURL = URL(string: "https://openstax.org/books/college-algebra-2e/pages/3-1-functions-and-function-notation")!
        let quadraticURL = URL(string: "https://openstax.org/books/college-algebra-2e/pages/5-1-quadratic-functions")!
        let geneURL = URL(string: "https://openstax.org/books/biology-2e/pages/15-2-prokaryotic-transcription")!
        let cycleURL = URL(string: "https://openstax.org/books/biology-2e/pages/10-2-the-cell-cycle")!
        return [
            LessonMaterial(objectiveID: "read-record", overview: "Begin with the 1787 petition itself. Separate details the document states from background supplied later.", keyIdeas: ["Date, author, audience, and request are evidence", "A primary source reflects a particular moment", "Observation comes before interpretation"], notes: note("Primary-source method", "Record what you can point to directly. Then label outside context separately so a later fact is not mistaken for a line in the document."), video: historyVideo, readingURL: archiveURL, attribution: "Original notes based on Delaware Public Archives material and Delaware civics standards."),
            LessonMaterial(objectiveID: "purpose-perspective", overview: "Analyze why the petitioners wrote, whom they addressed, and what action they wanted.", keyIdeas: ["Audience shapes a document’s language", "Purpose is the action the author seeks", "Perspective is not the same as statewide consensus"], notes: note("Purpose versus topic", "The topic is ratification. The purpose is more specific: persuade the General Assembly to begin the convention process quickly."), video: historyVideo, readingURL: archiveURL, attribution: "Original notes based on Delaware Public Archives material and Delaware civics standards."),
            LessonMaterial(objectiveID: "trace-process", overview: "Follow the civic sequence from public petition to legislative action, convention delegates, and a ratification decision.", keyIdeas: ["Petitions communicate demands", "The Assembly could authorize the next step", "Convention delegates made the ratification decision"], notes: note("Follow the institutions", "A petition did not ratify the Constitution by itself. It sought action from the institution with authority to arrange the convention process."), video: historyVideo, readingURL: archiveURL, attribution: "Original notes based on Delaware Public Archives material and Delaware civics standards."),
            LessonMaterial(objectiveID: "weigh-evidence", overview: "Use corroboration to decide what one supportive petition can and cannot establish.", keyIdeas: ["One document can prove its own claims", "Broad public opinion needs multiple sources", "Contemporary counterevidence tests a generalization"], notes: note("Claim strength", "Match the size of a claim to the evidence. A petition supports what its signers argued, but cannot alone show that every Delaware resident agreed."), video: historyVideo, readingURL: archiveURL, attribution: "Original notes based on Delaware Public Archives material and Delaware civics standards."),
            LessonMaterial(objectiveID: "algebra-equations", overview: "Use valid transformations to isolate an unknown without changing the equation’s solution.", keyIdeas: ["Perform the same operation on both sides", "Undo addition before multiplication in a two-step equation", "Substitute the result to check it"], notes: note("Equality as balance", "Treat the equal sign as a claim that two quantities match. A move is valid when it preserves that relationship."), video: algebraEquationVideo, readingURL: algebraURL, attribution: "Original notes sequenced from Illustrative Mathematics Algebra 1, CC BY-NC 2024."),
            LessonMaterial(objectiveID: "algebra-graphs", overview: "Represent linear relationships with ordered pairs, slope, intercepts, and equations.", keyIdeas: ["A point on a graph satisfies the equation", "Slope is change in y divided by change in x", "In y = mx + b, b is the y-intercept"], notes: note("Three connected views", "A table, an equation, and a graph can describe the same relationship. Test a point by substituting both coordinates into the equation."), video: algebraGraphVideo, readingURL: algebraURL, attribution: "Original notes sequenced from Illustrative Mathematics Algebra 1, CC BY-NC 2024."),
            LessonMaterial(objectiveID: "biology-cells", overview: "Compare the structures shared by all cells with the membrane-bound organelles found in eukaryotes.", keyIdeas: ["Cells are the basic unit of life", "All cells have DNA, ribosomes, cytoplasm, and a membrane", "Prokaryotes lack a membrane-bound nucleus"], notes: note("Structure and function", "A cell structure is best remembered by connecting it to a job: membranes regulate exchange, ribosomes build proteins, and DNA stores hereditary information."), video: cellVideo, readingURL: apCellURL, attribution: "Access for free at openstax.org. Original notes aligned to Biology for AP Courses, CC BY-NC-SA 4.0."),
            LessonMaterial(objectiveID: "biology-membranes", overview: "Model how selective permeability, concentration gradients, and transport proteins control exchange.", keyIdeas: ["Diffusion moves down a concentration gradient", "Osmosis is diffusion of water", "Active transport requires cellular energy"], notes: note("Predicting movement", "First identify the substance and its concentration gradient. Then determine whether it can cross directly, needs a protein, or must move against the gradient using energy."), video: membraneVideo, readingURL: apMembraneURL, attribution: "Access for free at openstax.org. Original notes aligned to Biology for AP Courses, CC BY-NC-SA 4.0."),
            LessonMaterial(objectiveID: "college-functions", overview: "Treat a function as a rule assigning each allowed input exactly one output.", keyIdeas: ["Function notation names inputs and outputs", "The domain is the allowed input set", "Transformations change a parent graph predictably"], notes: note("Domain restrictions", "Look for operations that are undefined: denominators cannot be zero and even roots require nonnegative radicands over the real numbers."), video: functionVideo, readingURL: functionURL, attribution: "Access for free at openstax.org. Original notes aligned to College Algebra 2e, CC BY 4.0."),
            LessonMaterial(objectiveID: "college-quadratics", overview: "Move among standard, factored, and vertex forms to reveal different features of a parabola.", keyIdeas: ["Factored form reveals zeros", "Vertex form reveals the vertex", "The axis is x = −b/(2a) in standard form"], notes: note("Choose the useful form", "No single form is always best. Select the form that exposes the feature you need, then verify results against the graph or original equation."), video: quadraticVideo, readingURL: quadraticURL, attribution: "Access for free at openstax.org. Original notes aligned to College Algebra 2e, CC BY 4.0."),
            LessonMaterial(objectiveID: "college-bio-genes", overview: "Trace how cells copy DNA information into RNA and translate messenger RNA into a polypeptide.", keyIdeas: ["Transcription makes RNA from a DNA template", "Translation occurs at ribosomes", "Codons correspond to amino acids or stop signals"], notes: note("Direction of information", "For ordinary cellular gene expression, distinguish the information-bearing sequence from the machinery: DNA is transcribed, while mRNA is translated."), video: geneVideo, readingURL: geneURL, attribution: "Access for free at openstax.org. Original notes aligned to Biology 2e, CC BY-NC-SA 4.0."),
            LessonMaterial(objectiveID: "college-bio-cycle", overview: "Connect interphase, mitosis, cytokinesis, and checkpoints that regulate cell division.", keyIdeas: ["DNA replication occurs before mitosis", "Mitosis separates duplicated chromosomes", "Checkpoint failure can contribute to uncontrolled growth"], notes: note("Cycle versus mitosis", "The cell cycle includes growth, DNA replication, division, and regulation. Mitosis is only the nuclear-division portion of that larger cycle."), video: cycleVideo, readingURL: cycleURL, attribution: "Access for free at openstax.org. Original notes aligned to Biology 2e, CC BY-NC-SA 4.0.")
        ]
    }
}
