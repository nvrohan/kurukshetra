# ADR 0008 — OCI Always Free account creation is a manual handoff

- Status: Accepted
- Date: 2026-05-30
- Decider: Rohan (standing approval per ADR 0007)
- Supersedes: —
- Superseded by: —

## Context

D4 of v0.1 ships a dedicated-server deploy targeting **Oracle Cloud
Infrastructure Always Free Tier** (chosen because it is the only major
cloud with a *forever-free* compute tier — AWS Free Tier expires after
12 months, GCP Always Free is too small for ENet servers, OCI gives us
24 GB RAM on ARM A1 forever).

The autonomous-build agent (Hermes cron, ADR 0007) is otherwise empowered
to ship without per-step approval, but OCI signup requires **a valid
credit card** for identity verification (no charge — Always Free resources
are outside the free trial credit envelope, but the card is mandatory at
signup).

The agent has no payment-method credentials and the project rule
"NEVER use paid tools" makes furnishing one a non-starter even if it could.

## Decision

The OCI account creation and the initial Compute VM provisioning are a
**one-time manual step performed by Rohan**, documented step-by-step in
`docs/DEPLOY.md` §"One-time setup". Every other piece of the deploy chain
is fully scripted and re-runnable by the agent or any contributor:

- `tools/build-server.sh` — headless export, runs locally on the build VM.
- `Dockerfile` — portable container build, runs anywhere with Docker.
- `server/systemd/kurukshetra.service` — hardened service unit.
- `server/oci/deploy.sh` — push-binary-and-restart, idempotent.

After Rohan does the one-time setup once, every future deploy is
`HOST=ubuntu@... ./server/oci/deploy.sh` and requires zero OCI console
interaction (security-list rule is also one-time, also documented).

## Why not use a different free host?

| Option | Status | Why rejected |
|---|---|---|
| AWS Free Tier (t2.micro) | Rejected | Free for 12 months only; would invalidate v1.0+ runway |
| GCP Always Free (e2-micro) | Rejected | Single-region, US-only, too far from India player base |
| Hetzner / Vultr / DO | Rejected | Cheapest is ~$4/mo — violates "free OSS first" rule |
| Local LAN only | Rejected | Brief explicitly says public-internet 16-player BR (D6 playtest) |
| Self-hosted at Rohan's apartment | Rejected | Asymmetric NAT, residential ISP UDP filtering, power risk |
| **OCI Always Free** | **Accepted** | 24 GB RAM ARM forever; Mumbai region; only blocker is one-time card-gated signup |

## Consequences

### Positive

- Everything *after* one human-gated step is fully reproducible by the
  agent. Future redeploys, rollbacks, and CI-driven push-to-prod all run
  unattended.
- The handoff is well-bounded: 15 minutes of console clicks (signup → VM →
  security list rule), then never again.
- Zero ongoing cost. Always Free is forever-free as long as the VM stays
  within shape limits (1 OCPU / 6 GB RAM A1 ARM, well under our budget).

### Negative

- D4 cannot be marked ✅-and-running-in-prod by the agent alone — only
  ✅-and-deployable. The "running on a public IP that Rohan can ssh to"
  bit needs Rohan's 15 minutes.
- If OCI ever cancels Always Free or de-prioritises capacity in our home
  region (a documented risk — Mumbai A1 capacity has been sporadic in the
  past), we'd need a re-route. Mitigation: `deploy.sh` works against any
  Linux host with sshd; switching to a paid VPS (or another free tier)
  is one DNS change away.

### Neutral

- ADR 0007 remains the canonical "agent has standing approval" doc; this
  ADR carves out the single exception.

## Action items

- [x] Document the manual setup steps in `docs/DEPLOY.md`.
- [x] Make `deploy.sh` idempotent so the manual prep is decoupled from
      every subsequent agent-driven deploy.
- [ ] Rohan: complete §"One-time setup" steps 1–3 from `docs/DEPLOY.md`,
      then paste the public IP into a pinned issue or `secrets/OCI_HOST`
      so the agent can pick up automated deploys for D5/D6.
