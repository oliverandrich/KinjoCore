# parse-task CLI Tool

A command-line tool for testing the KinjoCore task parser.

## Building

```bash
swift build
```

## Usage

```bash
.build/debug/parse-task [options] <text>
```

### Options

- `-l, --lang <language>` - Language code: `de`, `en`, `fr`, `es` (default: `de`)
- `-h, --help` - Show help message

### Examples

**German:**
```bash
.build/debug/parse-task "Meeting morgen 14:00 p1 @Arbeit #wichtig"
.build/debug/parse-task "Softfolio eintragen jeden Freitag 17:00 @Arbeit p1"
.build/debug/parse-task "Bericht schreiben bis Freitag p2 @Projekt"
```

**English:**
```bash
.build/debug/parse-task --lang en "Meeting tomorrow 2 PM p1 @Work"
.build/debug/parse-task --lang en "Submit report every Monday @Work"
```

**French:**
```bash
.build/debug/parse-task --lang fr "Réunion demain 14h00 p1 @Travail"
```

**Spanish:**
```bash
.build/debug/parse-task --lang es "Reunión mañana 14:00 p1 @Trabajo"
```

## Output

The tool displays:
- Original input text
- Extracted title
- Scheduled date (when to work on it)
- Deadline (when it must be done)
- Time component
- Priority (p1-4)
- Project (@-tag)
- Labels (#-tags)
- Recurring pattern
- Annotations for UI highlighting
