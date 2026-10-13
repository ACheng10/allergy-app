# Swift for a Python and SQL person

The ELI5 first: Python lets you build with any Lego piece and only complains when the tower falls over (at runtime). Swift checks every piece fits before you start building (at compile time). That feels slower on day one and saves you from a whole class of crashes later.

## Translation table

| Python / SQL | Swift | Where you see it in this repo |
| --- | --- | --- |
| `@dataclass` | `struct` | `PhraseBook.Phrase`, `CardLine` |
| `json.load` into a dataclass (or pydantic) | `Decodable` + `JSONDecoder` | `PhraseBook.loadBundled()` |
| `Optional[str]`, SQL `NULL` | `String?` | `PhraseLocale.parent` |
| `if x is None: return` | `guard let x else { return }` | `PhraseBook.loadBundled()` |
| `class Color(str, Enum)` | `enum Severity: String` | `AllergyProfile.swift` |
| SQLAlchemy model / `CREATE TABLE` | `@Model final class` | `AllergyProfile` |
| `SELECT ... ORDER BY` that re-runs when data changes | `@Query(sort: ...)` | `RootView` |
| f-string `f"Call {n}"` | `"Call \(n)"` | `EmergencyView` |
| `[x.id for x in xs if x.ok]` | `xs.filter { $0.ok }.map(\.id)` | `CardBuilder` |
| `lambda p: p.id` | `{ $0.id }` or `\.id` | everywhere |
| a pure function | a computed `var` | `CardBuilder.sections` |

## How SwiftUI screens work

Think of a Jinja template that re-renders itself whenever its variables change.

- A screen is a `struct` with a `body`. `body` describes what should be on screen *right now*. You never say "add this label"; you say "the screen is this".
- `@State var x` is a variable the screen watches. Change it and the screen redraws. (Like a React state hook, if you have seen one.)
- `@Bindable var profile` is a live link to a database row. Typing in a `TextField` bound to `$profile.emergencyContactName` writes straight to the row; SwiftData saves it. The `$` means "give me a two-way binding, not just the value".
- `@Environment(\.phraseBook)` reads a shared value, like a global config object, without passing it through every function.

## Swift things that will trip you up

- **`let` vs `var`.** `let` can never change (like a tuple). Use `let` by default; the compiler tells you when you need `var`.
- **Types are checked before running.** A typo in a property name is a red error in Xcode, not a crash at runtime. Read the first red error; the rest are often knock-on effects.
- **No indentation rules, braces instead.** Xcode re-indents with Ctrl+I.
- **`!` means "crash if this is nil".** Avoid it. This repo uses it nowhere in app logic.

## Learn next

Do Apple's free SwiftUI tutorials (search "Develop in Swift tutorials" on developer.apple.com) and build a throwaway to-do list app first, as the plan suggests. Then come back and read `CardBuilder.swift`, which is the most Python-like file here.
