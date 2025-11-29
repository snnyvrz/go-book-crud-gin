import express from "express";
import { router } from "@auth/routes/auth.routes";
import { connectMongo } from "@auth/db/auth.db";

const app = express();
const port = 3030;

app.use(express.json());
app.use("/api/auth", router);

async function bootstrap() {
    await connectMongo();
    app.listen(port, () => {
        console.log(`Auth service listening on port ${port}`);
    });
}

bootstrap().catch((err) => {
    console.error("Failed to start auth-service:", err);
    process.exit(1);
});
