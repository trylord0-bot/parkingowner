import type { FastifyRequest, FastifyReply } from "fastify";
import type { UserRole } from "@prisma/client";

export interface JwtPayload {
  sub: string;       // userId
  email: string;
  role: UserRole;
  complexId?: string;
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: JwtPayload;
    user: JwtPayload;
  }
}

export async function authenticate(req: FastifyRequest, reply: FastifyReply) {
  try {
    await req.jwtVerify();
  } catch {
    reply.code(401).send({ error: "Unauthorized" });
  }
}

export function requireRole(...roles: UserRole[]) {
  return async (req: FastifyRequest, reply: FastifyReply) => {
    await authenticate(req, reply);
    if (!roles.includes(req.user.role)) {
      reply.code(403).send({ error: "Forbidden" });
    }
  };
}
