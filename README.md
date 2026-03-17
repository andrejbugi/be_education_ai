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
[docs/login_docs.md](/home/andrejbugi/projects/be_education_ai/docs/login/login_docs.md)

## Backend Docs
- [backend_overview.md](/home/andrejbugi/projects/be_education_ai/docs/backend_overview.md)
- [phase1_data_model.md](/home/andrejbugi/projects/be_education_ai/docs/phase1_data_model.md)
- [api_quick_reference.md](/home/andrejbugi/projects/be_education_ai/docs/api_quick_reference.md)
- [core_flows.md](/home/andrejbugi/projects/be_education_ai/docs/core_flows.md)
- [assignment_model_data.md](/home/andrejbugi/projects/be_education_ai/docs/assignment_model_data.md)
- [frontend_assignment_submission_checks_guide.md](/home/andrejbugi/projects/be_education_ai/docs/frontend_assignment_submission_checks_guide.md)
- [schools_frontend_guide.md](/home/andrejbugi/projects/be_education_ai/docs/schools_frontend_guide.md)
- [seeded_school_data_summary.md](/home/andrejbugi/projects/be_education_ai/docs/seeded_school_data_summary.md)


## Redis

This project now uses Redis for Action Cable.

Development default:
- `REDIS_URL=redis://127.0.0.1:6379/1`

WSL install commands:

```bash
sudo apt update
sudo apt install -y redis-server redis-tools

sudo sed -i 's/^supervised .*/supervised systemd/' /etc/redis/redis.conf
sudo sed -i 's/^#\\? bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode .*/protected-mode yes/' /etc/redis/redis.conf

sudo systemctl enable redis-server
sudo systemctl restart redis-server
sudo systemctl status redis-server --no-pager

redis-cli ping
redis-server --version
redis-cli INFO server
```

See the chat Redis setup guide:
- [redis_setup.md](/home/andrejbugi/projects/be_education_ai/docs/chat-messaging/redis_setup.md)
