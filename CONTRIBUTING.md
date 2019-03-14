# Contributing Guidelines

## Submitting Issues
1. Before creating a new issue, perform a [cursory search](https://github.ibm.com/BlockchainInnovation/token-factory/issues?utf8=✓&q=is%3Aissue%20%20) to see if a similar issue has already been submitted. Similar issues may have different names than what you would have written, and may have been closed.
* Please follow our [Issue Guidelines](#issue-guidelines) when creating a new issue.
* For Bug Reports, please include screenshots and animated GIFs whenever possible; they are immensely helpful.
* When submitting an update to or a new feature, pattern, guideline, etc… please provide user research associated with the suggestion including testing methods, results, and sample size, whenever possible. This allows us to make more user-centered decisions and cut through assumptions and individual preferences.
* Issues that have a number of sub-items that need to be completed should use [task lists](https://github.com/blog/1375%0A-task-lists-in-gfm-issues-pulls-comments) to track the sub-items in the main issue comment.

## Agile Workflow: The life of an issue
### New Stories
Stubs and User Stories go here to get discussed and groomed. Anything in New Stories is considered **Under Construction**. Once a story is **consumable** (groomed and ready to be worked on), it is sized, labeled, and moved to the backlog.

### Backlog
The backlog is where all future work lives. The stories are listed here in order of prioritization. They are not assigned and aren't in any milestones, they just live here in a prioritized order. Issues in the backlog can be blocked, as long as the blocking issue is referenced in the comments.

### To Do
During Sprint Planning, issues for the sprint are assigned to a contributor or contributors, put in a milestone, and moved to this pipeline. This will remove any confusion as to what work is in the queue for the current sprint. 

### In Progress
When a contributor begins to work on a story from the "To Do" channel, they will move it to this pipeline.

### In Review
Once all of the acceptance criteria is complete and the work is done, the story is moved to this pipeline to let the team know that it needs to be approved the OM and any design or developer responsible for code or design reviews. Once Github **Review** functionality makes its way to GHE, this pipeline can go away.

### Closed
Once an issue is approved by both the OM and the technical approver, it is closed. Preferably, the contributor submitting the **Pull Request** will add `resolves /url/to/the/issue`, and the issue will automatically close when the PR is merged.

## Issue Guidelines
Issues fall in to one of three categories:

* [User Stories](#user-stories)
* [Bug Reports](#bug-reports)
* [Epics](#epics)
* [Stubs](#stubs)

---
### User Stories

[Create a User Story](https://github.ibm.com/BlockchainInnovation/token-factory/issues/new?title=%7B%7Bpersona%7D%7D%3A%20%7B%7Bneed%7D%7D&body=%23%20_As%20a_%20%7B%7Bpersona%7D%7D%2C%20_I%20want_%20%7B%7Bneed%7D%7D%20_so%20that_%20%7B%7Brationale%7D%7D%0D%0A%0D%0A%2A%2AContext%3A%2A%2A%0D%0A%0D%0A%7B%7BIf%20more%20context%20is%20required%20to%20understand%20the%20request%2C%20add%20it%20here.%7D%7D%20%0D%0A%0D%0A---%0D%0A%2A%2AAcceptance%20Criteria%3A%2A%2A%20%0D%0A%0D%0A%20-%20%5B%20%5D%20Must%20do%20this%0D%0A%20-%20%5B%20%5D%20Must%20also%20do%20this%0D%0A%20-%20%5B%20%5D%20Finally%2C%20must%20do%20this%0D%0A%0D%0A---%0D%0A%2A%2ARelated%20to%3A%2A%2A%20%28will%20dictate%20labels%29%0D%0A%0D%0A%20-%20%5B%20%5D%20WDC%20Website%0D%0A%20-%20%5B%20%5D%20Service%20Demo%0D%0A%20-%20%5B%20%5D%20Content%20Strategy%0D%0A%20-%20%5B%20%5D%20Documentaion%0D%0A%20-%20%5B%20%5D%20SDK%0D%0A%20-%20%5B%20%5D%20Starter%20Kit%2FSample%20Code%0D%0A%20-%20%5B%20%5D%20Video%0D%0A%20%0D%0A%2A%2ADesired%20Delivery%20Date%3A%2A%2A%20%0D%0A%7B%7Bexact%20date%2C%20month%2C%20quarter%2C%20or%20as%20soon%20as%20possible%7D%7D)

The most common type of issue will likely be the user story. User stories describe the needs of a [user persona](https://github.ibm.com/Watson/developer-cloud/wiki/Personas) for our project. User stories should be written in the following form:

```markdown
_As a_ {{persona}} _I want_ {{need}} _so that_ {{rationale}}
```

Replace `{{persona}}` with the name of the user persona the need is for, `{{need}}` with the need, and `{{rationale}}` with the reason the persona has that need. Titles of User Stories should be in the form of `{{persona}}: {{need}}` with the body including the full user story as above. 

User stories also need their requirements for being considered complete, or **acceptance criteria**, written out in addition to their user story. To do so, you should list the criteria using checkboxes. 

```
**Acceptance Criteria:** 

 - [ ] Must do this
 - [ ] Must also do this
 - [ ] Finally, must do this
```	

#### Done

A User Story is considered _done_ when all acceptance criteria defined in the issue has been completed with passing tests for said functionality and the solution has been approved by a product owner.

---
### Bug Reports

[Create a Bug Report](https://github.ibm.com/BlockchainInnovation/token-factory/issues/new?title=Bug%3A%20%7B%7Bshort%20description%7D%7D&body=%2A%2AExpected%20Behavior%3A%2A%2A%20%0D%0A%7B%7Bexpected%20behavior%7D%7D%0D%0A%0D%0A%2A%2AActual%20Behavior%3A%2A%2A%0D%0A%7B%7Bactual%20behavior%7D%7D%0D%0A%0D%0A%23%23%20Steps%20for%20Reproducing%0D%0A%0D%0A1.%20%7B%7BStep%201%7D%7D%0D%0A2.%20%7B%7BStep%202%7D%7D%0D%0A3.%20%7B%7BStep%203%7D%7D%0D%0A%0D%0A%23%23%20Screenshots%0D%0A%0D%0A%23%23%23%20%7B%7BStep%201%7D%7D%0D%0A%0D%0A%21%5BScreenshot%20of%20Step%201%5D%28url%2Fto%2Fscreenshot%29%0D%0A%0D%0A%23%23%23%20%7B%7BStep%202%7D%7D%0D%0A%0D%0A%21%5BScreenshot%20of%20Step%202%5D%28url%2Fto%2Fscreenshot%29%0D%0A%0D%0A%23%23%23%20%7B%7BStep%203%7D%7D%0D%0A%0D%0A%21%5BScreenshot%20of%20Step%203%5D%28url%2Fto%2Fscreenshot%29%0D%0A%0D%0A%23%23%20Affected%20Browsers%0D%0A%5BWhat%27s%20my%20browser%3F%5D%28http%3A%2F%2Fwww.whatsmyua.com%2F%29%0D%0A%0D%0A-%20%5B%20%5D%20%7B%7BChrome%2047%20on%20Mac%2010.11%7D%7D%20%2F%20%7B%7BProduction%2C%20Development%7D%7D%0D%0A-%20%5B%20%5D%20%7B%7BChrome%2047%20on%20Windows%2010%7D%7D%20%2F%20%7B%7BProduction%2C%20Development%7D%7D%0D%0A-%20%5B%20%5D%20%7B%7BFirefox%2038.4%20on%20Mac%2010.11%7D%7D%20%2F%20%7B%7BDevelopment%7D%7D%0D%0A%0D%0A%23%23%20Optional%20Info%0D%0A%2A%2ARuntime%20Version%3A%2A%2A%0D%0A%7B%7Bruntime%20version%7D%7D%0D%0A%0D%0A%2A%2ACode%20Version%2A%2A%0D%0A%7B%7Bcode%20version%7D%7D)

Bug reports represent a problem in our environments. If the problem exists because something isn't working as it was designed and implemented to work, it should be filed as a bug report. If the problem exists because something isn't working as expected or working as liked but _is_ working as it was designed and implemented to work, it should be filed as a [user story](#user-story).

Titles of bug reports should be in the form of `Bug: {{short description}}` with `{{short description}}` being a very short (5-10 word) description of the issue. Bug reports should all include the following information:

* Expected Behavior
* Actual Behavior
* Step-by-step instructions on how to reproduce the issue
* Screenshots and if possible animated GIFs (ideally at least one for every step)
* Browsers, browser versions, operating systems, and operating system versions affected
* Optional Info

#### Done

A Bug Report is considered _done_ when the described issue no longer manifests itself in the described browsers/versions and environments, as well as preferably having passing tests written for the bug.

---
### Epics

[Create an Epic](https://github.ibm.com/BlockchainInnovation/token-factory/issues/new?title=Epic%3A%20%7B%7Bneed%7D%7D&body=_As%20a_%20%7B%7Bpersona%7D%7D%20_I%20want_%20%7B%7Bneed%7D%7D%20_so%20that_%20%7B%7Brationale%7D%7D%0A%0A)

An [epic](https://github.ibm.com/Watson/mycroft/wiki/Label-Style-Guide#epics) is a collection of [user stories](#user-stories) that together track a larger desired outcome change for one or many user personas. Epics should be constructed identically to user stories, with the exception that instead of acceptance criteria, the user stories attached to the epic act as the acceptance criteria for the epic. 

#### Done

An Epic is considered _done_ when all linked stories have been closed.

---
### Stubs

Any issue filed that does not follow the structure of a User Story, Bug Report, or Epic is considered a stub and needs to be rewritten to align with one of those issue types.

---

## Definition of Done
A story is **DONE** when its acceptance criteria is met. However, there are global requirements that must be met before a story can be closed. They can differ between types of stories. 
### Website
- [ ] Must adhere to [Performance Guidelines](https://pages.github.ibm.com/hackademy/performance)
- [ ] Must adhere to [Accessibility Guidelines](https://pages.github.ibm.com/watson/design-guide/resources/accessibility/)
- [ ] We design and develop mobile-first, so everything should be responsive

### SDK
 - [ ] To be populated...



