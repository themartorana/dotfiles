# CLAUDE.md - Flyclops Code Guidelines

## Overview

This document contains rules and guidelines that should be applied to all code touched by Claude on behalf of Flyclops.

---

## General Rules

1. Before any code:
    - Research best practices
    - Analyze related files
    - Step-by-step plan
    - Token/time estimate
WAIT for my approval before coding!

2. Check code for:  
    - Time complexity (Big O notation)
    - DB/memory bottlenecks
    - Async pitfalls
    - N+1 query problems
Suggest measurable improvements with benchmarks.

3. Always ask for clarification if requirements are ambiguous or incomplete. Never make assumptions about intended behavior without confirmation.

4. Follow the existing code style and conventions of the project unless explicitly directed otherwise. When in doubt, ask for guidance on style.

5. When modifying existing code, ensure that you understand the original implementation and its context. Avoid making changes that could introduce regressions or break existing functionality without thorough testing.

6. Write clear, concise, and descriptive commit messages that explain the purpose of the changes made. Include references to any relevant issues or tickets.

7. When adding new functionality, ensure that it is well-documented with comments explaining the purpose and behavior of the code. Follow the documentation style used in the project.

8. Always write tests for new code and ensure that existing tests pass after making changes. Aim for high test coverage, especially for critical functionality.

9. If I introduce a suggestion or request that you disagree with, please explain your reasoning and provide alternative solutions if possible. Open communication is key to finding the best approach. I am uninterested in a "yes man" approach, I want to have a collaborative relationship where we can challenge each other's ideas and arrive at the best solution together.

--

## General Code Rules

2. **Always propagate errors**: Any function that can receive an error from another function, or generates its own errors, must return those errors to the caller. Never swallow errors silently unless explicitly specified otherwise.

3. **Log errors at creation**: Any function that creates an `errorclops.Error` is responsible for logging that error at the point of creation.

4. **Wrap generic errors**: Any function that receives a generic error should wrap it in an `errorclops.Error` and log it.

5. **Error type by project**: If the project imports `com-flyclops-common` at the `go.mod` level, use `errorclops.Error` objects unless otherwise specified. If `com-flyclops-common` is not imported, the same error handling rules apply but using standard `Error` objects instead.

---

## Code Style

1. **Error fall-through pattern**: When multiple operations return errors in sequence and each subsequent operation should only run if the previous succeeded, use the `if err == nil` fall-through pattern instead of repeated `if err != nil { return err }` blocks. This reduces nesting and makes the success path clearer.

   Instead of:
   ```go
   err := A()
   if err != nil {
       return err
   }
   err = B()
   if err != nil {
       return err
   }
   err = C()
   if err != nil {
       return err
   }
   ```

   Use:
   ```go
   err := A()
   if err == nil {
       err = B()
   }
   if err == nil {
       err = C()
   }
   return err
   ```

2. **Extract repeated nested access**: When the same chain of property/method access is used multiple times in a function, extract the nested object into a local variable.

   Instead of:
   ```go
   _ = a.b.c.d.A()
   _ = a.b.c.d.B()
   _ = a.b.c.d.C()
   ```

   Use:
   ```go
   e := a.b.c.d
   _ = e.A()
   _ = e.B()
   _ = e.C()
   ```

3. **Format with golines on save**: When Go files are saved, run golines to enforce line length limits:
   ```bash
   golines --base-formatter="gofmt" -m 80 -w {file}
   ```

---

## Data

1. **Transaction lifecycle**: Each `contextclops.Context` object has a single transaction per database. Any save operation on any model must either commit or roll back the transaction.

2. **Copy context for goroutines**: When passing work into a goroutine, copy the context in the caller to give the goroutine its own transaction set. Example: `go someFunction(ctx.Copy())`

-- 

## Architecture

<!-- Add architecture rules here -->

---

## Testing

<!-- Add testing rules here -->

---

## Security

<!-- Add security rules here -->

---

## Project-Specific Rules

<!-- Add project-specific rules here -->

---
