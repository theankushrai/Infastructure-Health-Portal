# Reset Last Commit

## Use Case

Need to undo the last commit and create a new branch with different commit message.

## Commands

### Reset Last Commit (Keep Changes)

```bash
git reset --soft HEAD~1
```

### Create New Branch

```bash
git checkout -b ingress-fix
```

### Commit with New Message

```bash
git commit -m "Fix ingress paths"
```

## Notes

- `--soft` keeps changes staged
- Use `--hard` to discard changes completely
- Creates clean history with proper commit message
