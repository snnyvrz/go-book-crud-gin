import express from "express";
import { router } from "@auth/routes/auth.routes";

const app = express();
const port = 3030;

app.use(express.json());
app.use("/api/auth", router);

app.listen(port, () => {
    console.log(`Listening on port ${port}...`);
});
