# Redis Setup And Usage For Chat Messaging

This doc is for later when we switch chat updates to realtime behavior with Action Cable + Redis.

Right now chat works through normal API requests.
Redis is not required for the current polling-based flow.

When we add realtime chat, Redis can be used as the Action Cable adapter so development and production behave the same way.

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
sudo sed -i 's/^#\\? bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
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

## Suggested Rails env var

When we wire Redis into Action Cable, a common env var is:

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

## Likely future Rails cable config

When we switch to Redis-backed Action Cable, `config/cable.yml` will likely look like this:

```yml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/1") %>
  channel_prefix: be_education_ai_development

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") %>
  channel_prefix: be_education_ai_production
```

Notes:

- `channel_prefix` helps separate apps/environments
- database `/1` is just one Redis logical DB choice for development
- production often uses a dedicated Redis instance or managed Redis service

## How FE would benefit after Redis + Action Cable

Once Redis-backed Action Cable is added, FE could subscribe to chat updates instead of polling.

Typical events we would broadcast:

- new message created
- message delivered
- message read
- reaction added
- reaction removed
- user presence changed

That would remove the need to manually refresh the chat screen to see updates.

## Production expectations later

If we move to Redis-backed Cable in production, expect:

- Rails app still handles websocket connections
- Redis handles pub/sub fanout
- proxy or load balancer must allow websocket upgrades
- app instances should all be able to reach the same Redis

## What we have today

Today this project still uses normal API requests for chat refresh behavior.

So this Redis setup doc is preparation for the next step, not a requirement for current chat API usage.
