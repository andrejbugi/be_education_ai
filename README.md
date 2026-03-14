# BE Education AI Backend (Rails API)

## Setup
1. Install gems:
```bash
bundle install
```
2. Create and migrate DB:
```bash
bin/rails db:create
bin/rails db:migrate
```
3. Prepare test DB:
```bash
RAILS_ENV=test bin/rails db:prepare
```
4. Run server:
```bash
bin/rails server
```

## API Base
`/api/v1`

Health check:
`GET /up`

## Frontend Login Flow
Detailed guide with request/response examples:
[docs/frontend_login_flow.md](/home/andrejbugi/projects/be_education_ai/docs/frontend_login_flow.md)

## Backend Docs
- [backend_overview.md](/home/andrejbugi/projects/be_education_ai/docs/backend_overview.md)
- [phase1_data_model.md](/home/andrejbugi/projects/be_education_ai/docs/phase1_data_model.md)
- [api_quick_reference.md](/home/andrejbugi/projects/be_education_ai/docs/api_quick_reference.md)
- [core_flows.md](/home/andrejbugi/projects/be_education_ai/docs/core_flows.md)
- [schools_frontend_guide.md](/home/andrejbugi/projects/be_education_ai/docs/schools_frontend_guide.md)
- [seeded_school_data_summary.md](/home/andrejbugi/projects/be_education_ai/docs/seeded_school_data_summary.md)
