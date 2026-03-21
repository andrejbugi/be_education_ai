# Redis Setup And Usage For Chat Messaging

This doc covers the Redis setup for Action Cable in this project.

Right now chat works through normal API requests.
Redis is not required for the current polling-based flow.

The backend is now configured to use Redis for Action Cable in:

- development
- production

Current backend files:

- `config/cable.yml`
- `config/routes.rb`
- `config/environments/development.rb`
- `config/environments/production.rb`

## What Redis would be used for

For chat messaging, Redis would typically sit behind Action Cable and help with:

- pub/sub for new messages
- pub/sub for read and delivered updates
- pub/sub for reaction updates
- pub/sub for presence updates

This is different from the current setup, where the frontend must refresh or poll to see new chat activity.

## WSL Ubuntu 24.04 install

Run:

```bash
sudo apt update
sudo apt install -y redis-server redis-tools

sudo sed -i 's/^supervised .*/supervised systemd/' /etc/redis/redis.conf
sudo sed -i 's/^#\? bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode .*/protected-mode yes/' /etc/redis/redis.conf

sudo systemctl enable redis-server
sudo systemctl restart redis-server
sudo systemctl status redis-server --no-pager

redis-cli ping
redis-server --version
redis-cli INFO server
```

Expected quick check:

```text
PONG
```

## Basic day-to-day commands

Check service:

```bash
sudo systemctl status redis-server --no-pager
```

Restart service:

```bash
sudo systemctl restart redis-server
```

Stop service:

```bash
sudo systemctl stop redis-server
```

Start service:

```bash
sudo systemctl start redis-server
```

Ping Redis:

```bash
redis-cli ping
```

Open Redis CLI:

```bash
redis-cli
```

## Redis env var used by the backend

The backend uses:

```bash
REDIS_URL=redis://127.0.0.1:6379/1
```

You can temporarily export it in WSL with:

```bash
export REDIS_URL=redis://127.0.0.1:6379/1
```

If you want it persistent for your shell:

```bash
echo 'export REDIS_URL=redis://127.0.0.1:6379/1' >> ~/.bashrc
source ~/.bashrc
```

## Current Rails cable config shape

The project is configured like this:

```yml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/1") %>
  channel_prefix: be_education_ai_development

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/1") %>
  channel_prefix: be_education_ai_production
```

Notes:

- `channel_prefix` helps separate apps/environments
- database `/1` is just one Redis logical DB choice for development
- production should still set a real `REDIS_URL` explicitly
- the fallback value exists mainly so local boot and config inspection do not break

## Cable endpoint

The backend mounts Action Cable at:

```text
/cable
```

That means the future frontend websocket URL will typically be based on `/cable`.

Examples:

```text
ws://localhost:3000/cable
wss://app.example.com/cable
```

Current auth style:

```text
/cable
```

The websocket connection uses the same browser auth cookie as the HTTP API.

## Allowed origins

Development allows common local frontend origins like:

- `http://localhost:<port>`
- `http://127.0.0.1:<port>`

Production can be controlled with:

```bash
ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=https://app.example.com
```

For multiple origins:

```bash
ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=https://app.example.com,https://www.app.example.com
```

## How FE would benefit after Redis + Action Cable

FE can now subscribe to new-message updates for chat conversations instead of relying only on polling.

Current and future event examples:

- new message created
- message delivered
- message read
- reaction added
- reaction removed
- user presence changed

That would remove the need to manually refresh the chat screen to see updates.

## Production expectations later

With the current Redis-backed Cable setup, expect:

- Rails app still handles websocket connections
- Redis handles pub/sub fanout
- proxy or load balancer must allow websocket upgrades
- app instances should all be able to reach the same Redis

## What is still not done

Redis-backed Action Cable is configured, and the minimal chat realtime flow is in place for new messages.

What is already done:

- token-authenticated websocket connection
- per-conversation subscription authorization
- `message.created` broadcasts for new chat messages

The remaining work for fuller live chat is:

- add richer event coverage for delivered, read, reactions, and presence
- subscribe from FE
