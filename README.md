# ext-schoolus

Public **extension-definition repo** for the `schoolus` extension (product:
**School Portal**), following the
[`ext-<id>` repo-naming convention](https://github.com/sneat-co/sneat-specs/blob/main/standards/repo-naming.md).

It holds the **frozen wire shapes** other repos need in order to *talk to*
School Portal — the TypeSpec source of truth and the matching Go DTOs. It
contains **no** School Portal implementation; that lives in
[`sneat-co/schoolus`](https://github.com/sneat-co/schoolus) (private).

## Layout

```
ext-schoolus/
├── typespec/           # api4schoolus.tsp — source of truth for the wire shape
└── backend/            # Go module github.com/sneat-co/ext-schoolus/backend
    └── dto4schoolus/   # package dto4schoolus — the frozen request/response DTOs
```

No emitters are configured — the `.tsp` file and the Go package are
hand-kept in sync (same convention as `eventius/typespec` and the
`sneat-go/typespec` directory).

## Discovery

Tagged `sneat-extension-definition` (with legacy `sneat-extension-contract`
during migration) — see all extension-definition repos at
[`github.com/sneat-co?q=topic:sneat-extension-definition`](https://github.com/orgs/sneat-co/repositories?q=topic%3Asneat-extension-definition).

## Status

Prototype scaffold — DTOs cover the six v1 endpoints (create school, public
school read, create class, enrol student, class timetable read, mark
attendance). See backstage
`docs/superpowers/specs/2026-07-04-schoolus-prototype-design.md`.
