# Reunite

Reunite is a calm, community-led bridge between a missing-person report and the people who may hold the next useful detail. It gives families, neighbors, and volunteers one shared place to publish, discover, and carefully discuss cases.

The project is split by responsibility: the frontend is the public and member-facing experience, the backend protects the workflow and data boundary, and the AI service turns submitted photographs into searchable identity signals. Together they form a small network designed around dignity, clarity, and practical action.

## Project map

- `Frontend/` — the web experience people see and use.
- `mobile/` — the cross-platform Flutter mobile application.
- `backend-node/` — unified production Node.js API server (Fastify, TypeScript, CoALA Agent Memory, and dual Web/Mobile compatibility).
- `Backend/` — Python FastAPI service prototype.
- `AI/` — the image embedding service used for photo similarity search.
- `Database/` — the relational schema that gives the network its memory.

Each area has its own README with the knowledge that matters when working there.

## Guiding idea

Reunite should feel less like a database and more like a thoughtful noticeboard: information is structured enough to be useful, private enough to be handled responsibly, and human enough to invite help.

