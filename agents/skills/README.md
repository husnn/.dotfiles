# Agent skills

Repository-managed skills use this structure:

```text
skills/
└── <skill-name>/
    └── SKILL.md
```

Create and link a skill with:

```sh
newskill <skill-name>
```

If a skill directory was added manually or arrived through Git, reconcile the
installed links with:

```sh
sync-skills
```

`sync-skills` creates one link per repository skill under `~/.agents/skills`.
When a repository skill is removed, the command removes its obsolete link. It
only removes links that point through the managed dotfiles checkout, so skills
installed directly into `~/.agents/skills` remain local to that machine.

A local skill and repository skill cannot use the same name. Resolve that
conflict explicitly; synchronization never replaces the local skill.

Preview or verify the layout with:

```sh
sync-skills --dry-run
sync-skills --check
```
