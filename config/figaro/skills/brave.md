---
name: brave
description: Search the web using the Brave Search API. Use whenever the user wants to search the internet, look something up online, google something, find websites, or get current/recent information from the web.
---

# Web Search Skill

Search the web using the Brave Search API via hush.

## Prerequisites

The hush agent must be running. If it's not, start it yourself in the background:

```bash
hush up -d
```

Only ask the user for help if `hush up -d` itself fails (e.g. it needs a passphrase and no cached one is available). In that case, tell the user to run `hush up -d` in their terminal.

## Usage

To search the web, run:

```bash
hush brave "search query here"
```

- Pass the entire search query as a single quoted argument.
- No other arguments are needed.
- Results are returned as title, URL, and description for the top 5 hits.

### Concurrency

Fire as many `hush brave` calls in parallel as you like. The free plan allows one
request per second; the command handles that entirely statelessly — no locks, no
files, no coordination. A 429 (or transient 5xx) is retried with exponential
backoff and per-process random jitter (windows of 1.2s, 2.4s, 4.8s … capped at
30s, sleeping 50–100% of the window), up to 8 attempts.

A lone caller is never delayed: the first attempt always fires immediately
(~0.5s round trip). Measured: 6 concurrent searches all succeed within ~15s,
12 concurrent within ~35s.

## Examples

```bash
hush brave "golang age encryption library"
hush brave "rust vs go performance 2025"
hush brave "how to zero memory in go"
```

## Error handling

- If the agent is not running, run `hush up -d` yourself and retry. Only escalate to the user if that command fails.
- If the agent needs an interactive passphrase ("no interactive terminal is available to prompt for a passphrase"), ask the user to run `hush up -d` in their terminal.
- If the API returns an error, the HTTP status code and body are printed to stderr.
- Rate limits (429) and transient 5xx are retried automatically with backoff; you
  only see an error after 8 failed attempts ("HTTP 429 after 8 attempts"), which
  means the whole minute was saturated — wait and retry.
- If no results are found, "No results found." is printed.
