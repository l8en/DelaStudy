# DelaStudy

I'm M'hamed, I am Ibrahim, and I am Sai, and DelaStudy is an iPhone study app I've been working on for high-school and college students. It started with Delaware civics and grew into a place to study other subjects too.

I wanted the app to connect the parts of studying that usually end up scattered around: reading something, trying a question, taking notes, and remembering where I left off.

## What you can do

- Browse high-school and introductory college subjects, including math, science, history, computing, and writing.
- Work through lessons and practice questions, with explanations after answering.
- Save lesson notes and come back to them later.
- Open linked readings and watch course videos inside the app.
- Earn XP, levels, streaks, and achievements from saved practice.
- Use a college-planning checklist and links to application and financial-aid resources.
- Try study challenges, write responses, and share prompts with friends.

The community section isn't a live social network. Responses stay on your phone unless you choose to share them. Progress is saved locally too; there's no cloud sync.

## Run it

I built this with Swift and SwiftUI. You'll need a Mac with Xcode to run the iPhone app.

```sh
git clone https://github.com/l8en/DelaStudy.git
cd DelaStudy
open FirstStateLens.xcodeproj
```

In Xcode, select the `FirstStateLens` scheme, choose an iPhone Simulator, and press Run. The project and scheme still have their original internal names.

To run the core tests:

```sh
swift test
```

## Still in progress

This is a student project, and we are still improving it. Course paths cover selected topics, not full school courses or college credit. Videos and external links need an internet connection.

The practice questions aren't official Delaware assessments, and the app isn't endorsed by the state or the source publishers.

The readings, curriculum references, and credits are listed in [SOURCES.md](SOURCES.md). [STATUS.md](STATUS.md) has the more detailed development notes and testing history.
