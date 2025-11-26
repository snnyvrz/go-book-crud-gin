import express from "express";
import { router } from "./routes";

const app = express();
const port = 3030;

app.use(express.json());
app.use("/auth", router);

app.listen(port, () => {
    console.log(`Listening on port ${port}...`);
});
