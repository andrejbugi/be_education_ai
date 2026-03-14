# Assignment Specification Addendum – Materials, Uploads, PDFs, and Rich Content

## Goal
Extend the assignment system so both front end and back end can support:

- file uploads
- PDFs
- links
- embedded learning materials
- richer assignment instructions
- richer step-level content
- reusable assignment resource blocks

This should make assignments much more flexible and allow teachers to provide full learning material together with the task itself.

---

## Why this is needed
The most useful upgrade is one or more of these:

- add `resource_blocks` / `attachments` to assignments
- add `resource_url`, `prompt`, `example_answer` to `assignment_steps`
- add a richer `content_json` field so FE can render text, links, files, embeds, and instructions cleanly

This should be considered part of the core assignment design.

---

## Main recommendation
Use a combination of:

1. **assignment-level resources**
2. **step-level resource fields**
3. **rich structured content JSON**

This gives the best flexibility.

---

# 1. Assignment-level resources

## Purpose
Assignments should be able to include materials that apply to the whole assignment.

Examples:
- PDF instructions
- worksheet file
- reading material
- presentation
- YouTube/video link
- external article
- teacher-created notes
- image attachment
- downloadable template

## Recommended structure
Add a relation or nested structure for:

- `assignment_resources`
or
- `resource_blocks`

## Suggested fields
Each resource block can include:

- `id`
- `assignment_id`
- `title`
- `resource_type`
- `file_url`
- `external_url`
- `embed_url`
- `description`
- `position`
- `is_required`
- `created_at`
- `updated_at`

## Suggested resource types
Examples:
- `pdf`
- `file`
- `image`
- `video`
- `link`
- `text`
- `embed`

## Front-end behavior
FE should render these resources in the assignment details page.

Examples:
- PDF preview/download
- image preview
- clickable links
- embedded video
- text instruction block

## Back-end behavior
BE should:
- store metadata for uploaded files
- support file upload endpoints
- validate allowed file types
- return resource metadata to FE
- allow ordering by `position`

Implementation note:
- uploaded assignment resources now use Active Storage
- development uses local disk storage
- assignment resource payloads return generated file URLs plus uploaded file metadata

---

# 2. Assignment attachments

## Purpose
Some assignments just need simple file attachments.

This can exist as:
- a simpler version of `resource_blocks`
- or as part of the same resource system

## Suggested attachment support
Teachers should be able to attach:
- PDF
- DOC/DOCX
- PPT/PPTX
- XLS/XLSX
- TXT
- image files
- ZIP if allowed later

## Student-side behavior
Students should be able to:
- view attached materials
- download files
- open PDFs
- open external links

## Teacher-side behavior
Teachers should be able to:
- upload files
- remove files
- reorder files
- mark a file as important / required

---

# 3. Step-level rich fields

## Purpose
Assignment steps should support richer content, especially for interactive tasks.

## Recommended new fields for `assignment_steps`
Add fields such as:

- `resource_url`
- `prompt`
- `example_answer`

## Meaning of each field

### `resource_url`
Used for:
- link to external material
- PDF for this specific step
- video explanation
- image/example resource

### `prompt`
Used for:
- step instruction
- question text
- guided message
- AI-assisted task instruction
- explanation of what student should do

### `example_answer`
Used for:
- teacher example
- expected answer format
- reference solution example
- model structure for essay/problem-solving

## FE use cases
FE can render each step with:
- instruction text
- optional example answer section
- optional resource link/file
- input area below

## BE use cases
BE stores the fields and returns them cleanly in the assignment details payload.

---

# 4. Rich `content_json` field

## Purpose
A richer `content_json` field is highly recommended so FE can render structured educational content without hardcoding many different cases.

This is especially useful for:
- assignment details page
- step-by-step workspace
- content blocks with mixed media
- future AI-generated or AI-assisted content rendering

## Recommended idea
Add a `content_json` field on:
- `assignments`
and optionally also on:
- `assignment_steps`

This field should contain structured blocks.

## Example content block types
The JSON can include blocks such as:

- text
- heading
- paragraph
- list
- quote
- link
- file
- pdf
- image
- video
- embed
- instruction
- hint
- warning
- code
- equation
- separator

## Example conceptual structure
FE should be able to render something like:

- heading block
- paragraph block
- PDF block
- link block
- instruction block
- image block

This makes the UI much more flexible and future-proof.

## Why this is useful
Instead of relying only on plain text fields like `description`, the system can render rich, clean learning content.

This is especially helpful for:
- digital worksheets
- multimedia homework
- guided exercises
- science/math tasks
- teacher notes with files and links
- resource-rich assignments

---

# 5. Recommended combined model

## Best practical recommendation
Use all three layers:

### A. Assignment-level resources
For files/materials used by the whole assignment

### B. Step-level fields
For specific prompts/examples/resources per task step

### C. Rich content JSON
For flexible rendering of mixed content blocks

This gives the best long-term architecture.

---

# 6. Front-end implementation expectations

## Assignment details page
FE should render:

- title
- description
- deadline
- teacher notes
- assignment resources
- attachments
- structured rich content blocks
- start button

## Assignment workspace
FE should render:

- current step
- prompt
- example answer if available
- step resource if available
- student answer input area
- next / previous / submit actions

## Teacher create/edit assignment UI
Teacher should be able to add:

- description
- files
- PDFs
- links
- step prompts
- example answers
- structured content blocks later

For MVP, it is fine if this starts as:
- upload file
- add link
- add text instruction
- add example answer

---

# 7. Back-end implementation expectations

## Upload handling
BE should support:
- uploading files for assignments
- uploading files for step resources if needed later
- storing metadata
- associating uploaded files with assignment or step

## Recommended stored metadata
Examples:
- file name
- file type
- mime type
- file size
- storage key/path
- public or signed URL
- uploaded by
- created at

## Validations
BE should validate:
- allowed file types
- file size limits
- ownership/access
- school/class authorization
- teacher permissions

## API response expectations
BE should return assignment payloads with:
- core assignment fields
- resource blocks / attachments
- steps with prompt/example/resource fields
- content_json when available

FE should not need to guess how to render the content.

---

# 8. Suggested storage approach
For uploaded files, use object storage such as:
- S3-compatible storage

Store only metadata in the database.
Do not store large binary files directly in SQL rows.

---

# 9. Suggested MVP scope
For the first version, implement:

## Assignment level
- attachments/resources on assignment
- PDF/file/link support

## Step level
- `prompt`
- `resource_url`
- `example_answer`

## Structured content
- basic `content_json` support for text, link, file, pdf, instruction blocks

This is enough to make the system strong without overcomplicating it.

---

# 10. Suggested later extensions
Later, the system can support:
- inline PDF preview
- video embeds
- equations
- hints/reveal blocks
- AI-generated help content
- reusable resource templates
- drag-and-drop content builder for teachers
- rubric blocks
- audio attachments

---

# 11. Final implementation recommendation
For both FE and BE, the assignment system should now support:

- assignment-level attachments/resources
- step-level prompt/resource/example fields
- richer structured content through `content_json`

This will allow the platform to handle:
- uploads
- PDFs
- links
- instructional materials
- guided steps
- richer rendering in both teacher and student workflows

This should be treated as part of the core assignment architecture, not as an afterthought.
