# LLS Roadmap

LLS (Lean Limb Subsystem) is a persistent, headless workspace service. Clients such as `lls-t` attach to it without owning its state or lifetime.

## Milestone 0: Walking skeleton

- `lls`
  - [ ] Run in the foreground or as a background service.
  - [ ] Expose a versioned local command/event protocol.
  - [ ] Accept multiple attachable clients.
  - [ ] Support `ping`, `status`, and clean shutdown.
- `lls-t`
  - [ ] Find or start the local `lls` instance.
  - [ ] Show service status and protocol version.
  - [ ] Send commands and print structured errors.

## Milestone 1: Workspaces and events

- `lls`
  - [ ] Open workspaces by canonical path and assign stable identities.
  - [ ] Maintain a monotonic, replayable event journal.
  - [ ] Support snapshots, subscriptions, cursors, and acknowledgements.
  - [ ] Preserve state when every client detaches.
- `lls-t`
  - [ ] List, open, select, and close workspaces.
  - [ ] Watch live events and resume from an event cursor.
  - [ ] Provide readable and JSON output modes.

## Milestone 2: Persistent file search

- `lls`
  - [ ] Inventory files with include, exclude, ignore, binary, and size rules.
  - [ ] Build and persist a content index.
  - [ ] Update the index incrementally when files change.
  - [ ] Search multiple literals, regular expressions, and path filters in one request.
  - [ ] Return snippets, counts, skipped files, errors, and explicit truncation status.
  - [ ] Cache queries and invalidate them by workspace generation.
- `lls-t`
  - [ ] Search contents and paths from the terminal.
  - [ ] Request context lines, counts, limits, and machine-readable results.
  - [ ] Inspect index freshness, coverage, and statistics.

## Milestone 3: Durable working memory

- `lls`
  - [ ] Store findings, concepts, evidence, decisions, failed attempts, and questions.
  - [ ] Store resumable checkpoints with goals, progress, blockers, and next steps.
  - [ ] Link memories to file spans, content hashes, and repository revisions.
  - [ ] Recall relevant records by text, relationship, workspace, and freshness.
  - [ ] Supersede stale records without erasing their history.
- `lls-t`
  - [ ] Add, inspect, search, and supersede memory records.
  - [ ] Show evidence and freshness for recalled information.
  - [ ] Create and restore task checkpoints.

## Milestone 4: Execution

- `lls`
  - [ ] Start processes with explicit arguments, working directory, environment, and limits.
  - [ ] Stream stdout and stderr as replayable events.
  - [ ] Accept process input and support cancellation.
  - [ ] Track process trees and clean them up safely.
  - [ ] Persist execution metadata and associate results with source and memory records.
- `lls-t`
  - [ ] Start, list, attach to, interact with, and cancel processes.
  - [ ] Resume reading output from a saved event cursor.
  - [ ] Display exit status, duration, and resource-limit failures.

## Milestone 5: Recovery and readiness

- `lls`
  - [ ] Recover cleanly after interruption or crash.
  - [ ] Version and migrate persistent data and indexes.
  - [ ] Enforce workspace boundaries and local-client authorization.
  - [ ] Provide diagnostics, integrity checks, backups, and export.
  - [ ] Benchmark startup, indexing, search, memory retrieval, and event delivery.
- `lls-t`
  - [ ] Provide `doctor`, integrity-check, backup, restore, and export commands.
  - [ ] Report actionable diagnostics without requiring direct database inspection.

## Completion target

- [ ] `lls` can keep a workspace indexed, remembered, and observable with no GUI attached.
- [ ] `lls-t` can exercise and diagnose every core capability.
- [ ] Later attachments such as `lls-a` and `lls-g` can rely exclusively on the same protocol and event journal.
