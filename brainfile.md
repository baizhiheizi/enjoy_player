---
title: Enjoy Player (Flutter)
agent:
  instructions:
    - Modify only the YAML frontmatter
    - Preserve all IDs
    - Keep ordering
    - Make minimal changes
    - Preserve unknown fields
rules:
  always: []
  never: []
  prefer: []
  context: []
columns:
  - id: todo
    title: To Do
    tasks:
      - id: ep-1
        title: URL / streaming playback
        description: Open remote HTTP(S) media in media_kit; unify with local session model.
      - id: ep-2
        title: YouTube via flutter_inappwebview
        description: Dedicated surface + JS bridge for current time sync with transcript.
      - id: ep-3
        title: Mini player polish
        description: Artwork, swipe gestures, expand animation parity with web mini bar.
  - id: in-progress
    title: In Progress
    tasks: []
  - id: done
    title: Done
    tasks:
      - id: ep-0
        title: MVP scaffold
        description: Riverpod + Drift + media_kit + library import + expanded player + echo + docs system.
---
