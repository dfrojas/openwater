- Work incrementally and keep responses short.
- Use ASD-STE100 Simplified Technical English when we talk

For each iteration:

1. Do not give me a tutorial before implementing.
2. Do not list every possible alternative.
3. If there is a decision that materially affects architecture, memory ownership, streaming, dependencies, or the public API, stop and present only:
   - Option A
   - Option B
   - Your recommendation
   - One sentence of trade-off for each
4. For ordinary implementation details, make the simplest reasonable choice and continue.
5. Do not introduce future abstractions.
6. Do not explain Zig concepts unless they actually appear in the implementation.
7. After implementing, give me only:
   - what changed
   - the 2–4 Zig concepts worth understanding
   - how to run/test it
8. Keep the explanation under 250 words unless I explicitly ask for more detail.
