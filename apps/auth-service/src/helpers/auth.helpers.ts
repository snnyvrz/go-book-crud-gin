import type { UserDoc } from "@auth/models/User";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "dev_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 3600;

export const signToken = (user: UserDoc) => {
    if (!user) {
        throw new Error("User is null, cannot sign token");
    }

    return jwt.sign(
        { sub: user._id.toString(), email: user.email },
        JWT_SECRET,
        {
            expiresIn: Number(JWT_EXPIRES_IN),
        }
    );
};
