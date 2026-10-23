# ADR-0008: Private S3-compatible object storage with scoped presigned access

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Lease PDFs, identity documents, inspection photos, expense evidence must be
private, scoped, and auditable; servers should not proxy large files.

## Decision
**S3-compatible object storage, private buckets** (MinIO locally; R2/S3 in
hosting). Access via short-TTL presigned URLs granted only through the
authorization policy (scope + role + record); upload paths validate
content-type/size server-side; key scheme encodes
`workspace/entityType/entityId/…` for lifecycle and export tooling. Sensitive
downloads are audit-logged (FR-IDW-06).

## Consequences
No public URLs ever; expired-link UX handled client-side; storage costs scale
with media; retention rules (#14/#31) operate on the key scheme.
