# Documentation rules

We use [ASD-STE100 Issue 9](https://www.asd-ste100.org/) as the reference for our new technical documentation.
We use first-person plural for our project decisions and plans.
In this documentation, “we” means the people responsible for this fork.
We use imperative sentences for user procedures.

## Writing checks

1. Use one term for one meaning.
2. Use active voice.
3. Use short sentences.
4. Keep procedural sentences within 20 words.
5. Keep descriptive sentences within 25 words.
6. Give each paragraph one topic.
7. Use no more than six sentences in a paragraph.
8. Give one instruction in each procedural sentence.
9. Define technical terms before they cause ambiguity.
10. Keep API identifiers unchanged.
11. Separate current behavior from planned behavior.
12. Check each statement against the code and recorded test results.

We use the glossary below to define project terms.
We check each technical term against the applicable ASD-STE100 rules.
We do not replace an API identifier with a simpler word that changes its meaning.
We retain historical release notes and the original license text.

## Technical terms

| Term            | Meaning in this project                                               |
| --------------- | --------------------------------------------------------------------- |
| API             | The public declarations that an app can use.                          |
| Branch          | A named line of Git history.                                          |
| Castling        | A chess move that moves the king and a rook.                          |
| CI              | Automated checks that run after a repository event.                   |
| Dead position   | A position where no legal move sequence can lead to checkmate.        |
| En passant      | The special pawn capture after an opposing pawn advances two squares. |
| FEN             | Text that describes a position and its state.                         |
| Fork            | Our copy of an upstream Git repository.                               |
| Move rights     | State that affects castling or en passant.                            |
| Perft           | A test that counts legal move sequences to a given depth.             |
| PGN             | A text format for chess games and their annotations.                  |
| Regression test | A test that detects the return of a known defect.                     |
| SAN             | Standard Algebraic Notation for a chess move.                         |
| Upstream        | The original aperechnev/ChessKit repository.                          |

## Review status

We apply these writing rules to the new README, contribution guide, and project notes.
We do not claim certified or complete ASD-STE100 compliance.
A complete review must check the approved vocabulary and all applicable rules.
A sentence-length check alone does not establish compliance.
