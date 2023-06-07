import { Router } from "express";
import user from "./userRoute";

const router: Router = Router();

router.use("/users", user);

export default router;
