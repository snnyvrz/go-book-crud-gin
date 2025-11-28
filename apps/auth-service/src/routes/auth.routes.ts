import { Router } from "express";
import type { Request, Response } from "express";
import { authMiddleware } from "@auth/middlewares/auth.middleware";
import { signToken } from "@auth/helpers/auth.helpers";
import type { User } from "@auth/types/auth.types";

const router = Router();

const users: User[] = [];

router.post("/register", async (req: Request, res: Response) => {
    const { email, password } = req.body as {
        email?: string;
        password?: string;
    };

    if (!email || !password) {
        return res
            .status(400)
            .json({ error: "email and password are required" });
    }

    const existing = users.find((u) => u.email === email);
    if (existing) {
        return res.status(409).json({ error: "User already exists" });
    }

    const passwordHash = await Bun.password.hash(password);
    const user: User = {
        id: crypto.randomUUID(),
        email,
        passwordHash,
    };
    users.push(user);

    const token = signToken(user);

    return res.status(201).json({
        user: { id: user.id, email: user.email },
        token,
    });
});

router.post("/login", async (req: Request, res: Response) => {
    const { email, password } = req.body as {
        email?: string;
        password?: string;
    };

    if (!email || !password) {
        return res
            .status(400)
            .json({ error: "email and password are required" });
    }

    const user = users.find((u) => u.email === email);
    if (!user) {
        return res.status(401).json({ error: "Invalid credentials" });
    }

    const ok = await Bun.password.verify(password, user.passwordHash);
    if (!ok) {
        return res.status(401).json({ error: "Invalid credentials" });
    }

    const token = signToken(user);

    return res.json({
        user: { id: user.id, email: user.email },
        token,
    });
});

router.get("/me", authMiddleware, (req: Request, res: Response) => {
    return res.json({ user: req.user });
});

export { router };
