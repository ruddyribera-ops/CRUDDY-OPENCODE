# Full-Stack Ecosystem & Libraries

## Web Frameworks
| Library | Description |
|---------|-------------|
| [express](https://expressjs.com) | Minimal web framework |
| [fastify](https://fastify.dev) | Fast & low overhead, schema-based validation |
| [koa](https://koajs.com) | Express successor by same team, async middleware |
| [hapi](https://hapijs.com) | Rich plugin system, configuration-oriented |
| [nest](https://nestjs.com) | Opinionated framework (decorators, DI, modules) |
| [adonis](https://adonisjs.com) | Full-featured Node.js framework (Laravel-like) |
| [hono](https://hono.dev) | Ultralight, multi-runtime (Node, Deno, Bun, Cloudflare) |

## HTTP Clients
| Library | Description |
|---------|-------------|
| [got](https://github.com/sindresorhus/got) | Human-friendly HTTP client (retry, hooks, streams) |
| [undici](https://undici.nodejs.org) | Node.js built-in HTTP/1.1 client (fast) |
| [axios](https://axios-http.com) | Promise-based HTTP client (browser + Node) |
| [ky-universal](https://github.com/sindresorhus/ky-universal) | Tiny HTTP client (browser-first, isomorphic) |

## Authentication
| Library | Description |
|---------|-------------|
| [passport](https://www.passportjs.org) | Strategy-based auth (500+ strategies) |
| [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken) | JWT signing & verification |
| [bcrypt](https://github.com/kelektiv/node.bcrypt.js) | Password hashing |
| [jose](https://github.com/panva/jose) | JOSE standards (JWT, JWE, JWS, JWK) |
| [iron-session](https://github.com/vvo/iron-session) | Encrypted cookie sessions |
| [auth.js](https://authjs.dev) | Universal auth for any framework |

## Data Validation
| Library | Description |
|---------|-------------|
| [zod](https://zod.dev) | TypeScript-first schema validation |
| [joi](https://joi.dev) | Rich validation language |
| [ajv](https://ajv.js.org) | JSON Schema validator (fastest) |
| [yup](https://github.com/jquense/yup) | Schema builder for runtime validation |

## Real-Time
| Library | Description |
|---------|-------------|
| [socket.io](https://socket.io) | WebSocket + fallbacks (rooms, namespaces) |
| [uWebSockets](https://github.com/uNetworking/uWebSockets) | C++ backed, extremely fast WebSocket server |
| [mqtt.js](https://github.com/mqttjs/MQTT.js) | MQTT client for IoT messaging |

## Job Queues
| Library | Description |
|---------|-------------|
| [bull](https://github.com/OptimalBits/bull) | Redis-backed job queue (priority, repeat, rate-limit) |
| [agenda](https://github.com/agenda/agenda) | MongoDB-backed job scheduler |
| [kue](https://github.com/Automattic/kue) | Redis-backed priority queue |
| [p-queue](https://github.com/sindresorhus/p-queue) | Promise-based concurrency control |

## Database / ORMs
| Library | Description |
|---------|-------------|
| [knex](https://knexjs.org) | SQL query builder (raw SQL, migrations, seeds) |
| [sequelize](https://sequelize.org) | Promise-based ORM for SQL dialects |
| [prisma](https://www.prisma.io) | Next-gen ORM (auto-generated types) |
| [drizzle-orm](https://orm.drizzle.team) | TypeScript ORM (SQL-like syntax, lightweight) |
| [typeorm](https://typeorm.io) | Decorator-based ORM (Data Mapper / Active Record) |
| [mikro-orm](https://mikro-orm.io) | Unit of Work ORM (Identity Map) |

## Image Processing
| Library | Description |
|---------|-------------|
| [sharp](https://sharp.pixelplumbing.com) | High-performance image resizing (libvips) |
| [jimp](https://github.com/oliver-moran/jimp) | Pure JS image manipulation (no native deps) |
| [qrcode](https://github.com/soldair/node-qrcode) | QR code generation |

## Logging
| Library | Description |
|---------|-------------|
| [pino](https://getpino.io) | Low-overhead JSON logger (fastest) |
| [winston](https://github.com/winstonjs/winston) | Multi-transport logger (file, console, HTTP) |
| [debug](https://github.com/debug-js/debug) | Namespaced debug logging (dev tool) |

## Security
| Library | Description |
|---------|-------------|
| [helmet](https://helmetjs.github.io) | HTTP security headers middleware |
| [cors](https://github.com/expressjs/cors) | CORS middleware |
| [express-rate-limit](https://github.com/express-rate-limit/express-rate-limit) | Rate limiting middleware |

## See Also
- [awesome-nodejs](https://github.com/sindresorhus/awesome-nodejs) — Curated Node.js resources (65K+ stars)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices) — Comprehensive Node.js guide
- [OpenAPI Specification](https://swagger.io/specification/) — API description standard
- [Twelve-Factor App](https://12factor.net) — SaaS app methodology
