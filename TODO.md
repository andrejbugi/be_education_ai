Current roadmap / pending work

Implemented already:
- direct chat between teachers and between teacher/student pairs with an allowed shared-school/shared-classroom relationship
- user accessibility preferences through profile settings:
  - larger font presets
  - high contrast mode
  - dyslexic reading font preference
  - reduced motion preference
- forgot password / reset password flow with reset token email delivery and password confirmation endpoint

Still pending:
- divide schools more strictly, likely with subdomain-based tenant resolution instead of `X-School-Id`
- decide whether auth cookies should stay host-only for strict tenant isolation or use a parent-domain cookie for cross-subdomain SSO with stronger tenant checks
- create a demo for people to test
- create tutorial / onboarding / training materials for how to use the system
- let teachers copy/save assignments as reusable templates, publish them across multiple classes, and later possibly across different schools

Chat / messaging roadmap still pending:
- group conversations are not enabled yet
- student-student direct chat stays disabled unless explicitly enabled later
- realtime chat events over Action Cable are not implemented yet

Performance / scaling still pending:
- cache classroom student lists where useful
- stop generating performance snapshots on every dashboard request long-term
- move performance snapshot generation toward background jobs / cached stored snapshots
