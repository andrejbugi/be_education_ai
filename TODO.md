For later in the future..

It should have chat option between students and the teachers. Also between teachers.
Settings to increase font size, high contrast, font for dyslecsic, etc.
A way to divide schools, probably with subdomain.
Create a demo for people to test. Create a tutorial, courses for learning how to use the system.

Very short shape:

conversations table: school_id, conversation_type (direct, maybe later group), timestamps
conversation_participants table: which users are in the thread
messages table: conversation_id, sender_id, body, maybe attachments/read_at/deleted_at later
Rules:

teacher-teacher: allow same-school teachers to start direct conversations
teacher-student: allow only if they share a classroom/assignment/school relationship you approve
student-student: keep disabled unless you explicitly want it later
API would likely be:

GET /api/v1/conversations
POST /api/v1/conversations
GET /api/v1/conversations/:id/messages
POST /api/v1/conversations/:id/messages

Performance / scaling:

- Cache classroom student lists where possible, since class membership changes rarely, usually only every few months.
- Do not generate performance snapshots on every dashboard request long-term.
- Prefer background jobs for performance snapshot generation, then serve cached / stored snapshot data in dashboard responses.
